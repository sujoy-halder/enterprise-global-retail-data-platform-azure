from retail_platform.schemas import EVENT_CONTRACTS, validate_record


def test_all_contracts_route_to_event_hubs() -> None:
    assert len(EVENT_CONTRACTS) == 9
    assert EVENT_CONTRACTS["iot_warehouse_sensor"].event_hub == "iot-warehouse-sensors"


def test_valid_pos_transaction_passes() -> None:
    record = {
        "event_id": "evt-1",
        "event_time": "2026-07-26T13:45:00Z",
        "source_system": "POS",
        "store_id": "store-100",
        "terminal_id": "term-8",
        "transaction_id": "txn-1",
        "product_id": "sku-1",
        "quantity": 2,
        "gross_amount": "19.99",
        "currency": "USD",
    }
    assert validate_record("pos_transaction", record) == []


def test_invalid_order_reports_actionable_errors() -> None:
    record = {
        "event_id": "evt-2",
        "event_time": "not-a-date",
        "source_system": "ECOMMERCE",
        "order_id": "ord-1",
        "customer_id": "cust-1",
        "product_id": "sku-1",
        "quantity": -1,
        "gross_amount": 10,
        "order_status": "packed",
    }
    errors = validate_record("online_order", record)
    assert "event_time: expected ISO-8601 timestamp" in errors
    assert "quantity: below minimum 0" in errors
    assert "order_status: expected one of created, paid, shipped, cancelled" in errors
