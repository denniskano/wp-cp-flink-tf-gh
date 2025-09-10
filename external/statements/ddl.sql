-- DDL: Crear tabla simple
CREATE TABLE `default`.`denniskano-clu`.demo_table (
  id STRING,
  name STRING,
  created_at TIMESTAMP(3)
) WITH (
  'connector' = 'confluent'
);
