# Modelo Operativo: Flink SQL Statements

## Confluent Cloud for Apache Flink

---

## Conceptos Fundamentales

### DDL vs DML

| Tipo | Significado | Que hace | Ejemplo |
|---|---|---|---|
| **DDL** | Data Definition Language | Define/modifica metadata (tablas, vistas) | CREATE TABLE, ALTER TABLE, DROP TABLE |
| **DML** | Data Manipulation Language | Procesa/transforma datos | INSERT INTO SELECT, SELECT |

### Por que son necesarios los DDLs

En Confluent Cloud Flink, **los topics de Kafka no son visibles como tablas automaticamente**. Para que Flink pueda leer o escribir en un topic, necesitas crear un DDL (CREATE TABLE) que:

1. Mapea el topic de Kafka a una tabla Flink
2. Define el schema de los campos (tipos de datos)
3. Establece el formato de serializacion (AVRO, JSON_SR, PROTOBUF)
4. Configura la estrategia de watermark para procesamiento basado en tiempo de evento
5. Define propiedades adicionales (changelog.mode, scan.startup.mode, etc.)

Sin un DDL, Flink no puede interactuar con el topic.

**Nota**: Si el topic ya tiene un schema registrado en Schema Registry, Confluent Cloud puede auto-detectar la tabla. Sin embargo, para control total (watermarks custom, propiedades especificas), se recomienda crear el DDL explicitamente.

### Inmutabilidad de statements

El SQL de un statement es **inmutable**: no se puede modificar una vez enviado. Si necesitas editar un statement, debes detener el statement actual y crear uno nuevo con el SQL corregido.

### Limites importantes

| Limite | Valor | Notas |
|---|---|---|
| Tamano del query SQL | 4 MB | Incluye literals de string y binarios |
| Largo del statement-name | 72 caracteres | Maximo permitido |
| State size (soft limit) | 500 GB por statement | Statement es detenido (STOPPED), puede reanudarse sin garantias de SLA |
| State size (hard limit) | 1000 GB (1 TB) por statement | Statement falla y **no puede reanudarse** |
| Retencion en estados terminales | 30 dias | Statements en STOPPED se eliminan automaticamente |
| Foreground statement idle | 5 minutos | Si no hay consumidor, se mueve a STOPPED |

---

## Tabla de Equivalencia de Tipos de Datos: Avro a Flink SQL

