resource "confluent_schema" "${SUBJECT_NAME}-${VERSION}" {
  subject_name  = "${context}${SUBJECT_NAME}"
  format        = "${FORMAT}"
  schema        = file("${path.module}/${SUBPATH_SR}")
  recreate_on_update = true

  depends_on = [
    ${SUBJECT_MODE}
	  ${AVRO_PREVIOUS_VERSION}
  ]
}

output "${SUBJECT_NAME}-${VERSION}" {
  value = format("id: %s", confluent_schema.${SUBJECT_NAME}-${VERSION}.schema_identifier)
}

