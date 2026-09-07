module "smt" {
  source = "../../modules/ccloud-connect-smt"

  environment_id = var.environment_id
  smt_file       = var.smt_file
  artifact_files = var.artifact_files
  cloud          = var.cloud
}
