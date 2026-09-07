# ccloud-connectors

Connectors full-managed. Lee `connectors_dir` y `security_dir` (los llena el workflow desde `./externo`).

El `for_each` es el nombre del yaml sin extensión. Si borras un archivo, Terraform destruye solo ese connector.

`vault.secrets` y `config_sensitive` van a `config_sensitive` del provider (nunca a `config_nonsensitive`). El workflow inyecta los valores en `TF_VAR_connector_secrets`.

El SMT custom no se sube aquí. En el yaml va `transforms.*.custom.smt.artifact.id` (el `ca-…` lo crea `connect-plugins` desde `{CODAPP}/{env}/smt.yaml`).
