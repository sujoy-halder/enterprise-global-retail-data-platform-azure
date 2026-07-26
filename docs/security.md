# Security Controls

## Identity

- Azure resources use managed identities and Azure RBAC where supported.
- AKS uses Microsoft Entra ID, Azure RBAC, OIDC issuer, and workload identity.
- GitHub Actions deployment is designed for OIDC federation, not long-lived client secrets.

## Secrets

- Key Vault has purge protection enabled and RBAC authorization.
- `.env`, `*.tfvars`, state files, and generated plans are excluded from Git.
- Snowflake and Informatica credentials are external prerequisites and are not stored in this repo.

## Network

- The Terraform module supports private public-network-disabled deployment with private endpoint subnets.
- Storage accounts deny shared key access and require TLS 1.2 or newer.
- AKS uses Azure CNI and network policy.

## Containers

- Docker images run as non-root users.
- Kubernetes workloads use read-only root filesystems, dropped Linux capabilities, and seccomp runtime default.
- Probes are configured for health and readiness.

## Monitoring

- Log Analytics receives AKS, Data Factory, Databricks, Event Hubs, Storage, Key Vault, ACR, and Synapse diagnostics.
- Runtime endpoints expose health/readiness and Prometheus-style counters.
