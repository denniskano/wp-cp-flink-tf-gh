# Stack: connect-plugins

Esqueleto. Subida de Custom SMT a nivel environment (no por use-case).

Enlazar `modules/ccloud-connect-smt` (`confluent_connect_artifact`, id `ca-…`).

Apply **antes** que `kafka-connect`. El YAML del conector referencia el artifact id; este stack no crea el connector.

Binarios (JAR/ZIP) en resources o artifact store; `artifact_file` lo pasa el workflow.
