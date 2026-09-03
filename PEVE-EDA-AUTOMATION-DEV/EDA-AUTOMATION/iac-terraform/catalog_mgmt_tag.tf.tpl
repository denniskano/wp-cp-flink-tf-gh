resource "confluent_tag" "TAG-${TAG_NAME}" {
  name = "${TAG_NAME}"
  description = "${TAG_DESCRIPTION}"
}
