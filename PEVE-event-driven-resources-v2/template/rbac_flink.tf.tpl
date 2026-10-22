resource "confluent_role_binding" "rbac_${PRINCIPAL}_${RESOURCE_TYPE}_${RESOURCE_NAME0}_${PATTERN_TYPE}_${OPERATION}" {
  principal   = "User:${data.confluent_service_account.sa_${PRINCIPAL}.id}"
  role_name   = "${OPERATION}"
  
  crn_pattern = "crn://confluent.cloud/organization=${ORGANIZATION_ID}/environment=${ENVIRONMENT_ID}${RESOURCE_CRN}${RESOURCE_TYPE}=${RESOURCE_NAME}${PATTERN_VALUE}"

  lifecycle {
    prevent_destroy = true
  }

}

output "${PRINCIPAL}_${RESOURCE_TYPE}_${RESOURCE_NAME0}_${PATTERN_TYPE}_${OPERATION}" {
  value = "RBAC"
}
