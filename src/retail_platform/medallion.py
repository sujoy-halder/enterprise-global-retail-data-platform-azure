from __future__ import annotations

import hashlib
import json
from datetime import UTC, datetime
from decimal import Decimal
from typing import Any

from retail_platform.schemas import EVENT_CONTRACTS, validate_record


def bronze_envelope(
    event_type: str,
    payload: dict[str, Any],
    *,
    ingestion_time: datetime | None = None,
) -> dict[str, Any]:
    if event_type not in EVENT_CONTRACTS:
        raise ValueError(f"unknown event_type: {event_type}")

    observed_at = ingestion_time or datetime.now(UTC)
    canonical_payload = json.dumps(payload, sort_keys=True, separators=(",", ":"), default=str)
    digest = hashlib.sha256(canonical_payload.encode("utf-8")).hexdigest()
    contract = EVENT_CONTRACTS[event_type]
    return {
        "event_type": event_type,
        "event_hub": contract.event_hub,
        "source_system": payload.get("source_system", contract.source_system),
        "ingestion_time": observed_at.isoformat(),
        "payload_hash": digest,
        "payload": payload,
    }


def silver_record(envelope: dict[str, Any]) -> dict[str, Any]:
    event_type = str(envelope["event_type"])
    payload = dict(envelope["payload"])
    errors = validate_record(event_type, payload)
    if errors:
        return {
            "event_type": event_type,
            "quality_status": "quarantine",
            "quality_errors": errors,
            "payload_hash": envelope["payload_hash"],
            "payload": payload,
        }

    normalized = {
        key: _normalize_value(value)
        for key, value in payload.items()
        if key not in EVENT_CONTRACTS[event_type].pii_fields
    }
    normalized.update(
        {
            "event_type": event_type,
            "quality_status": "accepted",
            "quality_errors": [],
            "payload_hash": envelope["payload_hash"],
            "ingestion_time": envelope["ingestion_time"],
        }
    )
    return normalized


def gold_metrics(silver_records: list[dict[str, Any]]) -> dict[str, Any]:
    accepted = [record for record in silver_records if record.get("quality_status") == "accepted"]
    revenue_events = [
        record
        for record in accepted
        if record.get("event_type") in {"pos_transaction", "online_order"}
    ]

    gross_revenue = sum(Decimal(str(record.get("gross_amount", 0))) for record in revenue_events)
    units_sold = sum(Decimal(str(record.get("quantity", 0))) for record in revenue_events)
    inventory_units = sum(
        Decimal(str(record.get("on_hand_quantity", 0)))
        for record in accepted
        if record.get("event_type") == "inventory_snapshot"
    )

    return {
        "accepted_records": len(accepted),
        "quarantined_records": len(silver_records) - len(accepted),
        "gross_revenue": str(gross_revenue),
        "units_sold": str(units_sold),
        "inventory_units_on_hand": str(inventory_units),
    }


def _normalize_value(value: Any) -> Any:
    if isinstance(value, str):
        stripped = value.strip()
        return stripped.upper() if stripped in {"usd", "eur", "gbp", "inr"} else stripped
    return value
