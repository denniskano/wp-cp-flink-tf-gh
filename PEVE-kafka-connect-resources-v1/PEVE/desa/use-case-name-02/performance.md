# Pruebas de estrés — use-case-name-02

Source: [`ccloud-datagen-source-connector-01.yaml`](connects/ccloud-datagen-source-connector-01.yaml) (`peve-datagen-source-connector-01`) → topic `azc-peve-transaction` (6 particiones, Avro `TRANSACTIONS`).

Sink: [`ccloud-postgresql-sink-connector-01.yaml`](connects/ccloud-postgresql-sink-connector-01.yaml) (`peve-postgresql-sink-connector-01`) → `peved02server.postgres.database.azure.com` / DB `postgres`.

En cada escenario el **sink y la DB se quedan fijos**. El **source** se corre tres veces (config 1 → 2 → 3), 10 min cada una. Anota lag, filas/s, CPU/IOPS, DLQ.

No se tocan: host, Vault, SA, `ssl.mode`, `errors.tolerance`, `quickstart`, topic. `insert.mode: INSERT`. Sin `iterations`. Primero sink `RUNNING`, después source.

```text
rec/s ≈ tasks.max × (1000 / max.interval)     # max.interval mínimo = 5
```

Las tres configs del source (iguales en los 5 escenarios):

| Config source | `tasks.max` | `max.interval` | Volumen ≈ |
|---|---|---|---|
| 1 | 1 | 20 | ~50 rec/s |
| 2 | 3 | 5 | ~600 rec/s |
| 3 | 6 | 5 | ~1 200 rec/s |

Techo de Datagen ≈ **1 200 rec/s**. Si en source-3 el lag es 0 y la CPU de Postgres está baja, la DB no se estresó.

| Señal | Sink | DB |
|---|---|---|
| Lag ≈ 0, CPU baja | Absorbe | No estresada |
| Lag crece, IOPS bajos | Corto de tasks/batch | Holgada |
| Lag crece, CPU/IOPS al tope | Empuja | Techo del SKU |
| Source-3, lag 0, CPU baja | Bien | Datagen no alcanza |

---

## Escenario 1 — piso (1 task, batch bajo)

### Conector source

| | `tasks.max` | `max.interval` | ≈ rec/s |
|---|---|---|---|
| Config 1 | 1 | 20 | ~50 |
| Config 2 | 3 | 5 | ~600 |
| Config 3 | 6 | 5 | ~1 200 |

```yaml
# config 1
tasks.max: "1"
max.interval: "20"
# config 2  →  tasks.max: "3"  /  max.interval: "5"
# config 3  →  tasks.max: "6"  /  max.interval: "5"
```

### Conector sink

```yaml
tasks.max: "1"
insert.mode: "INSERT"
batch.sizes: "1000"
max.poll.records: "500"
max.poll.interval.ms: "300000"
```

### DB

Sin cambios. SKU DES, solo PK en `azc-peve-transaction`, `max_connections` default.

### Esperado

Capacidad sink 1 500–3 000 filas/s. Con Datagen: config 1–3 las absorbe (lag ≈ 0) si la red está bien. CPU/IOPS bajos. Si el lag ya crece en config 1 o 2: EAP, SSL o tabla — para.

---

## Escenario 2 — 1 task, más batch

### Conector source

| | `tasks.max` | `max.interval` | ≈ rec/s |
|---|---|---|---|
| Config 1 | 1 | 20 | ~50 |
| Config 2 | 3 | 5 | ~600 |
| Config 3 | 6 | 5 | ~1 200 |

```yaml
# mismas 3 configs que el escenario 1
```

### Conector sink

```yaml
tasks.max: "1"
insert.mode: "INSERT"
batch.sizes: "3000"
max.poll.records: "1500"
max.poll.interval.ms: "300000"
```

### DB

Sin cambios de SKU. `SHOW max_wal_size` / `checkpoint_timeout`. Sube `max_wal_size` solo si hay checkpoints en sierra.

### Esperado

Capacidad sink 3 000–6 000 filas/s. Con Datagen el tope medible sigue ~1 200. Compara vs escenario 1: misma filas/s, menos round-trips / CPU de la sesión. Si source-3 sigue con lag 0, el batch no era el límite.

---

## Escenario 3 — 3 tasks

### Conector source

| | `tasks.max` | `max.interval` | ≈ rec/s |
|---|---|---|---|
| Config 1 | 1 | 20 | ~50 |
| Config 2 | 3 | 5 | ~600 |
| Config 3 | 6 | 5 | ~1 200 |

En config 1 el source solo llena 1 partición: 2 de las 3 tasks del sink van a estar quietas. Config 2–3 son las que importan.

### Conector sink

