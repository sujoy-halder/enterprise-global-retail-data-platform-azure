from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from decimal import Decimal, InvalidOperation
from typing import Any


@dataclass(frozen=True)
class FieldRule:
    name: str
    kind: str
    required: bool = True
    min_value: Decimal | None = None
    allowed_values: tuple[str, ...] = ()


@dataclass(frozen=True)
class EventContract:
    event_type: str
    source_system: str
    event_hub: str
    required_fields: tuple[FieldRule, ...]
    pii_fields: tuple[str, ...] = ()


COMMON_FIELDS = (
    FieldRule("event_id", "string"),
    FieldRule("event_time", "timestamp"),
    FieldRule("source_system", "string"),
)


EVENT_CONTRACTS: dict[str, EventContract] = {
    "pos_transaction": EventContract(
        event_type="pos_transaction",
        source_system="POS",
        event_hub="pos-transactions",
        required_fields=COMMON_FIELDS
        + (
            FieldRule("store_id", "string"),
            FieldRule("terminal_id", "string"),
            FieldRule("transaction_id", "string"),
            FieldRule("product_id", "string"),
            FieldRule("quantity", "number", min_value=Decimal("0")),
            FieldRule("gross_amount", "number", min_value=Decimal("0")),
            FieldRule("currency", "string"),
        ),
    ),
    "online_order": EventContract(
        event_type="online_order",
        source_system="ECOMMERCE",
        event_hub="online-orders",
        required_fields=COMMON_FIELDS
        + (
            FieldRule("order_id", "string"),
            FieldRule("customer_id", "string"),
            FieldRule("product_id", "string"),
            FieldRule("quantity", "number", min_value=Decimal("0")),
            FieldRule("gross_amount", "number", min_value=Decimal("0")),
            FieldRule(
                "order_status",
                "string",
                allowed_values=("created", "paid", "shipped", "cancelled"),
            ),
        ),
        pii_fields=("customer_id",),
    ),
    "inventory_snapshot": EventContract(
        event_type="inventory_snapshot",
        source_system="WAREHOUSE",
        event_hub="inventory",
        required_fields=COMMON_FIELDS
        + (
            FieldRule("warehouse_id", "string"),
            FieldRule("product_id", "string"),
            FieldRule("on_hand_quantity", "number", min_value=Decimal("0")),
            FieldRule("reserved_quantity", "number", min_value=Decimal("0")),
        ),
    ),
    "supply_chain_event": EventContract(
        event_type="supply_chain_event",
        source_system="SUPPLIER",
        event_hub="supply-chain",
        required_fields=COMMON_FIELDS
        + (
            FieldRule("supplier_id", "string"),
            FieldRule("purchase_order_id", "string"),
            FieldRule("shipment_id", "string"),
            FieldRule("status", "string"),
        ),
    ),
    "delivery_tracking": EventContract(
        event_type="delivery_tracking",
        source_system="DELIVERY",
        event_hub="delivery-tracking",
        required_fields=COMMON_FIELDS
        + (
            FieldRule("shipment_id", "string"),
            FieldRule("carrier_id", "string"),
            FieldRule("status", "string"),
            FieldRule("latitude", "number"),
            FieldRule("longitude", "number"),
        ),
    ),
    "customer_behavior": EventContract(
        event_type="customer_behavior",
        source_system="WEB",
        event_hub="customer-behavior",
        required_fields=COMMON_FIELDS
        + (
            FieldRule("session_id", "string"),
            FieldRule("customer_id", "string", required=False),
            FieldRule("event_name", "string"),
            FieldRule("product_id", "string", required=False),
        ),
        pii_fields=("customer_id",),
    ),
    "product_catalog": EventContract(
        event_type="product_catalog",
        source_system="PIM",
        event_hub="product-catalog",
        required_fields=COMMON_FIELDS
        + (
            FieldRule("product_id", "string"),
            FieldRule("sku", "string"),
            FieldRule("category", "string"),
            FieldRule("unit_price", "number", min_value=Decimal("0")),
            FieldRule("active", "boolean"),
        ),
    ),
    "marketing_campaign": EventContract(
        event_type="marketing_campaign",
        source_system="MARKETING",
        event_hub="marketing-campaigns",
        required_fields=COMMON_FIELDS
        + (
            FieldRule("campaign_id", "string"),
            FieldRule("channel", "string"),
            FieldRule("spend_amount", "number", min_value=Decimal("0")),
            FieldRule("currency", "string"),
        ),
    ),
    "iot_warehouse_sensor": EventContract(
        event_type="iot_warehouse_sensor",
        source_system="IOT",
        event_hub="iot-warehouse-sensors",
        required_fields=COMMON_FIELDS
        + (
            FieldRule("warehouse_id", "string"),
            FieldRule("sensor_id", "string"),
            FieldRule("metric_name", "string"),
            FieldRule("metric_value", "number"),
            FieldRule("unit", "string"),
        ),
    ),
}


def validate_record(event_type: str, record: dict[str, Any]) -> list[str]:
    """Return contract errors. Empty list means the record is valid."""

    if event_type not in EVENT_CONTRACTS:
        return [f"unknown event_type: {event_type}"]

    errors: list[str] = []
    contract = EVENT_CONTRACTS[event_type]
    for field in contract.required_fields:
        if field.required and field.name not in record:
            errors.append(f"{field.name}: missing required field")
            continue
        if field.name not in record or record[field.name] is None:
            continue

        value = record[field.name]
        if field.kind == "string" and not _is_non_empty_string(value):
            errors.append(f"{field.name}: expected non-empty string")
        elif field.kind == "timestamp" and not _is_iso_timestamp(value):
            errors.append(f"{field.name}: expected ISO-8601 timestamp")
        elif field.kind == "number":
            number = _to_decimal(value)
            if number is None:
                errors.append(f"{field.name}: expected number")
            elif field.min_value is not None and number < field.min_value:
                errors.append(f"{field.name}: below minimum {field.min_value}")
        elif field.kind == "boolean" and not isinstance(value, bool):
            errors.append(f"{field.name}: expected boolean")

        if field.allowed_values and str(value) not in field.allowed_values:
            allowed = ", ".join(field.allowed_values)
            errors.append(f"{field.name}: expected one of {allowed}")

    actual_source = record.get("source_system")
    if actual_source and str(actual_source).upper() != contract.source_system:
        errors.append(f"source_system: expected {contract.source_system}")

    return errors


def _is_non_empty_string(value: Any) -> bool:
    return isinstance(value, str) and bool(value.strip())


def _is_iso_timestamp(value: Any) -> bool:
    if not isinstance(value, str):
        return False
    normalized = value.replace("Z", "+00:00")
    try:
        datetime.fromisoformat(normalized)
    except ValueError:
        return False
    return True


def _to_decimal(value: Any) -> Decimal | None:
    if isinstance(value, bool):
        return None
    try:
        return Decimal(str(value))
    except (InvalidOperation, ValueError):
        return None
