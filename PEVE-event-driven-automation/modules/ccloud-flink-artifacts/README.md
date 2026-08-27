# ccloud-flink-artifacts

Esqueleto. Sube UDFs de Flink a Confluent Cloud (`confluent_flink_artifact`).

JAR o Python (`content_format`: `JAR` | ZIP Python). Cloud/región = los del compute pool (PEVE: `AZURE` / `eastus2`).

El binario **no** vive en este repo: el workflow descarga el artefacto (resources o artifact store) y pasa `artifact_file`. El statement referencia el artifact id (`lfa-…`); no lo sube `flink-statements`.

Unidad: plataforma / CODAPP (compartido entre pipelines). No un JAR por statement salvo UDF privada.