```yaml
tasks.max: "3"
insert.mode: "INSERT"
batch.sizes: "3000"
max.poll.records: "1500"
max.poll.interval.ms: "300000"
```

### DB

`max_connections` ≥ 20. Tres backends del user de Connect (`pg_stat_activity`).

### Esperado

Capacidad sink 6 000–12 000 filas/s. Medible: ~50 / ~600 / ~1 200. Lag ≈ 0; 3 sesiones. CPU DB baja = aún no estresas el SKU.

---

## Escenario 4 — 6 tasks, batch alto

### Conector source

| | `tasks.max` | `max.interval` | ≈ rec/s |
|---|---|---|---|
| Config 1 | 1 | 20 | ~50 |
| Config 2 | 3 | 5 | ~600 |
| Config 3 | 6 | 5 | ~1 200 |

Config 3 es la que llena las 6 particiones. 1 y 2 dejan tasks del sink sin datos.

### Conector sink

```yaml
tasks.max: "6"
insert.mode: "INSERT"
batch.sizes: "5000"
max.poll.records: "3000"
max.poll.interval.ms: "600000"
```

### DB

`max_connections` ≥ 30. Seis backends del user de Connect. `max_wal_size` 4–8 GB si hay sierra de checkpoints. Autovacuum `scale_factor` 0.05–0.1 en la tabla si `n_dead_tup` crece.

### Esperado

Capacidad sink 10 000–18 000 filas/s. Medible ~1 200 en source-3. Seis conexiones, CPU/IOPS bajos en 4 vCores = Datagen no estresa la DB.

---

## Escenario 5 — perfil ingest (sink al máximo)

### Conector source

| | `tasks.max` | `max.interval` | ≈ rec/s |
|---|---|---|---|
| Config 1 | 1 | 20 | ~50 |
| Config 2 | 3 | 5 | ~600 |
| Config 3 | 6 | 5 | ~1 200 |

### Conector sink

```yaml
tasks.max: "6"
insert.mode: "INSERT"
batch.sizes: "5000"
max.poll.records: "5000"
max.poll.interval.ms: "600000"
```

### DB

Revertir al terminar.

| Cambio | Acción |
|---|---|
| Índices secundarios | `DROP` (dejar solo PK) |
| FK / triggers / RLS | Fuera de `azc-peve-transaction` |
| `FILLFACTOR` | 100 |
| Autovacuum tabla | `autovacuum_vacuum_scale_factor = 0.02` |
| `max_connections` | ≥ 30 |
| SKU | Subir vCores/IOPS solo si el escenario 4 ya saturó |

```sql
ALTER TABLE azc-peve-transaction SET (
  fillfactor = 100,
  autovacuum_vacuum_scale_factor = 0.02,
  autovacuum_analyze_scale_factor = 0.01
);
```

No `UNLOGGED`.

### Esperado

Capacidad sink 15 000–30 000 filas/s — no medible con Datagen. En source-3 ~1 200, misma señal que el 4 si el SKU está holgado.

---

## Resumen

| Escenario | Source (1 / 2 / 3) | Sink | DB | Capacidad sink | Con Datagen |
|---|---|---|---|---|---|
| 1 | 50 / 600 / 1 200 rec/s | 1 task, batch 1000, poll 500 | Default | 1 500–3 000 filas/s | Lag 0 si la red está bien |
| 2 | 50 / 600 / 1 200 rec/s | 1 task, batch 3000, poll 1500 | WAL si hay checkpoints | 3 000–6 000 filas/s | ~1 200; menos round-trips vs 1 |
| 3 | 50 / 600 / 1 200 rec/s | 3 tasks, batch 3000, poll 1500 | `max_connections` ≥ 20 | 6 000–12 000 filas/s | 3 sesiones |
| 4 | 50 / 600 / 1 200 rec/s | 6 tasks, batch 5000, poll 3000 | `max_connections` ≥ 30 | 10 000–18 000 filas/s | 6 sesiones |
| 5 | 50 / 600 / 1 200 rec/s | 6 tasks, batch 5000, poll 5000 | Perfil ingest | 15 000–30 000 filas/s | ~1 200; no llena el rango |

## Bitácora

```text
Escenario / source config (1-2-3):
Datagen tasks.max / max.interval / rec/s:
Sink tasks.max / batch.sizes / max.poll.records:
filas/s (n_tup_ins):
lag inicio → fin:
sesiones Connect / CPU % / IOPS %:
DLQ / restarts:
```

Al terminar: YAML de DES otra vez (`tasks.max: 1`, Datagen sin interval agresivo). Revertir DB del escenario 5. Para 10k–30k filas/s hace falta otro producer; el sink de 4–5 sirve para esa ronda.
