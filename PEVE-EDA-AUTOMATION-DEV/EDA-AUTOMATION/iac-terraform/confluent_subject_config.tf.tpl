resource "confluent_subject_config" "${SUBJECT_NAME}-config" {
  subject_name        = "${context}${SUBJECT_NAME}"
  compatibility_level = "${COMPATIBILITY_MODE}"
}

