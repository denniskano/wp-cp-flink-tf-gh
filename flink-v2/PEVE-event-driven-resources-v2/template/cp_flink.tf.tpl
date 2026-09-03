#INI CP: cp_flink_${DISPLAY_NAME}
resource "confluent_flink_compute_pool" "cp_flink_${DISPLAY_NAME}" {
  display_name = "${DISPLAY_NAME}"
  environment  { id = "${ENVIRONMENT_ID}" }
  cloud   = "${CLOUD}"
  region  = "${REGION}"
  max_cfu = "${MAX_CFU}"
}
#FIN CP
