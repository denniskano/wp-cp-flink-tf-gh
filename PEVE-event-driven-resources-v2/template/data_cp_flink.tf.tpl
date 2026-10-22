data "confluent_flink_compute_pool" "cp_${COMPUTE_POOL}" {
  display_name = "${COMPUTE_POOL}"
  environment {
    id = "${ENVIRONMENT_ID}"
  }
}
