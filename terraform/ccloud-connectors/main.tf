# =============================================================================
# CONNECTORS MODULE
# =============================================================================

# =============================================================================
# LOCAL VALUES - Fase 1: Descubrimiento y carga de configuración
# =============================================================================
locals {
  # Mapear environment a prefijo de archivos de configuración
  env_prefix = {
    "DES" = "dev"
    "CER" = "cert"
    "PRO" = "prod"
  }

  prefix         = local.env_prefix[var.environment]

  # Nombres de archivos por entorno derivados del prefijo
  # JSON: {prefix}-{connector-name}.json  (ej: dev-ccloud-sql-db-sink-connector-01.json)
  # YAML: {prefix}-vars.yaml              (ej: dev-vars.yaml)
  vars_file_name = "${local.prefix}-vars.yaml"

  # Descubrir conectores buscando archivos JSON que coincidan con el entorno actual
  # Convención: {directorio}/{prefix}-{directorio}.json
  # Ejemplo: ccloud-datagen-source-connector-01/dev-ccloud-datagen-source-connector-01.json
  # fileset solo retorna archivos, no directorios, por eso buscamos el patrón de JSON
  connector_json_paths = fileset(var.connectors_dir, "*/${local.prefix}-*.json")

  # Extraer nombres de directorio de los paths encontrados (key del for_each)
  connector_dirs = distinct([for path in local.connector_json_paths : dirname(path)])

  # Cargar configuración de cada conector:
  # - config_json: configuración base desde el JSON del entorno
  # - vars: variables por entorno desde el YAML (si existe, sino objeto vacío)
  connectors_data = {
    for connector_dir in local.connector_dirs :
    connector_dir => {
      config_json = jsondecode(file("${var.connectors_dir}/${connector_dir}/${local.prefix}-${connector_dir}.json"))
      vars        = fileexists("${var.connectors_dir}/${connector_dir}/${local.vars_file_name}") ? yamldecode(file("${var.connectors_dir}/${connector_dir}/${local.vars_file_name}")) : {}
    }
  }

  # Extraer nombre del Service Account por conector desde vault.service_account del YAML
  # Ejemplo: vault.service_account: "SA_AZC_DES_PEVE_DATAGEN_01"
  connector_sa_names = {
    for name, d in local.connectors_data :
    name => try(d.vars["vault"]["service_account"], "")
  }

  # Obtener nombres únicos de SAs para hacer un solo lookup por SA (evita duplicados)
  unique_sa_names = toset([
    for sa in values(local.connector_sa_names) : sa if sa != ""
  ])

  # Combinar config_nonsensitive: primero JSON, luego YAML vars (vars sobrescribe JSON)
  connector_base_configs = {
    for name, d in local.connectors_data :
    name => merge(
      try(d.config_json["config_nonsensitive"], {}),
      try(d.vars["config_nonsensitive"], {})
    )
  }

  # Detectar el topic principal por conector (para generación automática de DLQ)
  # Puede ser "topics" para sinks o "kafka.topic" para sources
  # Si hay múltiples topics separados por comas, tomar el primero
  connector_topics = {
    for name, cfg in local.connector_base_configs :
    name => (
      try(cfg["topics"], "") != "" ?
      trimspace(split(",", tostring(cfg["topics"]))[0]) :
      try(tostring(cfg["kafka.topic"]), "")
    )
  }

  # Generar nombre del DLQ: [topic-name]-dlq
  # Solo si el topic existe y el conector tiene errors.tolerance configurado
  # Nota: El topic DLQ debe crearse previamente por un proceso externo
  connector_dlq_configs = {
    for name, cfg in local.connector_base_configs :
    name => (
      local.connector_topics[name] != "" && try(cfg["errors.tolerance"], "") != "" ? {
        "errors.deadletterqueue.topic.name" = "${local.connector_topics[name]}-dlq"
      } : {}
    )
  }
}

# =============================================================================
# DATA SOURCES - Resolver Service Account ID a partir del nombre
# =============================================================================
# Cada conector define su SA en el YAML (vault.service_account: "SA_AZC_DES_PEVE_DATAGEN_01")
# Terraform resuelve el ID (sa-xxxxx) automáticamente via este data source
data "confluent_service_account" "connector_sa" {
  for_each     = local.unique_sa_names
  display_name = each.value
}

