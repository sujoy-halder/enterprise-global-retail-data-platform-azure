from pathlib import Path

from retail_platform.medallion import bronze_envelope, gold_metrics, silver_record
from retail_platform.stream_processor import process_jsonl


def test_silver_record_masks_customer_identifier() -> None:
    envelope = bronze_envelope(
        "online_order",
        {
            "event_id": "evt-3",
            "event_time": "2026-07-26T13:45:00Z",
            "source_system": "ECOMMERCE",
            "order_id": "ord-1",
            "customer_id": "cust-secret",
            "product_id": "sku-1",
            "quantity": 2,
            "gross_amount": "30.50",
            "order_status": "paid",
        },
    )
    silver = silver_record(envelope)
    assert silver["quality_status"] == "accepted"
    assert "customer_id" not in silver


def test_gold_metrics_summarizes_accepted_records() -> None:
    records = [
        {
            "event_type": "pos_transaction",
            "quality_status": "accepted",
            "quantity": 2,
            "gross_amount": "12.50",
        },
        {
            "event_type": "online_order",
            "quality_status": "accepted",
            "quantity": 1,
            "gross_amount": "20.00",
        },
        {"event_type": "inventory_snapshot", "quality_status": "accepted", "on_hand_quantity": 7},
        {
            "event_type": "pos_transaction",
            "quality_status": "quarantine",
            "quantity": 2,
            "gross_amount": "99.99",
        },
    ]
    assert gold_metrics(records) == {
        "accepted_records": 3,
        "quarantined_records": 1,
        "gross_revenue": "32.50",
        "units_sold": "3",
        "inventory_units_on_hand": "7",
    }


def test_local_stream_processor(tmp_path: Path) -> None:
    input_path = tmp_path / "events.jsonl"
    output_path = tmp_path / "silver.jsonl"
    input_path.write_text(
        '{"event_type":"pos_transaction","payload":{"event_id":"evt-1","event_time":"2026-07-26T13:45:00Z","source_system":"POS","store_id":"s1","terminal_id":"t1","transaction_id":"tx1","product_id":"sku","quantity":1,"gross_amount":"8.00","currency":"USD"}}\n',
        encoding="utf-8",
    )
    metrics = process_jsonl(input_path, output_path)
    assert metrics["gross_revenue"] == "8.00"
    assert output_path.exists()