Fuente: [Documentacion oficial de Confluent](https://docs.confluent.io/cloud/current/flink/reference/serialization.html)

### Tipos primitivos

| Tipo Avro | Logical Type Avro | Tipo Flink SQL | Notas |
|---|---|---|---|
| `boolean` | — | `BOOLEAN` | |
| `int` | — | `INT` | |
| `int` | `date` | `DATE` | Dias desde epoch |
| `int` | `time-millis` | `TIME(3)` | Milisegundos desde medianoche |
| `long` | — | `BIGINT` | |
| `long` | `timestamp-millis` | `TIMESTAMP_LTZ(3)` | Con zona horaria |
| `long` | `timestamp-micros` | `TIMESTAMP_LTZ(6)` | Con zona horaria |
| `long` | `local-timestamp-millis` | `TIMESTAMP(3)` | Sin zona horaria |
| `long` | `local-timestamp-micros` | `TIMESTAMP(6)` | Sin zona horaria |
| `float` | — | `FLOAT` | |
| `double` | — | `DOUBLE` | |
| `string` | — | `VARCHAR` / `STRING` | |
| `enum` | — | `STRING` | Avro enums se tratan como STRING |
| `bytes` | — | `BYTES` / `VARBINARY` | |
| `bytes` | `decimal` | `DECIMAL(p, s)` | Precision y escala del logical type |
| `fixed` | — | `BINARY` | |

### Tipos adicionales (Flink a Avro)

| Tipo Flink SQL | Tipo Avro resultante | Notas |
|---|---|---|
| `TINYINT` | `int` | No tiene tipo Avro nativo, se mapea a int |
| `SMALLINT` | `int` | No tiene tipo Avro nativo, se mapea a int |
| `CHAR(n)` | `string` | Con propiedad adicional `flink.maxLength` |

### Tipos complejos

| Tipo Avro | Tipo Flink SQL | Ejemplo Flink |
|---|---|---|
| `record` | `ROW` | `ROW<name STRING, age INT>` |
| `array` | `ARRAY` | `ARRAY<STRING>` |
| `map` | `MAP` | `MAP<STRING, INT>` |
| `union(T, null)` | `T` (nullable) | Campo nullable por defecto |

### Tipos NO soportados

| Tipo | Notas |
|---|---|
| `time-micros` (Avro) | Se lee como BIGINT, no como TIME |
| `INTERVAL DAY TO SECOND` (Flink) | No tiene equivalente Avro |
| `INTERVAL YEAR TO MONTH` (Flink) | No tiene equivalente Avro |
| `TIMESTAMP WITH TIME ZONE` (Flink) | No soportado en Avro |

### Limitaciones conocidas

- **Avro enums**: Flink los trata como STRING. No se pueden crear enums desde Flink.
- **Nombres de campos**: Deben cumplir el patron Avro: iniciar con `[A-Za-z_]`, luego `[A-Za-z0-9_]`.
- **time-micros**: No se puede leer como TIME (Flink solo soporta TIME hasta precision 3).

---

## Estructura de un DDL (CREATE TABLE)

### Ejemplo basico: Topic Avro simple

```sql
CREATE TABLE `catalog`.`cluster`.`mi-topic` (
  transaction_id STRING,
  amount DOUBLE,
  currency STRING,
  created_at TIMESTAMP(3),
  WATERMARK FOR created_at AS created_at - INTERVAL '5' SECONDS
);
```

### Ejemplo: Topic Avro con schema anidado

```sql
CREATE TABLE `catalog`.`cluster`.`mi-topic-complejo` (
  order_id STRING,
  customer ROW<
    name STRING,
    email STRING,
    address ROW<
      street STRING,
      city STRING,
      country STRING
    >
  >,
  items ARRAY<ROW<
    product_id STRING,
    quantity INT,
    price DOUBLE
  >>,
  metadata MAP<STRING, STRING>,
  created_at TIMESTAMP_LTZ(3),
  WATERMARK FOR created_at AS created_at - INTERVAL '10' SECONDS
);
```

### Ejemplo: DDL con propiedades de connector y changelog

```sql
CREATE TABLE `catalog`.`cluster`.`mi-topic-changelog` (
  id STRING,
  name STRING,
  value DOUBLE,
  updated_at TIMESTAMP(3),
  WATERMARK FOR updated_at AS updated_at - INTERVAL '5' SECONDS
) WITH (
  'changelog.mode' = 'upsert',
  'kafka.cleanup-policy' = 'compact',
  'scan.startup.mode' = 'earliest-offset'
);
```

### Propiedades WITH comunes

| Propiedad | Valores | Descripcion |
|---|---|---|
| `changelog.mode` | `append`, `upsert`, `retract` | Como Flink interpreta los cambios |
| `scan.startup.mode` | `earliest-offset`, `latest-offset`, `timestamp` | Desde donde leer el topic |
| `scan.startup.timestamp-millis` | Epoch en ms | Usado con `scan.startup.mode = timestamp` |
| `kafka.cleanup-policy` | `delete`, `compact` | Politica de limpieza del topic |
| `value.format` | `avro-confluent`, `json-sr`, `protobuf` | Formato de serializacion |

---

## Estructura de un DML (INSERT INTO SELECT)

### Archivo YAML de configuracion

```yaml
statement-name: "insert-target-from-source-v1"
flink-compute-pool: "CP_AZC_${environment}_PEVE_01"
stopped: "false"
statement: |
  INSERT INTO `${catalog_name}`.`${cluster_name}`.`target-topic`
  SELECT
    field1,
    field2,
    UPPER(field3) AS field3_normalized
  FROM `${catalog_name}`.`${cluster_name}`.`source-topic`
  WHERE field1 IS NOT NULL;
```

### Variables soportadas en statements

| Variable | Se reemplaza por | Ejemplo |
|---|---|---|
| `${catalog_name}` | Nombre del catalog Flink | `peve-catalog` |
| `${cluster_name}` | Nombre del cluster Kafka | `azure_eu2_kafka01` |
| `${environment}` | Entorno (DES, CER, PRO) | `DES` |

---

## Estrategias de Control de Errores

### 1. TRY_CAST — Casteo seguro

Retorna NULL en vez de fallar si el dato no es convertible:

```sql
INSERT INTO target_table
SELECT
  TRY_CAST(raw_amount AS DOUBLE) AS amount,
  TRY_CAST(raw_quantity AS INT) AS quantity
FROM source_table;
```

### 2. COALESCE — Valores por defecto

Reemplaza NULLs con valores seguros:

```sql
INSERT INTO target_table
SELECT
  COALESCE(TRY_CAST(amount AS DOUBLE), 0.0) AS amount,
  COALESCE(customer_name, 'DESCONOCIDO') AS customer_name
FROM source_table;
```

### 3. WHERE — Filtrar eventos invalidos

Descarta registros que no cumplen criterios minimos:

```sql
INSERT INTO target_table
SELECT field1, field2, field3
FROM source_table
WHERE field1 IS NOT NULL
  AND field2 > 0
  AND LENGTH(field3) > 0;
```

### 4. Dead Letter Queue (DLQ) — Redirigir eventos invalidos

Dos statements complementarios: uno para datos validos y otro para invalidos:

```sql
-- Statement 1: Eventos validos al destino
INSERT INTO target_table
SELECT transaction_id, amount, currency
FROM source_table
WHERE amount IS NOT NULL AND amount > 0 AND currency IS NOT NULL;

-- Statement 2: Eventos invalidos al DLQ
INSERT INTO source_table_dlq
SELECT transaction_id, amount, currency,
  CASE
    WHEN amount IS NULL THEN 'amount es NULL'
    WHEN amount <= 0 THEN 'amount invalido'
    WHEN currency IS NULL THEN 'currency es NULL'
    ELSE 'error desconocido'
  END AS error_reason,
  CURRENT_TIMESTAMP AS error_timestamp
FROM source_table
WHERE amount IS NULL OR amount <= 0 OR currency IS NULL;
```

### 5. CASE WHEN — Normalizacion y clasificacion

```sql
INSERT INTO target_table
SELECT
  transaction_id,
  CASE
    WHEN amount < 0 THEN 0
    WHEN amount > 1000000 THEN 1000000
    ELSE amount
  END AS amount_sanitized,
  CASE
    WHEN currency IS NULL OR currency = '' THEN 'USD'
    ELSE UPPER(TRIM(currency))
  END AS currency_normalized
FROM source_table;
```

---

## Casos de Uso: Ejemplos de Statements

### 1. Filtrado y enriquecimiento en tiempo real

Filtrar transacciones sospechosas y agregar metadata:

```sql
INSERT INTO transactions_enriched
SELECT
  t.transaction_id,
  t.amount,
  t.currency,
  t.customer_id,
  CASE
    WHEN t.amount > 10000 THEN 'HIGH_VALUE'
    WHEN t.amount > 1000 THEN 'MEDIUM_VALUE'
    ELSE 'LOW_VALUE'
  END AS risk_category,
  CURRENT_TIMESTAMP AS processed_at
FROM transactions t
WHERE t.amount > 0 AND t.status = 'COMPLETED';
```

### 2. Agregacion en ventanas de tiempo (TUMBLE)

Calcular metricas por ventana de 5 minutos:

```sql
INSERT INTO transaction_metrics_5m
SELECT
  window_start,
  window_end,
  currency,
  COUNT(*) AS transaction_count,
  SUM(amount) AS total_amount,
  AVG(amount) AS avg_amount,
  MAX(amount) AS max_amount
FROM TABLE(
  TUMBLE(TABLE transactions, DESCRIPTOR($rowtime), INTERVAL '5' MINUTES)
)
GROUP BY window_start, window_end, currency;
```

### 3. Ventanas deslizantes (HOP)

Calcular promedio movil cada minuto con ventana de 10 minutos:

```sql
INSERT INTO moving_avg_metrics
SELECT
  window_start,
  window_end,
  product_id,
  AVG(price) AS avg_price_10m,
  COUNT(*) AS event_count
FROM TABLE(
  HOP(TABLE price_events, DESCRIPTOR($rowtime), INTERVAL '1' MINUTE, INTERVAL '10' MINUTES)
)
GROUP BY window_start, window_end, product_id;
```

### 4. Deduplicacion de eventos

Eliminar eventos duplicados basandose en un ID unico:

```sql
INSERT INTO events_deduplicated
SELECT event_id, payload, event_time
FROM (
  SELECT *,
    ROW_NUMBER() OVER (
      PARTITION BY event_id
      ORDER BY $rowtime ASC
    ) AS row_num
  FROM raw_events
)
WHERE row_num = 1;
```

### 5. Temporal Join — Enriquecer stream con tabla de referencia

Unir un stream de transacciones con una tabla de tipos de cambio:

```sql
INSERT INTO transactions_with_usd
SELECT
  t.transaction_id,
  t.amount,
  t.currency,
  t.amount * r.rate_to_usd AS amount_usd,
  t.$rowtime AS transaction_time
FROM transactions t
JOIN exchange_rates FOR SYSTEM_TIME AS OF t.$rowtime AS r
  ON t.currency = r.currency;
```

### 6. Pattern matching (MATCH_RECOGNIZE)

Detectar patrones de fraude: 3+ transacciones en menos de 1 minuto:

```sql
INSERT INTO fraud_alerts
SELECT *
FROM transactions
MATCH_RECOGNIZE (
  PARTITION BY customer_id
  ORDER BY $rowtime
  MEASURES
    FIRST(A.transaction_id) AS first_tx,
    LAST(A.transaction_id) AS last_tx,
    COUNT(A.transaction_id) AS tx_count,
    FIRST(A.$rowtime) AS first_time,
    LAST(A.$rowtime) AS last_time
  ONE ROW PER MATCH
  AFTER MATCH SKIP PAST LAST ROW
  PATTERN (A{3,})
  DEFINE
    A AS A.$rowtime - FIRST(A.$rowtime) < INTERVAL '1' MINUTE
);
```

### 7. Conversion de formato de serializacion

Convertir un topic de AVRO a JSON:

```sql
-- DDL: Tabla fuente (AVRO)
CREATE TABLE source_avro (
  id STRING,
  name STRING,
  value DOUBLE
) WITH (
  'value.format' = 'avro-confluent'
);

-- DDL: Tabla destino (JSON)
CREATE TABLE target_json (
  id STRING,
  name STRING,
  value DOUBLE
) WITH (
  'value.format' = 'json-sr'
);

-- DML: Copiar datos convirtiendo formato
INSERT INTO target_json
SELECT id, name, value FROM source_avro;
```

### 8. Ventana de sesion (SESSION)

Agrupar eventos de actividad de usuario por sesion (gap de 30 minutos):

```sql
INSERT INTO user_sessions
SELECT
  window_start AS session_start,
  window_end AS session_end,
  user_id,
  COUNT(*) AS event_count,
  TIMESTAMPDIFF(MINUTE, window_start, window_end) AS session_duration_min
FROM TABLE(
  SESSION(TABLE user_events PARTITION BY user_id, DESCRIPTOR($rowtime), INTERVAL '30' MINUTES)
)
GROUP BY window_start, window_end, user_id;
```

---

## Buenas Practicas para Statements

### 1. Validar la estrategia de watermark

El watermark por defecto usa `$rowtime` (timestamp del record Kafka). Los watermarks se calculan **por particion Kafka** y requieren al menos **250 eventos por particion** para activarse. Definir watermark custom cuando:
- El tiempo de evento esta en el payload, no en el timestamp del record
- Puede haber retrasos mayores a 7 dias
- Los eventos llegan desordenados
- Los datos pueden llegar tarde por latencia de red o procesamiento

```sql
CREATE TABLE mi_tabla (
  event_id STRING,
  event_time TIMESTAMP(3),
  payload STRING,
  WATERMARK FOR event_time AS event_time - INTERVAL '30' SECONDS
);
```

### 2. Configurar idleness handling

Confluent Cloud implementa **Progressive Idleness**: la deteccion de inactividad inicia en **15 segundos** y crece linealmente con la edad del statement hasta un maximo de **5 minutos**. Si una particion es marcada como idle demasiado rapido, el watermark puede avanzar incorrectamente.

Para configurar manualmente el timeout:

```sql
SET 'sql.tables.scan.idle-timeout' = '30s';
```

O deshabilitar si causa problemas con el progreso del watermark:

```sql
SET 'sql.tables.scan.idle-timeout' = '0';
```

### 3. Implementar State TTL

Para operaciones stateful (joins, pattern matching), configurar TTL para evitar crecimiento infinito del state:

```sql
SET 'sql.state-ttl' = '24h';
```

### 4. Usar nombres descriptivos para statements

```yaml
# Bueno
statement-name: "insert-enriched-transactions-from-raw-v1"

# Malo
statement-name: "dml-001"
```

Incluir version (`v1`, `v2`) facilita la trazabilidad de cambios.

### 5. Usar FULL_TRANSITIVE en Schema Registry

Configurar la compatibilidad del schema como `FULL_TRANSITIVE` para evitar que cambios de schema rompan statements en ejecucion. Un statement Flink es productor y consumidor simultaneamente, por lo que se requiere la compatibilidad mas estricta.

> **Fuente**: *"Consider using FULL_TRANSITIVE compatibility to ensure that any new schema is fully compatible with all previous versions of the schema."* — [Best Practices](https://docs.confluent.io/cloud/current/flink/operate-and-deploy/best-practices.html)

### 6. Preferir temporal joins sobre streaming joins

Los temporal joins:
- Usan menos estado (menos CFUs, menos costo)
- Producen resultados insert-only (sin retracciones)
- Son mas predecibles en performance

### 7. Usar Service Account API Keys en produccion

Nunca usar API keys de usuario para statements de produccion. Si el usuario se elimina, los statements fallan.

### 8. Probar statements en un pool de desarrollo

Siempre probar en un compute pool de desarrollo antes de desplegar a produccion. Verificar:
- El statement compila y arranca correctamente
- Los tipos de datos son compatibles
- El watermark progresa
- No hay backpressure excesivo

### 9. Versionado de statements

Cuando necesitas modificar el SQL de un DML:
1. Crear un nuevo archivo YAML con el SQL actualizado y nuevo statement-name (ej: `v2`)
2. Eliminar el archivo YAML anterior o poner `stopped: true`
3. Ejecutar `terraform plan` para verificar que propone crear el nuevo y eliminar el antiguo
4. Aplicar el cambio

**Nunca** cambiar el SQL de un statement in-place. El SQL es inmutable en Confluent Cloud; cualquier cambio resulta en la destruccion del statement actual y la creacion de uno nuevo, perdiendo los offsets.

### 10. Orden de ejecucion DDL antes que DML

El modulo Terraform ya maneja esto con `depends_on`:

```hcl
resource "confluent_flink_statement" "dml_statements" {
  ...
  depends_on = [confluent_flink_statement.ddl_statements]
}
```

Pero adicionalmente, nombrar los archivos con prefijo numerico para asegurar orden:

```
ddl/
  01_tabla-input.yaml
  02_tabla-output.yaml
dml/
  01_insert-output-from-input.yaml
```

---

## Lifecycle en Terraform

| Accion | Resultado | Offsets |
|---|---|---|
| Cambiar SQL del statement | Destroy + Create (SQL es inmutable) | Se pierden |
| Cambiar `stopped` (true/false) | Update in-place | Se conservan |
| Cambiar `statement-name` | Nuevo statement creado | Se pierden |
| Renombrar archivo YAML | Destroy antiguo + Create nuevo | Se pierden |
| Agregar nuevo archivo YAML | Create nuevo | N/A |
| Eliminar archivo YAML | Destroy statement | Se pierden |

### Precondiciones implementadas

```hcl
lifecycle {
  precondition {
    condition     = can(each.value["statement-name"])
    error_message = "El campo 'statement-name' es obligatorio. NO cambies el statement-name despues de la creacion inicial."
  }
}
```

---

## Monitoreo de Statements

### Estados posibles

| Estado | Significado | Accion |
|---|---|---|
| `PENDING` | Statement enviado, Flink preparando ejecucion | Esperar o verificar max_cfu |
| `RUNNING` | Ejecutandose normalmente | Monitorear lag y scaling status |
| `DEGRADED` | Statement con comportamiento anomalo (sin commits recientes o restarts frecuentes) | Revisar excepciones y metricas |
| `STOPPING` | Statement en proceso de detencion | Esperar |
| `STOPPED` | Pausado intencionalmente | Reanudar con `stopped: false` |
| `FAILED` | Error terminal, statement dejo de ejecutar | Revisar logs, corregir y reenviar |
| `COMPLETED` | Finalizado (solo DDL y SELECT acotados) | Normal para DDLs |
| `DELETING` | En proceso de eliminacion | Esperar |

> **Nota**: Confluent Cloud aplica una retencion de **30 dias** para statements en estados terminales. Una vez que un statement pasa a STOPPED, ya no consume compute y se elimina automaticamente a los 30 dias.

### Metricas clave

| Metrica | Que monitorear | Umbral de alerta |
|---|---|---|
| **Consumer lag** | Retraso en lectura del topic | > 10,000 registros |
| **Backpressure** | Congestion en el procesamiento | > 50% sostenido |
| **CFU utilization** | Consumo de recursos del pool | > 80% del max_cfu |
| **Checkpoint duration** | Tiempo de snapshot del state | > 60 segundos |
| **Restarts** | Numero de restarts del statement | > 3 en 1 hora |

---

## Troubleshooting

### Statement en FAILED

**Causa comun**: Schema incompatible, topic no existe, permisos insuficientes.
**Solucion**:
1. Revisar el error en Confluent Cloud Console > Flink > Statements > [statement] > Exceptions
2. Verificar que el DDL coincide con el schema del topic
3. Verificar permisos RBAC del SA

### Watermark no progresa

**Causa comun**: Particiones idle, no llegan eventos.
**Solucion**:
1. Verificar que el topic tiene datos
2. Configurar `sql.tables.scan.idle-timeout`
3. Verificar que el campo de watermark tiene valores validos

### Statement consume muchos CFUs

**Causa comun**: Streaming join sin TTL, state creciendo infinitamente.
**Solucion**:
1. Configurar `sql.state-ttl`
2. Preferir temporal joins
3. Reducir complejidad de la query

### Datos duplicados en el destino

**Causa comun**: Statement recreado sin offset tracking, at-least-once semantics.
**Solucion**:
1. Usar deduplicacion con `ROW_NUMBER()`
2. Verificar que el topic destino tiene la key correcta para upsert

---

## Referencias

- [Documentacion oficial: Flink SQL Statements (conceptos)](https://docs.confluent.io/cloud/current/flink/concepts/statements.html)
- [Documentacion oficial: Data Type Mappings](https://docs.confluent.io/cloud/current/flink/reference/serialization.html)
- [Documentacion oficial: Best Practices](https://docs.confluent.io/cloud/current/flink/operate-and-deploy/best-practices.html)
- [Documentacion oficial: SQL Statements Overview](https://docs.confluent.io/cloud/current/flink/reference/statements/overview.html)
- [Documentacion oficial: Queries Overview](https://docs.confluent.io/cloud/current/flink/reference/queries/overview.html)
- [Documentacion oficial: Monitor Statements](https://docs.confluent.io/cloud/current/flink/operate-and-deploy/monitor-statements.html)
- [Documentacion oficial: Timely Stream Processing](https://docs.confluent.io/cloud/current/flink/concepts/timely-stream-processing.html)
- [Documentacion oficial: Flink RBAC](https://docs.confluent.io/cloud/current/flink/operate-and-deploy/flink-rbac.html)
- [Documentacion oficial: Autopilot](https://docs.confluent.io/cloud/current/flink/concepts/autopilot.html)