# =============================================================================
# LOCAL VALUES - Fase 2: Procesamiento final
# =============================================================================
locals {
  # Mapa de connector -> SA ID resuelto desde el data source
  # Ejemplo: "ccloud-datagen-source-connector-01" -> "sa-abc123"
  connector_sa_ids = {
    for name, sa_name in local.connector_sa_names :
    name => sa_name != "" ? data.confluent_service_account.connector_sa[sa_name].id : ""
  }

  # Procesar y combinar configuraciones finales para cada conector
  connectors_processed = {
    for connector_name, d in local.connectors_data :
    connector_name => {
      # Obtener nombre del conector desde JSON o usar el nombre del directorio
      name = try(
        d.config_json["name"],
        try(d.config_json["config_nonsensitive"]["name"], connector_name)
      )

      # Combinar config_nonsensitive:
      # 1. base_config (JSON + YAML vars merge)
      # 2. name (siempre se aplica, no puede sobrescribirse)
      # 3. kafka.service.account.id (resuelto desde data source por SA name)
      # 4. DLQ config (si aplica)
      config_nonsensitive = merge(
        local.connector_base_configs[connector_name],
        {
          "name" = try(
            d.config_json["name"],
            try(d.config_json["config_nonsensitive"]["name"], connector_name)
          )
        },
        # Inyectar kafka.service.account.id resuelto desde el data source
        # Solo si el conector tiene un SA definido en vault.service_account
        local.connector_sa_ids[connector_name] != "" ? {
          "kafka.service.account.id" = local.connector_sa_ids[connector_name]
        } : {},
        # Agregar configuración de DLQ si aplica
        local.connector_dlq_configs[connector_name]
      )

      # Combinar config_sensitive: primero JSON (si existe), luego YAML vars (vars sobrescribe)
      # Filtrar valores vacíos ya que pueden venir como placeholders
      config_sensitive = {
        for k, v in merge(
          try(d.config_json["config_sensitive"], {}),
          try(d.vars["config_sensitive"], {})
        ) : k => v if v != "" && v != null
      }

      # Estado del conector (desde vars o JSON, por defecto RUNNING)
      status = try(
        d.vars["status"],
        try(d.config_json["status"], "RUNNING")
      )
    }
  }
}

# =============================================================================
# RESOURCES
# =============================================================================

# -----------------------------------------------------------------------------
# Full-Managed Kafka Connectors
# -----------------------------------------------------------------------------
# Nota: Los topics DLQ deben crearse previamente por otro proceso externo
# El service account configurado en kafka.service.account.id necesita permisos
# RBAC (DeveloperWrite/DeveloperRead) a los topics y Schema Registry correspondientes.
# Ver docs/CONNECTOR_DLQ_PERMISSIONS.md para más detalles
#
# REGLA CRÍTICA: El campo 'name' en el JSON NO debe cambiarse después de la
# creación inicial. El atributo 'name' es ForceNew en el provider de Confluent,
# lo que significa que cambiar el nombre destruirá el conector y creará uno nuevo,
# causando pérdida de offsets y posible re-procesamiento de mensajes.
#
# CÓMO FUNCIONA LA ACTUALIZACIÓN:
# - Si cambias configuraciones (tasks.max, topics, flush.size, etc.):
#   Terraform envía un update al provider -> actualización in-place.
# - Si cambias el status (RUNNING/PAUSED): actualización in-place.
# - Si cambias el 'name': DESTROY + CREATE (pérdida de offsets).
# - Si renombras el directorio: DESTROY + CREATE (cambia la key del for_each).
#
# Para un cambio seguro de configuración:
# 1. Modificar el JSON o YAML correspondiente al entorno
# 2. Ejecutar terraform plan para verificar que propone 'update in-place'
# 3. Si propone 'destroy and recreate', DETENER y revisar qué cambio lo provoca
resource "confluent_connector" "connectors" {
  for_each = local.connectors_processed

  environment {
    id = var.environment_id
  }

  kafka_cluster {
    id = var.kafka_cluster_id
  }

  config_nonsensitive = each.value.config_nonsensitive
  config_sensitive    = each.value.config_sensitive
  status              = each.value.status

  lifecycle {
    precondition {
      condition     = can(each.value.config_nonsensitive["name"]) && each.value.config_nonsensitive["name"] != ""
      error_message = "El campo 'name' es obligatorio en el JSON del conector: ${each.key}. REGLA: NO cambies el 'name' después de la creación inicial."
    }
  }
}
