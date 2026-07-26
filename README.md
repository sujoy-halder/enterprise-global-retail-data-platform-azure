<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:0078D4,35:00A6A6,70:7C3AED,100:FF694B&height=190&section=header&text=Enterprise%20Global%20Retail%20Data%20Platform&fontSize=38&fontColor=ffffff&animation=fadeIn&fontAlignY=38&desc=Azure%20Lakehouse%20%7C%20Databricks%20%7C%20Snowflake%20%7C%20dbt%20%7C%20AKS%20%7C%20Terraform&descSize=16&descAlignY=60" />

### Cloud-native multinational retail data platform for POS, e-commerce, inventory, supply chain, customer behavior, IoT warehouse events, and executive analytics.

![Author](https://img.shields.io/badge/Author-Sujoy%20Halder-0A66C2?style=for-the-badge)
![Azure](https://img.shields.io/badge/Azure-Cloud%20Platform-0078D4?style=for-the-badge\&logo=microsoftazure\&logoColor=white)
![ADLS](https://img.shields.io/badge/ADLS%20Gen2-Medallion%20Lakehouse-00A6A6?style=for-the-badge)
![Event Hubs](https://img.shields.io/badge/Event%20Hubs-Real--Time%20Streaming-2563EB?style=for-the-badge)
![ADF](https://img.shields.io/badge/Azure%20Data%20Factory-Orchestration-7C3AED?style=for-the-badge)
![Databricks](https://img.shields.io/badge/Databricks-Delta%20Lake-FF3621?style=for-the-badge\&logo=databricks\&logoColor=white)
![Snowflake](https://img.shields.io/badge/Snowflake-Warehouse-29B5E8?style=for-the-badge\&logo=snowflake\&logoColor=white)
![dbt](https://img.shields.io/badge/dbt-Retail%20Marts-FF694B?style=for-the-badge\&logo=dbt\&logoColor=white)
![AKS](https://img.shields.io/badge/AKS-Microservices-326CE5?style=for-the-badge\&logo=kubernetes\&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-IaC-844FBA?style=for-the-badge\&logo=terraform\&logoColor=white)

</div>

---

## Project Overview

**Enterprise Global Retail Data Platform On Azure** is a production-style data engineering platform for global retail analytics. It processes POS transactions, online orders, inventory, supplier feeds, warehouse events, delivery updates, product catalog data, marketing activity, customer behavior, and IoT warehouse sensor events.

The project demonstrates a complete Azure retail lakehouse architecture using **Event Hubs, Azure Data Factory, ADLS Gen2, Databricks Delta Lake, Synapse, Snowflake, dbt, AKS, Terraform, GitHub Actions, Key Vault, Log Analytics, and Informatica handoff assets**.

---

## Retail Use Cases

| Domain       | Analytics Supported                                  |
| ------------ | ---------------------------------------------------- |
| Sales        | POS transactions, online orders, store revenue       |
| Inventory    | Stock movement, product availability, replenishment  |
| Customer     | Behavior tracking, segmentation, customer 360        |
| Supply Chain | Supplier feeds, delivery tracking, warehouse events  |
| Marketing    | Campaign performance and conversion analytics        |
| Operations   | Power BI dashboards, Snowflake marts, executive KPIs |

---

## Architecture

```mermaid
flowchart TD
    ERP["ERP"] --> EH["Azure Event Hubs"]
    CRM["CRM"] --> EH
    POS["POS Transactions"] --> EH
    WEB["Online Orders + Behavior"] --> EH
    IOT["IoT Warehouse Sensors"] --> EH
    SUP["Supplier APIs"] --> EH

    EH --> ADF["Azure Data Factory"]
    ADF --> BRONZE["ADLS Gen2 Bronze"]
    BRONZE --> DBX["Databricks Delta Lake"]
    DBX --> SILVER["ADLS Gen2 Silver"]
    DBX --> GOLD["ADLS Gen2 Gold"]

    GOLD --> SYN["Synapse Analytics"]
    GOLD --> SNOW["Snowflake Warehouse"]
    SNOW --> DBT["dbt Retail Marts"]
    DBT --> BI["Power BI Semantic Models"]

    AKS["AKS Microservices"] --> EH
    ACR["Azure Container Registry"] --> AKS
    KV["Azure Key Vault"] --> AKS
    MON["Azure Monitor + Log Analytics"] --> AKS
    GHA["GitHub Actions"] -. CI/CD .-> AKS
    TF["Terraform"] -. provisions .-> EH

    classDef source fill:#DBEAFE,stroke:#0078D4,color:#111827;
    classDef azure fill:#E0F2FE,stroke:#0284C7,color:#111827;
    classDef lake fill:#DCFCE7,stroke:#16A34A,color:#111827;
    classDef warehouse fill:#EDE9FE,stroke:#7C3AED,color:#111827;
    classDef security fill:#FEF3C7,stroke:#D97706,color:#111827;
    classDef devops fill:#FEE2E2,stroke:#DC2626,color:#111827;

    class ERP,CRM,POS,WEB,IOT,SUP source;
    class EH,ADF,BRONZE,AKS,ACR,MON,SYN azure;
    class DBX,SILVER,GOLD lake;
    class SNOW,DBT,BI warehouse;
    class KV security;
    class GHA,TF devops;
```

---

## What This Repository Includes

| Layer          | Implementation                                               |
| -------------- | ------------------------------------------------------------ |
| Infrastructure | Terraform for Azure platform resources                       |
| Storage        | ADLS Gen2 bronze, silver, and gold lakehouse zones           |
| Streaming      | Event Hubs for POS, CRM, ERP, web, warehouse, and IoT events |
| Orchestration  | Azure Data Factory for batch and scheduled ingestion         |
| Processing     | Databricks Delta Lake with medallion transformations         |
| Warehouse      | Snowflake bootstrap SQL and dbt retail marts                 |
| Serving        | Synapse Analytics and Power BI-ready semantic models         |
| Runtime        | AKS microservices, Docker, Azure Container Registry          |
| Security       | Key Vault, managed identities, RBAC, diagnostics             |
| DevOps         | GitHub Actions CI/CD with Azure OIDC                         |

---

## Medallion Data Flow

```text
Retail Sources
  -> Azure Event Hubs / Azure Data Factory
  -> ADLS Gen2 Bronze
  -> Databricks Delta Lake
  -> ADLS Gen2 Silver
  -> ADLS Gen2 Gold
  -> Synapse / Snowflake / dbt
  -> Power BI and Executive Analytics
```

---

## Local Validation

```powershell
.\scripts\validate-local.ps1
```

Validation checks Python compilation, tests, Ruff when available, Terraform formatting/validation, and Kubernetes rendering when `kubectl` is installed.

---

## Deployment Flow

```powershell
copy infra\terraform\environments\dev\terraform.tfvars.example infra\terraform\environments\dev\terraform.tfvars
notepad infra\terraform\environments\dev\terraform.tfvars
.\scripts\deploy-azure.ps1 -Environment dev -TerraformVarFile infra\terraform\environments\dev\terraform.tfvars
```

Then configure Snowflake and dbt:

```powershell
snowsql -f snowflake\sql\bootstrap.sql
cd dbt
python -m pip install -r ..\requirements-dbt.txt
dbt parse
dbt test
```

---

## Security Notes

* No real secrets should be committed
* Use Azure Key Vault for runtime secrets
* Use GitHub OIDC for Azure authentication
* Use managed identities and least-privilege RBAC
* Use separate dev, stage, and prod environment values
* Provide real Azure, Databricks, Snowflake, and Informatica values before live deployment

---

## Author

**Sujoy Halder**
Azure | Data Engineering | Databricks | Snowflake | dbt | AKS | Terraform | Retail Analytics | CI/CD

GitHub: [sujoy-halder](https://github.com/sujoy-halder)

<div align="center">

<img src="https://capsule-render.vercel.app/api?type=rect&color=0:0078D4,50:16A34A,100:7C3AED&height=90&section=footer&text=Built%20for%20Global%20Retail%20Data%20Engineering&fontSize=24&fontColor=ffffff" />

</div>
