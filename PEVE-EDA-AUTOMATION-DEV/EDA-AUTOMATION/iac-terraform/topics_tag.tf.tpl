resource "confluent_tag_binding" "TAGGING-${TF_TOPIC_NAME}-${TAG_NAME}" {
  tag_name = "${TAG_NAME}"
  entity_name = "${var.cluster_id}:${TOPIC_NAME}"
  entity_type = "kafka_topic"

  lifecycle {
    ignore_changes = [
	    entity_name,
    ]
  }

}

