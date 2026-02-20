# Modelo Operativo: Flink Compute Pools

## Confluent Cloud for Apache Flink

---

## Que es un Compute Pool

Un Compute Pool es un conjunto de recursos de computo administrado por Confluent Cloud donde se ejecutan los Flink SQL statements. Es el equivalente a un "cluster de Flink" pero completamente gestionado, sin infraestructura que administrar.

Cada Compute Pool:
- Tiene una capacidad maxima definida en **CFUs (Confluent Flink Units)**
- Esta asociado a una **region** y un **cloud provider** (Azure, AWS, GCP)
- Puede ejecutar multiples statements simultaneamente
- Escala automaticamente via **Autopilot** dentro del limite de CFUs configurado

---

## Arquitectura

```
Confluent Cloud
├── Environment (env-xxxxx)
│   ├── Kafka Cluster Dedicado (lkc-xxxxx)
│   ├── Schema Registry (lsrc-xxxxx)
│   ├── Compute Pool - Produccion (CP_AZC_PRO_PEVE_01)
│   │   ├── DDL Statements (CREATE TABLE)
│   │   └── DML Statements (INSERT INTO SELECT)
│   ├── Compute Pool - Desarrollo (CP_AZC_DES_PEVE_01)
│   │   ├── DDL Statements
│   │   └── DML Statements
│   └── Compute Pool - Ad-hoc Queries (CP_AZC_DES_PEVE_ADHOC)
│       └── SELECT queries exploratorias
```

---

## Configuracion via Terraform

### Archivo de configuracion YAML

Cada aplicacion define sus compute pools en un archivo YAML:

```yaml
# PEVE/compute_pool-config.yaml
compute_pools:
  - pool_name: "CP_AZC_DES_PEVE_01"
    cloud: "AZURE"
    region: "eastus2"
    max_cfu: 10

  - pool_name: "CP_AZC_CER_PEVE_01"
    cloud: "AZURE"
    region: "eastus2"
    max_cfu: 20

  - pool_name: "CP_AZC_PRO_PEVE_01"
    cloud: "AZURE"
    region: "eastus2"
    max_cfu: 30
```

### Modulo Terraform

El modulo `terraform/ccloud-flink-compute-pool` despliega los pools:

```hcl
resource "confluent_flink_compute_pool" "this" {
  for_each = {
    for idx, pool in try(local.config.compute_pools, []) : pool.pool_name => pool
  }

  display_name = each.value.pool_name

  environment {
    id = var.environment_id
  }

  cloud   = each.value.cloud
  region  = each.value.region
  max_cfu = each.value.max_cfu
}
```

---

## CFU (Confluent Flink Unit)

### Que es un CFU

Un CFU es la unidad de medida de recursos de computo en Confluent Cloud Flink. Cada statement consume CFUs segun su complejidad y volumen de datos.

### Modelo de costos

| Concepto | Detalle |
|---|---|
| Unidad de cobro | CFU-minuto |
| Precio aproximado | ~$0.21 USD / CFU-hora (~$0.0035 / CFU-minuto) |
| Minimo por statement | 1 CFU-minuto por ejecucion |
| Pool pausado (sin statements) | $0 (no consume CFUs) |

### Consumo tipico por tipo de statement

> **Nota**: La documentacion oficial no especifica CFUs exactos por tipo de operacion. Los valores siguientes son estimaciones basadas en la complejidad relativa de cada operacion. El consumo real depende del volumen de datos, paralelismo y estado acumulado.

| Tipo de Statement | CFUs tipicos (estimado) | Ejemplo |
|---|---|---|
| CREATE TABLE (DDL) | 1 CFU momentaneo | Crear tabla/vista |
| INSERT INTO SELECT simple | 1-2 CFUs | Filtrado, transformacion basica |
| INSERT INTO SELECT con ventana | 2-5 CFUs | TUMBLE, HOP, SESSION |
| INSERT INTO SELECT con JOIN | 3-10 CFUs | Temporal join, streaming join |
| INSERT INTO SELECT con agregacion compleja | 5-15 CFUs | GROUP BY multiples campos + funciones |

Segun la documentacion oficial: *"Each Flink statement consumes a minimum of 1 CFU-minute but may consume more depending on the needs of the workload."*

---

## Autopilot

Confluent Cloud incluye **Flink SQL Autopilot**, que ajusta automaticamente el paralelismo de cada statement:

