module "temporal" {
  source = "../../modules/temporal-cloud"

  namespaces_dir = var.namespaces_dir
  nexus_dir      = var.nexus_dir
  mtls_ca_dir    = var.mtls_ca_dir
}
