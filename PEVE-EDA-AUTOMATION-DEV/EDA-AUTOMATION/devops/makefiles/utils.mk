validar_datos_entrada:
	./devops/scripts/validar_datos_entrada.sh $(ARG)
validar_pull_request:
	./devops/scripts/validar_pull_request.sh $(ARG)
validar_ruta_archivos_pr:
	./devops/scripts/validar_ruta_archivos_pr.sh $(ARG)

validar_estructura_topicos:
	./devops/scripts/validar_estructura_yaml.sh validar_topicos $(ARG)

obtener_verificar_merge_simulado:
	./devops/scripts/obtener_verificar_merge_simulado.sh $(ARG)
comments_pull_request:
	./devops/scripts/comments_pull_request.sh $(ARG)
approve_pull_request:
	./devops/scripts/approve_pull_request.sh $(ARG)
merge_pull_request:
	./devops/scripts/merge_pull_request.sh $(ARG)

eda_resource_terraform_plan:
	./devops/scripts/terraform_task.sh eda_resource_terraform_plan $(ARG)
eda_resource_terraform_apply:
	./devops/scripts/terraform_task.sh eda_resource_terraform_apply $(ARG)

eda_schemaregistry_terraform_plan:
	./devops/scripts/terraform_task.sh eda_schemaregistry_terraform_plan $(ARG)
eda_schemaregistry_terraform_apply:
	./devops/scripts/terraform_task.sh eda_schemaregistry_terraform_apply $(ARG)

validar_estructura_subjects:
	./devops/scripts/validar_estructura_yaml.sh validar_estructura_subjects $(ARG)

validar_esquema_version_1_0:
	./devops/scripts/validar_esquema_version_1_0.sh $(ARG)

validar_estructura_rbac:
	./devops/scripts/validar_estructura_yaml.sh validar_estructura_rbac $(ARG)

