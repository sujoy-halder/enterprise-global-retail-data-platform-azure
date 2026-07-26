from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from retail_platform.schemas import EVENT_CONTRACTS, validate_record


@dataclass(frozen=True)
class QualityResult:
    event_type: str
    accepted: bool
    errors: tuple[str, ...]
    pii_fields: tuple[str, ...]


def evaluate_quality(event_type: str, record: dict[str, Any]) -> QualityResult:
    errors = validate_record(event_type, record)
    contract = EVENT_CONTRACTS.get(event_type)
    return QualityResult(
        event_type=event_type,
        accepted=not errors,
        errors=tuple(errors),
        pii_fields=contract.pii_fields if contract else (),
    )


def route_quality_path(event_type: str, record: dict[str, Any]) -> str:
    result = evaluate_quality(event_type, record)
    status = "accepted" if result.accepted else "quarantine"
    return f"{event_type}/{status}"
