resource "confluent_kafka_topic" "${TF_TOPIC_NAME}" {
  topic_name        = "${TOPIC_NAME}"
  partitions_count  = ${TOPIC_PARTITIONS}

  config            = {
    ${TOPIC_CONFIG}
  }

  lifecycle {
    prevent_destroy = true
  }

}


output "${TF_TOPIC_NAME}" {
  value = format("partitions_count: %d", confluent_kafka_topic.${TF_TOPIC_NAME}.partitions_count)

#  value = {
#    partitions_count  = confluent_kafka_topic.${TF_TOPIC_NAME}.partitions_count
#    config = confluent_kafka_topic.${TF_TOPIC_NAME}.config
#  }
}