- Escala **hacia arriba** cuando detecta necesidad de mas recursos
- Escala **hacia abajo** cuando los recursos no estan siendo utilizados
- Opera dentro del limite `max_cfu` del pool
- No requiere configuracion manual

### Comportamiento

1. Autopilot asigna recursos basandose en el **paralelismo** requerido por cada statement
2. Monitorea metricas como throughput, **Messages Behind** (consumer lag) y state size
3. Si detecta que el statement necesita mas recursos, aumenta el paralelismo
4. Si el pool alcanza su limite max_cfu, los statements operan con paralelismo reducido
5. Al reducirse la carga, Autopilot reduce el paralelismo

### Estados de escalamiento (Scaling Status)

| Estado | Descripcion |
|---|---|
| `Fine` | El statement tiene suficientes recursos para el paralelismo requerido |
| `Pending Scale Down` | El statement tiene mas recursos de los necesarios, se reducira |
| `Pending Scale Up` | El statement necesita mas recursos, se escalara |
| `Compute Pool Exhausted` | No hay suficientes recursos en el pool para el paralelismo requerido |

### Limites de state

Autopilot tambien considera el tamano del state al decidir el paralelismo:

| Limite | Tamano | Comportamiento |
|---|---|---|
| Alerta (80% soft limit) | 400 GB | Warnings en Console y Metrics API |
| Soft limit | 500 GB | Statement es detenido (STOPPED). Se puede reanudar pero sin garantias de SLA |
| Hard limit | 1000 GB (1 TB) | Statement falla y **no puede reanudarse** |

Estos limites son absolutos por statement, no dependen del tamano del compute pool.

---

## Buenas Practicas

### 1. Separar compute pools por prioridad

No mezclar statements criticos de produccion con queries ad-hoc o desarrollo. Cuando el pool alcanza su max_cfu, los statements compiten por recursos.

| Pool | Uso | max_cfu sugerido |
|---|---|---|
| `CP_AZC_PRO_PEVE_01` | Statements DML de produccion | 20-50 |
| `CP_AZC_DES_PEVE_01` | Desarrollo y testing | 5-10 |
| `CP_AZC_DES_PEVE_ADHOC` | Queries exploratorias (SELECT interactivos) | 5 |

### 2. Dimensionar max_cfu correctamente

- Sumar los CFUs estimados de todos los statements que correran simultaneamente
- Agregar un 30-50% de margen para picos y para que Autopilot pueda escalar
- Monitorear el consumo real y ajustar

```
max_cfu = (suma_CFUs_statements * 1.5)
```

### 3. Una region, un cloud provider

El compute pool debe estar en la **misma region y cloud provider** que el Kafka cluster. Si el cluster esta en Azure East US 2, el pool debe estar en Azure East US 2. Cross-region no esta soportado.

### 4. Nombrar con convencion clara

Usar una convencion que incluya cloud, entorno, aplicacion y secuencia:

```
CP_{cloud}_{environment}_{app}_{sequence}
```

Ejemplos:
- `CP_AZC_DES_PEVE_01` — Azure, Desarrollo, PEVE, secuencia 01
- `CP_AZC_PRO_PEVE_01` — Azure, Produccion, PEVE, secuencia 01

### 5. No eliminar pools con statements activos

Antes de eliminar un compute pool:
1. Pausar todos los statements (stopped = true)
2. Verificar que no hay statements en ejecucion
3. Eliminar los statements
4. Eliminar el pool

### 6. Monitorear consumo de CFUs

- **Confluent Cloud Console** > Flink > Compute Pools > Metricas
- Verificar: CFU utilization, statement count, statements en estado FAILED o DEGRADED
- Configurar alertas cuando el pool esta por encima del 80% de max_cfu

### 7. Evitar pools con max_cfu muy bajo

Un pool con max_cfu = 1 solo puede ejecutar un statement a la vez con paralelismo minimo. Para multiples statements, usar al menos max_cfu = 5.

### 8. Considerar el tiempo de provisionamiento

- Crear un compute pool toma entre 1-5 minutos
- Los statements no pueden ejecutarse hasta que el pool este en estado PROVISIONED
- En pipelines CI/CD, considerar un `sleep` o polling despues de crear el pool

---

## Lifecycle en Terraform

