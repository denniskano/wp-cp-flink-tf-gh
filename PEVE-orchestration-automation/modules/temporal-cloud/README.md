# temporal-cloud

`yamldecode` de `namespaces/*.yaml` + `nexus/*.yaml`.

Recursos: `temporalcloud_namespace`, `connectivity_rule`, `namespace_tags`, `namespace_search_attribute`, `service_account`, `apikey`, `user`, `nexus_endpoint`.

YAML `labels` (alias `tags`) → `temporalcloud_namespace_tags`. Máx. 10 pares; keys/values 1-63, solo `a-z 0-9 . _ - @`. Si ambos existen, `tags` pisa.

Auth: `api_key_auth` únicamente. `regions` es ForceNew.
