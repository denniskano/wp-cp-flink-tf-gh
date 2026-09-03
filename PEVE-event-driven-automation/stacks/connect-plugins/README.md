# connect-plugins

Vacío. Acá iría la subida de SMT (`confluent_connect_artifact`, id `ca-…`) a nivel environment.

El connector no sube el JAR: en el yaml solo pone el artifact id. Si se implementa, hay que aplicarlo antes que `kafka-connect`. El binario lo baja el workflow (`artifact_file`).
