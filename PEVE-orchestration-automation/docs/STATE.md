# State

Backend Azure RM. El workflow manda `storage_account_name`, `container_name` y `key` en el `init`.

| Stack | Container DES | Key |
|---|---|---|
| temporal-cloud | tf-temporal-dev | `dev/{CODAPP}/temporal-cloud/tf-temporal.tfstate` |

CERT/PROD: `tf-temporal-cert` / `tf-temporal-prod` y prefijo `cert/` / `prod/` en la key.

No reutilizar keys de Flink ni Connect.
