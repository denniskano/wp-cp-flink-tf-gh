resource "confluent_subject_mode" "${SUBJECT_NAME}-mode" {
  subject_name  = "${context}${SUBJECT_NAME}"
  mode          = "READWRITE"
}

output "${SUBJECT_NAME}" {
  value = {
    mode = confluent_subject_mode.${SUBJECT_NAME}-mode.mode
    ${OUTPUT_COMPATIBILITY_MODE}
  }
}

