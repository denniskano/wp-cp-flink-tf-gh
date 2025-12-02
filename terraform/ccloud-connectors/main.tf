# =============================================================================
# CONNECTORS MODULE
# =============================================================================

# =============================================================================
# LOCAL VALUES
# =============================================================================
locals {
  # Mapear environment a nombre de archivo vars
  env_vars_file = {
    "DES" = "dev-vars.yaml"
    "CER" = "cert-vars.yaml"
    "PRO" = "prod-vars.yaml"
  }
  
  vars_file_name = local.env_vars_file[var.environment]
  
  # Encontrar todos los directorios de conectores
  all_connector_dirs = fileset(var.connectors_dir, "*")
  
  # Para cada directorio, encontrar archivos JSON de configuración
  # Buscar cualquier archivo JSON en el directorio (asumimos uno por conector)
  connector_json_files = {
    for dir in local.all_connector_dirs :
    dir => [
      for json_file in fileset("${var.connectors_dir}/${dir}", "*.json") :
      json_file if fileexists("${var.connectors_dir}/${dir}/${json_file}")
    ]
  }
  
  # Filtrar solo directorios que tengan al menos un archivo JSON
  connector_dirs = [
    for dir, json_files in local.connector_json_files :
    dir if length(json_files) > 0
  ]
  
  # Cargar configuración de cada conector
  connectors_data = {
    for connector_dir in local.connector_dirs :
    connector_dir => {
      # Usar el primer archivo JSON encontrado en el directorio
      # (asumimos un solo archivo JSON por conector con la configuración base)
      json_file = local.connector_json_files[connector_dir][0]
      json_file_path = "${var.connectors_dir}/${connector_dir}/${local.connector_json_files[connector_dir][0]}"
      
      # Cargar configuración base del conector desde JSON
      config_json = jsondecode(file("${var.connectors_dir}/${connector_dir}/${local.connector_json_files[connector_dir][0]}"))
      
      # Cargar variables por entorno (si existe, sino usar objeto vacío)
      vars_file_path = "${var.connectors_dir}/${connector_dir}/${local.vars_file_name}"
      vars = fileexists("${var.connectors_dir}/${connector_dir}/${local.vars_file_name}") ? yamldecode(file("${var.connectors_dir}/${connector_dir}/${local.vars_file_name}")) : {}
    }
  }
  
  # Procesar y combinar configuraciones
  connectors_processed = {
    for connector_name, data in local.connectors_data :
    connector_name => {
      # Obtener nombre del conector desde JSON o usar el nombre del directorio
      name = try(
        data.config_json["name"],
        try(data.config_json["config_nonsensitive"]["name"], connector_name)
      )
      
      # Combinar configuración base (JSON + vars) para detectar el topic
      base_config = merge(
        try(data.config_json["config_nonsensitive"], {}),
        try(data.vars["config_nonsensitive"], {})
      )
      
      # Detectar el topic principal (puede ser "topics" para sinks o "kafka.topic" para sources)
      # Si hay múltiples topics separados por comas, tomar el primero y limpiar espacios
      topics_value = try(base_config["topics"], null)
      kafka_topic_value = try(base_config["kafka.topic"], null)
      
      topic_name_raw = topics_value != null && topics_value != "" ? (
        # Si topics existe y no está vacío, tomar el primero de la lista separada por comas
        trimspace(split(",", tostring(topics_value))[0])
      ) : (
        # Si no, intentar obtener de kafka.topic (sources)
        kafka_topic_value != null && kafka_topic_value != "" ? tostring(kafka_topic_value) : ""
      )
      
      # Verificar si el conector tiene configuración de DLQ (errors.tolerance configurado)
      has_dlq_config = try(base_config["errors.tolerance"], "") != ""
      
      # Generar nombre del DLQ: [topic-name]-dlq
      # Solo si el topic existe, no está vacío, y el conector tiene configuración de DLQ
      dlq_config = length(topic_name_raw) > 0 && has_dlq_config ? {
        "errors.deadletterqueue.topic.name" = "${topic_name_raw}-dlq"
      } : {}
      
      # Combinar config_nonsensitive: primero JSON, luego vars (vars sobrescribe)
      # Nota: El merge se hace en orden, así que vars puede sobrescribir JSON
      # Pero los valores finales (name, kafka.service.account.id, y DLQ) siempre se aplican al final
      config_nonsensitive = merge(
        base_config,
        {
          # Valores que siempre deben estar y no pueden sobrescribirse
          "name" = try(
            data.config_json["name"],
            try(data.config_json["config_nonsensitive"]["name"], connector_name)
          ),
          "kafka.service.account.id" = var.principal_id
        },
        # Agregar configuración de DLQ si aplica
        dlq_config
      )
      
      # Combinar config_sensitive: primero JSON (si existe), luego vars (vars sobrescribe)
      # Filtrar valores vacíos ya que pueden venir como placeholders desde vars
      config_sensitive = {
        for k, v in merge(
          try(data.config_json["config_sensitive"], {}),
          try(data.vars["config_sensitive"], {})
        ) : k => v if v != "" && v != null
      }
      
      # Estado del conector (desde vars o JSON, por defecto RUNNING)
      status = try(
        data.vars["status"],
        try(data.config_json["status"], "RUNNING")
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
# RBAC (ResourceOwner o DeveloperWrite) al topic DLQ para que el conector pueda
# escribir mensajes fallidos. Ver docs/CONNECTOR_DLQ_PERMISSIONS.md para más detalles
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
}

