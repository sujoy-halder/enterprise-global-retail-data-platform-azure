"""Core contracts and transforms for the Azure retail data platform."""

from retail_platform.medallion import bronze_envelope, gold_metrics, silver_record
from retail_platform.schemas import EVENT_CONTRACTS, validate_record

__all__ = [
    "EVENT_CONTRACTS",
    "bronze_envelope",
    "gold_metrics",
    "silver_record",
    "validate_record",
]
