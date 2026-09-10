# Pruebas de performance — use-case-name-02

Datagen (`peve-datagen-source-connector-01`) produce a `azc-peve-transaction` (**6 particiones**, Avro, `quickstart: TRANSACTIONS`). Postgres Sink (`peve-postgresql-sink-connector-01`) lee ese topic y escribe en Azure Database for PostgreSQL.

Objetivo: **encontrar el techo del sink**, no equilibrar el pipeline. Datagen tiene que producir de más; el lag del consumer del sink es la señal. Si el lag no crece, Datagen no está empujando suficiente.

Host, Vault, SA, `ssl.mode` y `errors.tolerance` se quedan como están. Solo cambian las propiedades de este documento. `tasks.max` del sink **no pasa de 6**.

YAML actual (punto de partida, no es un caso de carga): Datagen `tasks.max: 1` sin `max.interval` (1000 ms); sink `tasks.max: 1`, `batch.sizes` 3000 y `max.poll.records` 500 por default, `INSERT`. Si con eso ya hay lag, para: es red, SSL, tabla o SKU, no throughput.

Entre caso y caso: pausa Datagen, espera a que el lag del sink baje (o acepta el residual), aplica el YAML nuevo, arranca **primero el sink** y después Datagen. Cada caso ~15–20 min en régimen. No mezcles cambios de SKU de Postgres con cambios de YAML en el mismo run.

Qué mirar: consumer lag del sink, `pg_stat_activity` (conexiones = `tasks.max` del sink + extras), CPU / IOPS / WAL del Flexible Server, restarts de la task, DLQ (`azc-peve-transaction-dlq`).

---

## Caso 1 — Datagen a tope, sink igual (1 task)

El sink queda con 1 task / defaults. Seis particiones alimentadas; una sola task las consume. El cuello tiene que ser el conector Postgres (o la base con 1 conexión JDBC).

**Datagen**

```yaml
tasks.max: "6"
max.interval: "5"
```

**Postgres** — sin cambios vs caso 0 (`tasks.max: "1"`).

Límite que buscas: lag del sink **sube lineal**. CPU de Postgres 1 sesión ocupada. Si Datagen no llena las 6 particiones, baja `max.interval` no más de 5 (mínimo del conector).

---

## Caso 2 — sink a 3 tasks (mitad de particiones)

Misma avalancha de Datagen. El sink duplica consumidores y conexiones. Mides si Postgres escala en conexiones o si el WAL/IOPS ya pinchan.

**Datagen** — igual que caso 1 (`tasks.max: "6"`, `max.interval: "5"`).

**Postgres**

```yaml
tasks.max: "3"
batch.sizes: "3000"
max.poll.records: "2000"
```

Límite que buscas: lag menor que en el caso 1, pero no a cero. 3 sesiones en `pg_stat_activity` haciendo `INSERT`. Si el lag **no** baja vs caso 1, la base ya era el techo con 1 task (IOPS/CPU), no el número de tasks.

---

## Caso 3 — sink a 6 tasks, batch JDBC al máximo (INSERT)

Paralelismo = particiones. Batch JDBC 5000 (tope del conector) y poll alto. Presión máxima de **INSERT** puro.

**Datagen** — igual que caso 1.

**Postgres**

```yaml
tasks.max: "6"
insert.mode: "INSERT"
batch.sizes: "5000"
max.poll.records: "5000"
max.poll.interval.ms: "600000"
```

`max.poll.interval.ms` a 10 min: un batch grande no puede disparar rebalance.

Límite que buscas: 6 conexiones, CPU o IOPS del SKU en ~100 %, checkpoints WAL, o tasks en Failed / timeout. Si el lag llega a 0 y la CPU de Postgres no está alta, Datagen no alcanza (no es el techo del sink).

`max_connections` del Flexible Server tiene que aguantar 6 + app + admin. PgBouncer en transaction pooling no: el sink usa prepared statements.

---

## Caso 4 — igual que 3, UPSERT (contención)

El peor caso típico para Postgres: `ON CONFLICT` por PK, locks y WAL más pesado que el INSERT. Misma paralelismo y batch.

La tabla necesita unique/PK en `transaction_id` (campo del quickstart `TRANSACTIONS`). Sin eso el conector falla al arrancar.

**Datagen** — igual que caso 1.

**Postgres**

```yaml
tasks.max: "6"
insert.mode: "UPSERT"
pk.mode: "record_value"
pk.fields: "transaction_id"
batch.sizes: "5000"
max.poll.records: "5000"
max.poll.interval.ms: "600000"
```

Límite que buscas: write time por batch mucho mayor que en el caso 3, waits de lock en `pg_stat_activity`, lag que no baja aunque CPU no esté al 100 % (contención). Si Datagen no reusa `transaction_id`, casi no hay conflicto y este caso se parece al 3: no es un fallo del YAML, es el generador.

---

## Caso 5 — poll pequeño, batch grande (round-trips vs JDBC)

Datagen igual. Sink en 6 tasks pero `max.poll.records` bajo y `batch.sizes` alto: muchas idas a Kafka, batches JDBC a medias. Distingue si el techo es **JDBC/Postgres** (caso 3) o el **ciclo poll del conector**.

**Datagen** — igual que caso 1.

**Postgres**

```yaml
tasks.max: "6"
insert.mode: "INSERT"
batch.sizes: "5000"
max.poll.records: "200"
max.poll.interval.ms: "300000"
```

Límite que buscas: más CPU en el conector / más polls, menos filas/s que el caso 3 con la **misma** base. Si las filas/s son casi iguales al caso 3, el techo era Postgres, no el poll.

---

## Cómo leer el resultado

| Señal | Interpretación |
|---|---|
| Caso 1 lag↑, caso 3 lag↓, CPU Postgres alta | El sink era el cuello; 6 tasks + batch lo empujan hasta el SKU. |
| Caso 1 y 3 con el mismo lag, CPU/IOPS Postgres al tope | El YAML ya no da: SKU, disco o índices/FK de la tabla. |
| Caso 3 bien, caso 4 lag↑ o locks | El techo real en upsert; en ingest usa `INSERT` y PK/índices mínimos. |
| Caso 3 bien, caso 5 peor | Sube `max.poll.records`; no bajes tasks. |
| Tasks Failed, DLQ crece | Baja `batch.sizes` (p. ej. 1000) y sube `max.poll.interval.ms`. `errors.tolerance: all` esconde filas perdidas: para medir techo, mira DLQ o pon `none` un rato. |

No subas `tasks.max` del sink por encima de 6. No actives `auto.create` / `auto.evolve` en estas pruebas.
