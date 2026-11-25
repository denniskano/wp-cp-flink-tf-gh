module "temporal" {
  source = "../../modules/temporal-cloud"

  namespaces_dir = var.namespaces_dir
  nexus_dir      = var.nexus_dir
}
