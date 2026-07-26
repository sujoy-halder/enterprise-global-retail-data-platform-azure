# Deployment Runbook

## Environments

Use separate Terraform roots under `infra/terraform/environments/dev`, `stage`, and `prod`. Each root points at the same Azure platform module but uses different tfvars, tags, scaling values, CIDR ranges, and approval rules.

## State

Configure an Azure Storage remote backend before team deployment. Do not commit `*.tfvars`, state files, `.terraform/`, or generated plans.

Recommended backend values:

```hcl
resource_group_name  = "rg-retail-tfstate-prod"
storage_account_name = "retailtfstateprod"
container_name       = "tfstate"
key                  = "enterprise-retail/dev.tfstate"
```

On Windows, keep Terraform plugin paths short:

```powershell
$env:TF_DATA_DIR="$env:TEMP\retail-azure-tfdata-dev"
```

Set `allowed_ip_ranges` to real corporate, VPN, or private self-hosted runner egress CIDRs before planning. The examples use `203.0.113.10/32` as a documentation placeholder; leaving it unchanged will intentionally block normal operator access.

## Release Gate

Before any apply:

```powershell
.\scripts\validate-local.ps1
terraform -chdir=infra\terraform\environments\dev plan -var-file terraform.tfvars -out tfplan
```

Before promoting to production, verify:

- Terraform plan reviewed by platform/security owners.
- Azure Policy assignment and diagnostics are accepted by the landing zone.
- ACR images are scanned in your registry.
- AKS admission policies allow only signed or approved images.
- Key Vault secrets exist and workloads use managed identity where possible.
- Snowflake storage integration can list/read the Gold ADLS location.
- Databricks jobs complete against production-scale sample data.
- dbt tests pass in Snowflake.
- Informatica workflow connections resolve through the secure agent.

Use `requirements-dbt.txt` for dbt validation so the Snowflake adapter and Python dependencies are isolated from workstation-wide packages.

## Rollback

- Infrastructure: revert the Git commit and run Terraform plan/apply after review. Avoid manual cloud edits except for incident containment.
- AKS workload: redeploy the previous image digest using the deploy workflow input.
- dbt: redeploy the prior manifest and rerun tests on affected marts.
- Data: replay source events from Event Hubs retention or ADLS Bronze files into a dated recovery path.
