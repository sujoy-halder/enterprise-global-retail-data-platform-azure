from __future__ import annotations

from typing import Any

from fastapi import FastAPI, Response
from pydantic import BaseModel, Field

from retail_platform.config import missing_required_environment
from retail_platform.medallion import bronze_envelope, silver_record
from retail_platform.schemas import EVENT_CONTRACTS


class ValidationRequest(BaseModel):
    event_type: str = Field(..., examples=["pos_transaction"])
    payload: dict[str, Any]


def create_app() -> FastAPI:
    app = FastAPI(title="Retail Ingestion API", version="0.1.0")
    counters = {"validated_records": 0, "quarantined_records": 0}

    @app.get("/healthz")
    def healthz() -> dict[str, str]:
        return {"status": "ok"}

    @app.get("/readyz")
    def readyz(response: Response) -> dict[str, Any]:
        missing = missing_required_environment()
        if missing:
            response.status_code = 503
        return {"ready": not missing, "missing": missing}

    @app.get("/contracts")
    def contracts() -> dict[str, dict[str, str]]:
        return {
            event_type: {
                "source_system": contract.source_system,
                "event_hub": contract.event_hub,
            }
            for event_type, contract in EVENT_CONTRACTS.items()
        }

    @app.post("/validate")
    def validate(request: ValidationRequest) -> dict[str, Any]:
        envelope = bronze_envelope(request.event_type, request.payload)
        silver = silver_record(envelope)
        counters["validated_records"] += 1
        if silver["quality_status"] == "quarantine":
            counters["quarantined_records"] += 1
        return silver

    @app.get("/metrics")
    def metrics() -> Response:
        body = "\n".join(
            [
                "# HELP retail_validated_records Total records validated by the API.",
                "# TYPE retail_validated_records counter",
                f"retail_validated_records {counters['validated_records']}",
                "# HELP retail_quarantined_records Total records sent to quarantine.",
                "# TYPE retail_quarantined_records counter",
                f"retail_quarantined_records {counters['quarantined_records']}",
                "",
            ]
        )
        return Response(content=body, media_type="text/plain; version=0.0.4")

    return app


app = create_app()
