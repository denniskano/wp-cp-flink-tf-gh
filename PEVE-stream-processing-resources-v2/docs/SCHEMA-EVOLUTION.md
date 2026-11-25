# Evolucionar el schema de un tópico con statements Flink corriendo

Confluent Cloud Flink (Dedicated) + Schema Registry. El SQL del statement es inmutable. El job **no** “se entera” de un schema nuevo con Resume ni con un apply del mismo `statement-name`.

Oficial:

- [Schema and Statement Evolution](https://docs.confluent.io/cloud/current/flink/concepts/schema-statement-evolution.html)
- [Carry-over offsets](https://docs.confluent.io/cloud/current/flink/operate-and-deploy/carry-over-offsets.html)
- Deserialización / `FAILED` / DLQ: [ERROR-HANDLING.md](ERROR-HANDLING.md)

## Qué pineá Flink

Al **crear** el statement toma un **snapshot**:

- *Read schema* = **última versión** del subject del tópico origen **en ese instante**.
- Opciones de la tabla origen (`error-handling.mode`, watermark, `scan.startup.mode`, …).
- Funciones UDF referenciadas.

Eso **no se actualiza** después:

- Resume / `stopped: false` reusa el snapshot **y** el checkpoint (mismos offsets).
- `ALTER TABLE` en el catálogo **no** se propaga a statements ya creados.
- Borrar un campo o agregar uno en SR **no** cambia el job viejo. Si el cambio es compatible, el viejo **ignora** campos nuevos; no los manda al sink. Si no es compatible para *ese* snapshot, el job pasa a `FAILED`.

Terraform `stopped` no es el status de Confluent (`RUNNING` / `FAILED`). Un apply con `stopped: "false"` cuando el state ya decía false **no** hace Resume.

## Cómo saber qué version usa un statement

1. Consola → statement → **Created**. En SR, subject `{topic}-value` (y `-key` si aplica): la versión que era `latest` **en esa fecha**.
2. `SHOW CREATE TABLE` / `DESCRIBE` es el catálogo **hoy**. No es el snapshot del job.
3. Record Avro Confluent: byte `0x00` + **schema id** (4 bytes) → SR te da la versión **del evento**. Si es más nueva que el snapshot, un job viejo en `BACKWARD` suele fallar al deserializar.
4. Exceptions: `Failed to deserialize Avro record` (u equivalente JSON/Protobuf).

## Compatibilidad en SR

Default de Confluent Cloud: **`BACKWARD`**.

| Modo | Qué garantiza | Orden |
|---|---|---|
| `BACKWARD` | Un **consumidor nuevo** lee datos **viejos** (quitar campos, agregar **opcionales**). Solo última vs anterior, no toda la historia. | **Flink nuevo primero**, productor después |
| `BACKWARD_TRANSITIVE` | Igual, contra **todas** las versiones anteriores | Igual: consumidores primero |
| `FULL` / `FULL_TRANSITIVE` | Add/remove de opcionales; el orden productor/consumidor no rompe la deserialización | Igual hay que **crear** Flink nuevo si quieres **usar** campos nuevos |
| `FORWARD` / `FORWARD_TRANSITIVE` | Productor primero. Un consumidor **viejo** puede leer datos **nuevos**. El Flink nuevo puede **no** leer historia (campo required sin default) | Peligroso con Flink: el create suele leer `earliest` |

Flink es **consumidor** del origen (y productor del sink). Con `BACKWARD`, **nunca** publiques el schema nuevo en el tópico origen **antes** de tener un statement Flink `RUNNING` que lo haya pineado.

`FULL` evita que el job viejo se caiga por un campo opcional, pero ese job **no proyecta** el campo nuevo. Para el sink con la columna nueva hace falta statement nuevo igual.

---

## Procedimiento correcto (statements en `RUNNING`)

Válido para un `INSERT INTO` (stateless: filtro / proyección / `CASE`, sin agregados, ventanas, `LAG`, MATCH, upsert sink). El carry-over de offsets **solo** aplica a esos.

### 0. Antes de tocar SR

- Anota `statement-name` del DML que está **Running** (no el nombre del archivo YAML).
- Confirma compatibilidad del subject (`BACKWARD` o, mejor para Flink, `FULL` / `FULL_TRANSITIVE`).
- El SQL **no** se edita in-place. YAML **nuevo**, otro `statement-name`.

### 1. Registrar el schema nuevo en SR (aún no produzcas con él)

Cambio típico `BACKWARD` / `FULL`: campo opcional con default, o borrar un campo que los consumidores nuevos ya no leen.

No despliegues el productor todavía.

### 2. Catálogo Flink (DDL)

Si la tabla Flink origen debe exponer columnas nuevas:

- DDL `ALTER TABLE` / `CREATE` en `statement/ddl/` (`apply: once` si es ALTER).
- Apply de DDL **antes** del DML nuevo.

El job **viejo no usa** este ALTER. Lo usa el **create** del DML nuevo.

Opcional: `'error-handling.mode' = 'log'` en la **tabla origen** (DDL) **antes** del DML nuevo, para que el snapshot del job nuevo ya traiga DLQ. Ver [ERROR-HANDLING.md](ERROR-HANDLING.md).

### 3. YAML del DML nuevo

- Copia el DML. **Otro** `statement-name` (ej. `insert-…-v2`).
- El SQL puede ser el **mismo** (solo refrescar snapshot) o incluir campos nuevos.
- Carry-over: el valor es el `statement-name` que está **Running**:

```yaml
properties:
  sql.tables.initial-offset-from: "insert-azc-pfmt-product"   # el Running, no el FAILED
```

No pongas `'scan.startup.mode'` en el SQL: pisa el carry-over.

### 4. Apply 1 — crear la nueva, la vieja sigue Running

- Vieja: `stopped: "false"` (no la toques).
- Nueva: `stopped: "false"`.
- Plan: **solo create** de la nueva.

La nueva queda `PENDING` (hasta 6 h) esperando el savepoint. Terraform da el create por bueno en segundos. En la lista del pool **puede no verse**. Comprueba con `terraform plan` (refresh) o GET del statement.

**No** pares la vieja en este apply.

### 5. Apply 2 — stop limpio de la anterior

- Solo la **vieja**: `stopped: "true"`.
- Plan: update in-place `stopped false → true`.
- CCloud saca savepoint. La nueva pasa a `RUNNING` y **continúa los offsets** (sin hueco).

Recién ahora el consumidor Flink usa el schema nuevo.

### 6. Productores

Cuando la **v2** esté `RUNNING` (Messages Behind bajo): despliega el productor / la app que escribe el schema nuevo al tópico origen.

### 7. Limpieza

- Vieja `STOPPED` + `apply: ignore` (si no, a los ~30 días CCloud borra el statement terminal y un apply `managed` lo **recrea** desde offset 0).
- No destruyas la tabla ni el tópico.

---

## Qué no hacer

| Acción | Resultado |
|---|---|
| Publicar schema nuevo y dejar el Flink viejo | Con `BACKWARD`, el viejo deserializa mal → `FAILED` |
| Resume del mismo statement para “tomar el schema” | Sigue el snapshot y el checkpoint viejos |
| Apply con el mismo `statement-name` y el mismo SQL | Terraform no recrea; no hay snapshot nuevo |
| `stopped: false` en Terraform sobre un `FAILED` (ya era false) | Plan vacío o “OK”; el dashboard sigue `FAILED` |
| `initial-offset-from` apuntando a un `FAILED` | La nueva se queda `PENDING` (timeout 6 h) y falla. FAILED no tiene savepoint |
| `stopped: true` sobre un `FAILED` | Terraform no manda stop; no hay change |
| Cambiar el SQL in-place (mismo `statement-name`) | Destroy+create; se pierden offsets |
| Carry-over + `'scan.startup.mode'` en el SQL | El hint gana; no hay continuidad de offsets |

---

## El job ya está `FAILED` (schema publicado antes que Flink)

Es el caso `BACKWARD` al revés: el productor ya escribe la versión nueva; el snapshot es el anterior. Resume vuelve a leer un evento nuevo y se cae otra vez.

Carry-over **desde ese FAILED no sirve**. Hay que **soltar** el offset del anterior.

### Procedimiento de recuperación (SQL igual)

1. SR: confirma latest = el schema que escribe el productor, modo `BACKWARD` (o el que sea).
2. DDL de catálogo al día (paso 2 de arriba). `error-handling.mode` = `log` si quieres red de seguridad.
3. DML:
   - **Opción A (mismo `statement-name`):** Delete en consola (o destroy de ese resource) y apply **sin** `sql.tables.initial-offset-from`. El INSERT no se toca. Instancia nueva → snapshot latest.
   - **Opción B (recomendado):** YAML con **otro** `statement-name`, mismo SQL, **sin** `initial-offset-from`. Apply. El FAILED se deja; luego `apply: ignore`.
4. Arranque: el de la tabla origen, casi siempre `earliest` de lo que quede en retention. Hueco desde que falló hasta el log start. Duplicados posibles en el sink si reprocesas el último día.
5. Para no reprocesar (hueco consciente) haría falta hint `latest-offset` en el SQL: **eso sí modifica el statement**.
6. Consola: nuevo en `RUNNING`. El FAILED no se Resume “para el schema”.

`initial-offset-from` vive en el YAML/`properties`, **no** en el `INSERT`. Si Terraform lo reinyecta al recreate, el job **sigue** atado al anterior: hay que quitar esa property **en este apply**.

### Si todavía está `RUNNING` y aún no publicas el productor

No borres. Usa el procedimiento de la sección anterior (v2 + carry-over + stop). Ese es el camino sin pérdida de offsets.

---

## Checklist rápido

**Evolución planificada (`RUNNING`):**

1. Schema nuevo en SR (aún sin producir).
2. DDL catálogo si aplica.
3. DML `…-v2` + `initial-offset-from` = name **Running**.
4. Apply create v2.
5. Apply `stopped: true` en v1.
6. v2 `RUNNING` → productores.
7. v1 `apply: ignore`.

**Ya se publicó el schema y Flink está `FAILED`:**

1. No Resume / no carry-over.
2. Quitar `initial-offset-from` para este corte.
3. Recreate (mismo SQL, instancia nueva) o `…-v2` sin carry-over.
4. Aceptar hueco o duplicados según `earliest`/`latest`.
5. Productores pueden seguir; el snapshot nuevo ya es el latest.

---

## Relación con `error-handling.mode`

`log` / `ignore` **no evolucionan** el schema. Solo evitan que un poison pill de **deserialización** tumbe el job **nuevo** (van en el snapshot del create). Un job viejo no toma un `ALTER` de modo posterior. Detalle: [ERROR-HANDLING.md](ERROR-HANDLING.md).
