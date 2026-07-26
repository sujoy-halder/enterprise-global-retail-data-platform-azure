# Databricks notebook source
from pyspark.sql import functions as F

dbutils.widgets.text("storage_account_name", "")
dbutils.widgets.text("silver_filesystem", "silver")
dbutils.widgets.text("gold_filesystem", "gold")

storage_account_name = dbutils.widgets.get("storage_account_name")
silver_filesystem = dbutils.widgets.get("silver_filesystem")
gold_filesystem = dbutils.widgets.get("gold_filesystem")

if not storage_account_name:
    raise ValueError("storage_account_name widget is required")

silver_base = f"abfss://{silver_filesystem}@{storage_account_name}.dfs.core.windows.net"
gold_base = f"abfss://{gold_filesystem}@{storage_account_name}.dfs.core.windows.net"

pos = spark.read.format("delta").load(f"{silver_base}/pos_transaction").where("quality_status = 'accepted'")
orders = spark.read.format("delta").load(f"{silver_base}/online_order").where("quality_status = 'accepted'")
inventory = spark.read.format("delta").load(f"{silver_base}/inventory_snapshot").where("quality_status = 'accepted'")
catalog = spark.read.format("delta").load(f"{silver_base}/product_catalog").where("quality_status = 'accepted'")
campaigns = spark.read.format("delta").load(f"{silver_base}/marketing_campaign").where("quality_status = 'accepted'")

sales = (
    pos.select(
        "event_id",
        F.col("event_time").cast("timestamp").alias("sold_at"),
        "store_id",
        F.lit(None).cast("string").alias("order_id"),
        "product_id",
        F.col("quantity").cast("double").alias("quantity"),
        F.col("gross_amount").cast("double").alias("gross_amount"),
        "currency",
        F.lit("store").alias("sales_channel"),
    )
    .unionByName(
        orders.select(
            "event_id",
            F.col("event_time").cast("timestamp").alias("sold_at"),
            F.lit(None).cast("string").alias("store_id"),
            "order_id",
            "product_id",
            F.col("quantity").cast("double").alias("quantity"),
            F.col("gross_amount").cast("double").alias("gross_amount"),
            F.lit("USD").alias("currency"),
            F.lit("online").alias("sales_channel"),
        )
    )
    .withColumn("sold_date", F.to_date("sold_at"))
)

inventory_position = inventory.select(
    F.col("event_time").cast("timestamp").alias("snapshot_at"),
    F.to_date("event_time").alias("snapshot_date"),
    "warehouse_id",
    "product_id",
    F.col("on_hand_quantity").cast("double").alias("on_hand_quantity"),
    F.col("reserved_quantity").cast("double").alias("reserved_quantity"),
)

product_dimension = catalog.select(
    "product_id",
    "sku",
    "category",
    F.col("unit_price").cast("double").alias("unit_price"),
    "active",
).dropDuplicates(["product_id"])

marketing_daily = campaigns.groupBy(F.to_date("event_time").alias("campaign_date"), "campaign_id", "channel").agg(
    F.sum(F.col("spend_amount").cast("double")).alias("spend_amount")
)

sales.write.format("delta").mode("overwrite").option("overwriteSchema", "true").partitionBy("sold_date").save(f"{gold_base}/sales")
inventory_position.write.format("delta").mode("overwrite").option("overwriteSchema", "true").partitionBy("snapshot_date").save(f"{gold_base}/inventory_position")
product_dimension.write.format("delta").mode("overwrite").option("overwriteSchema", "true").save(f"{gold_base}/product")
marketing_daily.write.format("delta").mode("overwrite").option("overwriteSchema", "true").partitionBy("campaign_date").save(f"{gold_base}/marketing_daily")
