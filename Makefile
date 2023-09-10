default:
	@echo "Creates a Terraform system from a template."
	@echo "The following commands are available:"
	@echo " - plan               : runs terraform plan for an environment"
	@echo " - apply              : runs terraform apply for an environment"
	@echo " - destroy            : will delete the entire project's infrastructure"

record-accounts:
	@cd ./bootstrap/organization; terraform output -json account_ids | jq > ../../accounts.json