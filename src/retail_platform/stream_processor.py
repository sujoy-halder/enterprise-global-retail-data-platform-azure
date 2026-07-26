from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

from retail_platform.medallion import bronze_envelope, gold_metrics, silver_record


def process_jsonl(input_path: Path, output_path: Path) -> dict[str, Any]:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    silver_records: list[dict[str, Any]] = []

    with input_path.open("r", encoding="utf-8") as source:
        for line in source:
            if not line.strip():
                continue
            event = json.loads(line)
            envelope = bronze_envelope(event["event_type"], event["payload"])
            silver_records.append(silver_record(envelope))

    with output_path.open("w", encoding="utf-8") as target:
        for record in silver_records:
            target.write(json.dumps(record, sort_keys=True) + "\n")

    return gold_metrics(silver_records)


def main() -> None:
    parser = argparse.ArgumentParser(description="Local JSONL stream processor smoke entrypoint.")
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    metrics = process_jsonl(args.input, args.output)
    print(json.dumps(metrics, sort_keys=True))


if __name__ == "__main__":
    main()
