from __future__ import annotations

import os
from dataclasses import dataclass


@dataclass(frozen=True)
class ServiceSettings:
    environment: str
    service_name: str
    log_level: str
    eventhub_namespace: str
    eventhub_consumer_group: str
    adls_account_name: str
    bronze_filesystem: str
    silver_filesystem: str
    gold_filesystem: str


def load_settings() -> ServiceSettings:
    return ServiceSettings(
        environment=os.getenv("ENVIRONMENT", "dev"),
        service_name=os.getenv("SERVICE_NAME", "retail-ingestion-api"),
        log_level=os.getenv("LOG_LEVEL", "INFO"),
        eventhub_namespace=_require("EVENTHUB_NAMESPACE"),
        eventhub_consumer_group=os.getenv("EVENTHUB_CONSUMER_GROUP", "databricks"),
        adls_account_name=_require("ADLS_ACCOUNT_NAME"),
        bronze_filesystem=os.getenv("ADLS_FILESYSTEM_BRONZE", "bronze"),
        silver_filesystem=os.getenv("ADLS_FILESYSTEM_SILVER", "silver"),
        gold_filesystem=os.getenv("ADLS_FILESYSTEM_GOLD", "gold"),
    )


def missing_required_environment() -> list[str]:
    required = ("EVENTHUB_NAMESPACE", "ADLS_ACCOUNT_NAME")
    return [name for name in required if not os.getenv(name)]


def _require(name: str) -> str:
    value = os.getenv(name)
    if not value:
        raise RuntimeError(f"missing required environment variable: {name}")
    return value
