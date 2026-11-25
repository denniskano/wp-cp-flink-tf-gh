# Deserialización, FAILED y DLQ (`error-handling.mode`)

Doc de Confluent Cloud Flink (Dedicated). No es un setting del YAML del DML ni de un `SET` de sesión.

Fuentes oficiales:

- [CREATE TABLE → `error-handling.mode`](https://docs.confluent.io/cloud/current/flink/reference/statements/create-table.html)
- [Configure a Dead Letter Queue](https://docs.confluent.io/cloud/current/flink/how-to-guides/configure-dlq.html)
- [Monitor and manage statements](https://docs.confluent.io/cloud/current/flink/operate-and-deploy/monitor-statements.html)
- Evolución de schema con jobs corriendo: [SCHEMA-EVOLUTION.md](SCHEMA-EVOLUTION.md)

## Resume de un statement `FAILED`

Un `INSERT INTO` en `FAILED` se puede **Resume** en la consola. Restaura el último checkpoint y **vuelve a leer el mismo offset**.

Si el fallo fue un record que no deserializa (schema) y ese record **sigue en el tópico**, Resume lo vuelve a `FAILED`. Un evento *bueno después* no salta el veneno.

Si el offset ya no existe (retention / compactación), Resume **puede** quedar `RUNNING` o fallar por offset out of range. No está garantizado.

`FAILED` no consume CFU. No es `STOPPED`: no hay savepoint ni `latest_offsets`.

## Dónde se configura (tabla origen)

Propiedad de la **tabla Flink que lees**, no del destino, no del `SELECT`, no de un `SET` de sesión. Todos los statements que leen esa tabla comparten el mismo modo y el mismo DLQ.

```sql
-- en el DDL de la tabla origen (CREATE o ALTER), no en el INSERT
ALTER TABLE mi_tabla_origen SET (
  'error-handling.mode' = 'log',
  'error-handling.log.target' = 'mi_tabla_origen_error_log'
);
```

En el YAML: va en el **DDL** de esa tabla (`CREATE TABLE … WITH (…)` o un `ALTER TABLE` con `apply: once`). No lo pongas en el SQL del DML.

Los tres valores: `fail` (default) | `ignore` | `log`.

## En qué momento actúa

Cuando Flink **lee** el tópico origen e **intenta deserializar** (Avro/JSON/Protobuf vs el schema de la tabla).

No ocurre al producir, en el broker, ni al hacer el `ALTER`. El record **sigue en el origen** en los tres modos: Kafka no lo borra. Flink solo decide si el statement muere, si tira el row o si copia el fallo a un DLQ, y avanza de offset.

Si el record **sí** deserializa y después revienta un `CAST` / UDF / el sink, **ningún modo aplica**: tumba el statement.

## Los tres modos

### `fail` (default)

Flink no puede deserializar → el statement pasa a `FAILED` y deja de leer.

**Cuándo usarlo:** un schema raro es incidente. Quieres que el pipeline pare, alguien mire Exceptions y decida. Es el default de Confluent: no pierdes datos “en silencio” hacia el destino (el INSERT no sigue), pero el job está caído y el lag crece.

**Resume:** si el veneno sigue en el tópico, Resume vuelve a `FAILED`. Para desatascar sin borrar Kafka: pasa la tabla a `log` o `ignore` y recién Resume.

### `ignore`

Flink intenta deserializar → falla → **descarta el row para el query** → **sigue al siguiente offset**. El statement queda `RUNNING`. El `INSERT` al destino **no recibe** ese evento.

Paso a paso:

1. El source lee el record del tópico origen (sigue en Kafka).
2. La deserialización falla (schema, poison pill, bytes que no calzan).
3. Flink **no** escribe a ningún DLQ. **No** mueve el mensaje. Solo no lo entrega al `SELECT`/`INSERT`.
4. Incrementa `io.confluent.flink/num_records_in_errors`.
5. Avanza el offset (checkpoint). El job no se cae.

No hay tópico extra. No hay rastro del payload más allá de la métrica (y lo que quede en el origen hasta que expire retention/compactación).

**Cuándo usarlo:**

- DES o pruebas donde ya sabes que hay basura y no te interesa el payload.
- Un poison pill puntual que aceptas **perder para Flink** y no quieres armar DLQ.

**Cuándo no:** CERT/PROD de un dominio de negocio. Un productor con schema malo se “traga” eventos: el destino queda incompleto, el statement sigue `RUNNING` y **nadie ve el dato** salvo que mires la métrica o el tópico crudo. Parece que el pipeline está sano.

```sql
ALTER TABLE mi_tabla_origen SET (
  'error-handling.mode' = 'ignore'
);
```

### `log`

Igual que `ignore` para el pipeline (el statement **no muere**, el INSERT no recibe el row malo), pero Flink **escribe una copia** a un tópico DLQ: código/mensaje de error, statement, y el record original (`topic`, `partition`, `offset`, `headers`, `key` y `value` en bytes).

Paso a paso:

1. Read + deserialización falla (igual que `ignore`).
2. Produce al DLQ (`error-handling.log.target`; default `error_log` si no lo pones).
3. Incrementa `num_records_in_errors`.
4. Avanza offset. Statement `RUNNING`.

No es un *move*. Origen intacto; DLQ = auditoría / reproceso.

**Cuándo usarlo:** DES, CERT y PROD cuando quieres que un poison pill **no tumbe** el job **y** poder inspeccionar o reprocesar (`SELECT * FROM mi_tabla_origen_error_log`). Es el modo operativo si el origen no es 100 % limpio y el pipeline tiene que seguir.

**Costo:** tópico DLQ + subjects en Schema Registry + un produce extra **solo en error**. Records buenos: casi el mismo camino.

Si Flink no puede crear el DLQ, el `ALTER`/`CREATE` no falla. Falla **después**, en el primer error de deserialización (el job se cae como si fuera `fail`). Configurar el DLQ pide `ResourceOwner` sobre el tópico origen; Confluent recomienda un SA de plataforma para ese `ALTER`.

```sql
ALTER TABLE mi_tabla_origen SET (
  'error-handling.mode' = 'log',
  'error-handling.log.target' = 'mi_tabla_origen_error_log'
);
```

## Comparación

| | `fail` | `ignore` | `log` |
|---|---|---|---|
| Statement | `FAILED` | sigue `RUNNING` | sigue `RUNNING` |
| Record en el origen | sigue | sigue | sigue |
| Llega al destino del INSERT | no | no | no |
| Dónde lo ves tú | Exceptions del job | métrica (y el tópico crudo) | tópico DLQ |
| Tópico extra | no | no | sí (DLQ) |
| Riesgo | pipeline parado, lag | pérdida silenciosa | I/O extra en errores; DLQ que hay que mirar |
| Uso típico | default; parar ante schema raro | DES / basura conocida | DES–PROD: seguir + auditar |

## ¿Altera el tópico origen?

No: ni datos, ni particiones, ni retention, ni schema. Solo una propiedad del catálogo Flink. `log` puede crear **otro** tópico (el DLQ).

## Performance

Records buenos: casi igual en los tres modos. Records malos:

- `fail`: el job muere (0 CFU después).
- `ignore`: un skip; barato.
- `log`: produce extra al DLQ. Pocos poison pills no se notan; un tópico lleno de basura escribe a dos lados y el statement **sigue cobrando CFU**.

## Operar un FAILED por schema

1. Confirma en Exceptions que es **deserialización** (no CAST/UDF/sink).
2. Elige modo: `log` si quieres el payload; `ignore` si aceptas tirarlo.
3. `ALTER` la tabla origen.
4. Resume. Con `log` el veneno va al DLQ; con `ignore` se descarta. El statement puede volver a `RUNNING`.
5. Si usaste `log`: `SELECT * FROM mi_tabla_origen_error_log;`

Métrica: `io.confluent.flink/num_records_in_errors` (cuenta el fallo de deserialización en **los tres** modos; el modo solo decide qué hacer con el record).
