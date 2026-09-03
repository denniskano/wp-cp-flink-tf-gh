.PHONY: validate-connect validate-flink-pools validate-flink-stmts plan-connect plan-flink-pools plan-flink-stmts

validate-connect:
	cd "$(REPO_ROOT)/stacks/kafka-connect" && terraform init -backend=false -input=false && terraform validate

validate-flink-pools:
	cd "$(REPO_ROOT)/stacks/flink-compute-pool" && terraform init -backend=false -input=false && terraform validate

validate-flink-stmts:
	cd "$(REPO_ROOT)/stacks/flink-statements" && terraform init -backend=false -input=false && terraform validate

plan-connect:
	cd "$(REPO_ROOT)" && ./scripts/local/tf.sh kafka-connect plan

plan-flink-pools:
	cd "$(REPO_ROOT)" && ./scripts/local/tf.sh flink-compute-pool plan

plan-flink-stmts:
	cd "$(REPO_ROOT)" && ./scripts/local/tf.sh flink-statements plan
