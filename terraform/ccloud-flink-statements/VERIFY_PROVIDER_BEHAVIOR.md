# Verificación del Comportamiento del Proveedor Confluent

## ⚠️ IMPORTANTE: Comportamiento del Proveedor

**El comportamiento de actualización vs. destroy/recreate depende completamente del proveedor de Confluent, NO de Terraform.**

Terraform solo envía la solicitud de actualización al proveedor. Es el proveedor quien decide si:
- ✅ Actualiza el statement in-place (preservando offsets)
- ❌ Destruye y recrea el statement (perdiendo offsets)

## Cómo Verificar el Comportamiento

### Método 1: Usar `terraform plan`

1. Haz un cambio pequeño en el SQL de un statement (ej: agregar un comentario)
2. Ejecuta:
   ```bash
   terraform plan -refresh=false
   ```
3. Revisa la salida:
   - Si dice `~ update in-place` → El proveedor actualiza sin recrear ✅
   - Si dice `-/+ destroy and then create replacement` → El proveedor destruye y recrea ❌

### Método 2: Revisar el Código Fuente del Proveedor

1. Ve al repositorio: https://github.com/confluentinc/terraform-provider-confluent
2. Busca el archivo del recurso `confluent_flink_statement`
3. Revisa el método `Update`:
   - Si tiene `ForceNew: true` en el atributo `statement` → Destruye y recrea
   - Si solo actualiza el atributo → Actualiza in-place

### Método 3: Consultar la Documentación

1. Revisa: https://registry.terraform.io/providers/confluentinc/confluent/latest/docs/resources/confluent_flink_statement
2. Busca qué atributos son "updateable" vs "force_new"

## Comportamiento Observado

Basado en tu experiencia previa:
- ❌ **Observado**: El proveedor destruye y recrea cuando cambia el SQL
- ⚠️ **Implicación**: Los offsets se pierden al cambiar el statement

## Recomendaciones

1. **Antes de cambiar un statement en producción**:
   - Prueba primero en un ambiente de desarrollo
   - Ejecuta `terraform plan` para ver qué operación propone
   - Si propone destroy/recreate, considera detener el statement manualmente primero

2. **Si el proveedor destruye y recrea**:
   - Los offsets se perderán
   - Necesitarás una estrategia de migración de offsets
   - O aceptar que se reprocesarán todos los eventos desde el inicio

3. **Alternativa**:
   - Usar la API de Confluent directamente para actualizar statements
   - O usar el CLI de Confluent para actualizar sin pasar por Terraform

## Nota sobre la Implementación Actual

La implementación actual con `for_each` usando el nombre del archivo como clave:
- ✅ Garantiza que Terraform identifica el mismo recurso
- ✅ Garantiza que el `statement_name` no cambia (por la regla)
- ⚠️ **NO garantiza** que el proveedor actualice en lugar de destruir/recrear

El comportamiento final depende del proveedor de Confluent.
