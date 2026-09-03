# ccloud-connectors

Connectors full-managed. Lee `connectors_dir` y `security_dir` (los llena el workflow desde `./externo`).

El `for_each` es el nombre del yaml sin extensión. Si borrás un archivo, Terraform tira solo ese connector.

El SMT custom no se sube acá. En el yaml va `transforms.*.custom.smt.artifact.id` (el `ca-…` lo tendría que crear `connect-plugins`).
