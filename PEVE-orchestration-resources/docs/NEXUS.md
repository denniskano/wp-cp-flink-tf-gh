# Nexus endpoint (YAML)

Opcional. Un archivo por endpoint en `{CODAPP}/{dev|cert|prod}/nexus/*.yaml`.

Nexus deja que un namespace **llame** workers de **otro** namespace del **mismo** env (mismo apply). Los dos namespaces tienen que existir en `namespaces/`.

Plantilla: [`TEMPLATE/nexus.yaml`](../TEMPLATE/nexus.yaml). Campos del namespace: [NAMESPACE.md](NAMESPACE.md).

El nombre del archivo no importa; Temporal usa `name`.

## Campos

| Campo | Obligatorio | Default | Valores | Qué es |
|---|---|---|---|---|
| `name` | Sí | — | Unique. Ej. `{codapp}-{suffix}-nexus` | Nombre del endpoint Nexus. |
| `description` | No | vacío | String (puede ser multilinea) | Texto en Temporal. |
| `target_namespace` | Sí | — | `name` de un YAML de `namespaces/` **de este env** | Dónde corren los workers que atienden Nexus. |
| `task_queue` | Sí | — | String. Tiene que coincidir con el worker | Task queue del target. |
| `allowed_callers` | Sí | — | Lista de `name` de namespaces **de este env**, ≥ 1 | Quién puede invocar el endpoint. |

El CI falla si `target_namespace` o un caller no está en este env. No se puede apuntar a un namespace de otro CODAPP ni de otro `dev|cert|prod`.

```yaml
name: peve-pagos-nexus
description: |
  pagos invoca workers en peve-dev.
target_namespace: peve-dev
task_queue: peve-dev-tq
allowed_callers:
  - peve-dev-pagos
```
