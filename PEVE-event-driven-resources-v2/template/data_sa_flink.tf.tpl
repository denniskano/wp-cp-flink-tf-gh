data "confluent_service_account" "sa_${PRINCIPAL}" {
  display_name = "${PRINCIPAL}"
}