| Accion | Resultado | Impacto |
|---|---|---|
| Incrementar `max_cfu` | Update in-place | Sin impacto en statements activos |
| Reducir `max_cfu` | **No soportado** | Confluent Cloud no permite reducir max_cfu una vez creado |
| Cambiar `display_name` | Update in-place | Sin impacto en statements activos |
| Cambiar `region` o `cloud` | Destroy + Create | Pool se recrea, statements se pierden |
| Eliminar pool del YAML | Destroy | Statements fallaran si estan activos |

> **Fuente**: *"You can update the name of the compute pool, its environment, and the MAX_CFUs setting. You can increase the Max CFUs value, but decreasing Max CFUs is not supported."* — [Manage Compute Pools](https://docs.confluent.io/cloud/current/flink/operate-and-deploy/create-compute-pool.html)

### Proteccion recomendada

Para pools de produccion, agregar `prevent_destroy`:

```hcl
lifecycle {
  prevent_destroy = true
}
```

---

## RBAC para Compute Pools

Los permisos de Flink siguen un **modelo por capas**. Cada capa agrega permisos sobre la anterior.

### Capa base (obligatoria para todos los statements)

| Rol | Recurso | Motivo |
|---|---|---|
| `FlinkDeveloper` | Environment o Compute Pool | Crear y ejecutar statements |
| `DeveloperRead` | Transactional-Id: `_confluent-flink_*` (prefix) | Leer estado de transacciones (exactly-once) |
| `DeveloperWrite` | Transactional-Id: `_confluent-flink_*` (prefix) | Crear y gestionar transacciones |

### Capa de acceso a datos

| Rol | Recurso | Motivo |
|---|---|---|
| `DeveloperRead` | Topics Kafka de lectura | Leer de los topics fuente |
| `DeveloperWrite` | Topics Kafka de escritura | Escribir a los topics destino |
| `DeveloperRead` | Schema Registry subjects | Leer schemas (lectura y escritura a topics) |

### Capa de gestion de tablas (si se ejecutan DDLs como CREATE TABLE)

| Rol | Recurso | Motivo |
|---|---|---|
| `DeveloperManage` | Topics Kafka | Crear topics via CREATE TABLE |
| `DeveloperWrite` | Schema Registry subjects | Registrar schemas |

### Capa administrativa (gestion de infraestructura)

| Rol | Recurso | Motivo |
|---|---|---|
| `FlinkAdmin` | Environment | Crear/eliminar compute pools y statements |
| `Assigner` | Service Account de produccion | Delegar ejecucion de statements a un SA |

### Service Account para Terraform (despliegue)

| Rol | Recurso | Motivo |
|---|---|---|
| `FlinkAdmin` o `EnvironmentAdmin` | Environment | Crear/eliminar compute pools y statements |
| `Assigner` | Service Account de produccion | Ejecutar statements bajo el SA de produccion |

> **Fuente**: [Grant Role-Based Access in Confluent Cloud for Apache Flink](https://docs.confluent.io/cloud/current/flink/operate-and-deploy/flink-rbac.html)

---

## Troubleshooting

### Pool no esta listo

**Sintoma**: Terraform falla al crear statements porque el pool no existe.
**Causa**: El pool no ha terminado de provisionarse.
**Solucion**: Verificar estado del pool con `confluent flink compute-pool list` o agregar `depends_on` en Terraform.

### Statements compitiendo por recursos

**Sintoma**: Statements con alto lag o backpressure.
**Causa**: max_cfu insuficiente para la carga total de statements.
**Solucion**: Aumentar max_cfu o mover statements a otro pool.

### Pool con 0 CFUs consumidos

**Sintoma**: Pool creado pero no consume CFUs.
**Causa**: No hay statements en estado RUNNING.
**Solucion**: Verificar que los statements no estan en `stopped: true`.

---

## Referencias

- [Documentacion oficial: Compute Pools](https://docs.confluent.io/cloud/current/flink/concepts/compute-pools.html)
- [Documentacion oficial: Flink Billing](https://docs.confluent.io/cloud/current/flink/concepts/flink-billing.html)
- [Documentacion oficial: Autopilot](https://docs.confluent.io/cloud/current/flink/concepts/autopilot.html)
- [Documentacion oficial: Manage Compute Pools](https://docs.confluent.io/cloud/current/flink/operate-and-deploy/create-compute-pool.html)
- [Documentacion oficial: Flink RBAC](https://docs.confluent.io/cloud/current/flink/operate-and-deploy/flink-rbac.html)
- [Documentacion oficial: Flink Statements](https://docs.confluent.io/cloud/current/flink/concepts/statements.html)
