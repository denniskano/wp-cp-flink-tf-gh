# Networking (Connect → Azure)

El Private Link de ingreso (VNet → Kafka) no se declara en el YAML del conector.

El de egreso (conector → Postgres, Blob, etc.) es de plataforma: módulo `ccloud-egress-privatelink`, todavía sin implementar. El sink sigue apuntando al FQDN (`peved02server.postgres.database.azure.com`); Confluent resuelve el DNS privado al PE.

En Flexible Server el sub-recurso es `postgresqlServer`. El PE se acepta a mano en Azure.
