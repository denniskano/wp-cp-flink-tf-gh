# temporal-cloud

`yamldecode` de `namespaces/*.yaml` + `nexus/*.yaml`.

Recursos: `temporalcloud_namespace`, `connectivity_rule`, `namespace_tags`, `namespace_search_attribute`, `service_account`, `apikey`, `user`, `nexus_endpoint`.

YAML `labels` (alias `tags`) → `temporalcloud_namespace_tags`. Máx. 10 pares; keys/values 1-63, solo `a-z 0-9 . _ - @`. Si ambos existen, `tags` pisa.

Auth: `api_key_auth` (default `true`) o mTLS (`false` + `accepted_client_ca_vault`; el CD baja el PEM de Vault). `connectivity` es opcional (omitir = internet; `private` + ID = PE). `regions` es ForceNew. Sin rules, `connectivity_rule_ids` se omite (no `[]`).
