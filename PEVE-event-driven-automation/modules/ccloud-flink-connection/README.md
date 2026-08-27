# ccloud-flink-connection

Esqueleto. Conexiones externas de Flink (`confluent_flink_connection`).

Tipos del provider: `OPENAI`, `AZUREML`, `AZUREOPENAI`, `BEDROCK`, `SAGEMAKER`, `GOOGLEAI`, `VERTEXAI`, `MONGODB`, `PINECONE`, `ELASTIC`, `COUCHBASE`.

Credenciales (api_key, service key, …) desde Vault vía el workflow; nunca en YAML de resources ni en este repo.

Compartido a nivel environment. Los statements usan el **nombre** de la connection en SQL (`CREATE TABLE … WITH ('azureopenai.connection' = '…')`); no recrear la connection por pipeline.
