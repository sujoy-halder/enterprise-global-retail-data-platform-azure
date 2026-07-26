# Databricks notebook source
dbutils.widgets.text("storage_account_name", "")
dbutils.widgets.text("bronze_filesystem", "bronze")
dbutils.widgets.text("silver_filesystem", "silver")

storage_account_name = dbutils.widgets.get("storage_account_name")
bronze_filesystem = dbutils.widgets.get("bronze_filesystem")
silver_filesystem = dbutils.widgets.get("silver_filesystem")

if not storage_account_name:
    raise ValueError("storage_account_name widget is required")

bronze_base = f"abfss://{bronze_filesystem}@{storage_account_name}.dfs.core.windows.net"
silver_base = f"abfss://{silver_filesystem}@{storage_account_name}.dfs.core.windows.net"

event_types = [
    "pos_transaction",
    "online_order",
    "inventory_snapshot",
    "supply_chain_event",
    "delivery_tracking",
    "customer_behavior",
    "product_catalog",
    "marketing_campaign",
    "iot_warehouse_sensor",
]

required_columns = {
    "pos_transaction": ["event_id", "event_time", "source_system", "transaction_id", "product_id"],
    "online_order": ["event_id", "event_time", "source_system", "order_id", "product_id"],
    "inventory_snapshot": ["event_id", "event_time", "source_system", "warehouse_id", "product_id"],
    "supply_chain_event": ["event_id", "event_time", "source_system", "supplier_id", "shipment_id"],
    "delivery_tracking": ["event_id", "event_time", "source_system", "shipment_id", "carrier_id"],
    "customer_behavior": ["event_id", "event_time", "source_system", "session_id", "event_name"],
    "product_catalog": ["event_id", "event_time", "source_system", "product_id", "sku"],
    "marketing_campaign": ["event_id", "event_time", "source_system", "campaign_id", "channel"],
    "iot_warehouse_sensor": ["event_id", "event_time", "source_system", "warehouse_id", "sensor_id"],
}


def add_quality_columns(df, event_type):
    from pyspark.sql import functions as F

    missing_expression = " OR ".join([f"{column} IS NULL" for column in required_columns[event_type]])
    return (
        df.withColumn("event_type", F.lit(event_type))
        .withColumn("event_date", F.to_date("event_time"))
        .withColumn(
            "quality_status",
            F.when(F.expr(missing_expression), F.lit("quarantine")).otherwise(F.lit("accepted")),
        )
        .withColumn("processed_at", F.current_timestamp())
    )


for event_type in event_types:
    source_path = f"{bronze_base}/{event_type}/"
    target_path = f"{silver_base}/{event_type}/"
    checkpoint_path = f"{silver_base}/_checkpoints/{event_type}/"

    stream_df = (
        spark.readStream.format("cloudFiles")
        .option("cloudFiles.format", "json")
        .option("cloudFiles.inferColumnTypes", "true")
        .load(source_path)
    )

    silver_df = add_quality_columns(stream_df, event_type)

    (
        silver_df.writeStream.format("delta")
        .option("checkpointLocation", checkpoint_path)
        .outputMode("append")
        .partitionBy("event_date")
        .trigger(availableNow=True)
        .start(target_path)
        .awaitTermination()
    )
