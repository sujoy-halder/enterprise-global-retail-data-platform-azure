# Terraform

This Terraform creates the Azure platform plane:

- ADLS Gen2 Bronze/Silver/Gold/checkpoints/quarantine filesystems
- Event Hubs namespace and domain event hubs
- Data Factory with managed identity
- Azure Databricks workspace and access connector
- Synapse workspace and optional dedicated SQL pool
- AKS with Entra ID RBAC, OIDC issuer, workload identity, Azure Policy, and Log Analytics
- ACR, Key Vault, Application Insights, diagnostics, and role assignments
- Private endpoints and DNS zones when public network access is disabled

Run from an environment root:

```powershell
$env:TF_DATA_DIR="$env:TEMP\retail-azure-tfdata-dev"
terraform -chdir=infra\terraform\environments\dev init -backend=false
terraform -chdir=infra\terraform\environments\dev validate
terraform -chdir=infra\terraform\environments\dev plan -var-file terraform.tfvars
```

Use a real remote backend for shared environments. The backend is intentionally not hard-coded because backend storage is tenant-specific bootstrap infrastructure.
