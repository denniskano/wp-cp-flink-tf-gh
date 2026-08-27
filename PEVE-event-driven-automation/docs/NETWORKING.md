# Networking (Connect → Azure)

Ingress Private Link (VNet → Kafka) no cambia el YAML del conector.

Egress Private Link (conector → Postgres, Blob, …) es **plataforma**: módulo `ccloud-egress-privatelink` (esqueleto). El sink sigue usando el FQDN (`peved02server.postgres.database.azure.com`); el DNS privado lo resuelve Confluent al PE.

Sub-recurso Flexible Server: `postgresqlServer`. Aceptar el PE a mano en Azure.
