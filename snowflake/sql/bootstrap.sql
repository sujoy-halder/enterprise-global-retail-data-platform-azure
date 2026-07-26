-- Replace placeholders before running in a real Snowflake account.
-- Required role: ACCOUNTADMIN or delegated platform provisioning role.

set retail_database = 'RETAIL_DW';
set transform_warehouse = 'RETAIL_TRANSFORM_WH';
set loader_role = 'RETAIL_LOADER_ROLE';
set dbt_role = 'RETAIL_DBT_ROLE';
set powerbi_role = 'RETAIL_POWERBI_ROLE';
set azure_tenant_id = '<AZURE_TENANT_ID>';
set adls_account = '<ADLS_ACCOUNT_NAME>';
set bronze_url = 'azure://<ADLS_ACCOUNT_NAME>.blob.core.windows.net/bronze/';
set gold_url = 'azure://<ADLS_ACCOUNT_NAME>.blob.core.windows.net/gold/';
set gold_sales_url = 'azure://<ADLS_ACCOUNT_NAME>.blob.core.windows.net/gold/sales/';

create warehouse if not exists identifier($transform_warehouse)
  warehouse_size = 'MEDIUM'
  auto_suspend = 60
  auto_resume = true
  initially_suspended = true;

create database if not exists identifier($retail_database);
create schema if not exists identifier($retail_database || '.RAW');
create schema if not exists identifier($retail_database || '.STAGING');
create schema if not exists identifier($retail_database || '.GOLD');

create role if not exists identifier($loader_role);
create role if not exists identifier($dbt_role);
create role if not exists identifier($powerbi_role);

grant usage on warehouse identifier($transform_warehouse) to role identifier($loader_role);
grant usage on warehouse identifier($transform_warehouse) to role identifier($dbt_role);
grant usage on database identifier($retail_database) to role identifier($loader_role);
grant usage on database identifier($retail_database) to role identifier($dbt_role);
grant usage on database identifier($retail_database) to role identifier($powerbi_role);
grant usage on all schemas in database identifier($retail_database) to role identifier($dbt_role);
grant usage on schema identifier($retail_database || '.GOLD') to role identifier($powerbi_role);
grant select on future tables in schema identifier($retail_database || '.GOLD') to role identifier($powerbi_role);

create storage integration if not exists retail_adls_integration
  type = external_stage
  storage_provider = azure
  enabled = true
  azure_tenant_id = $azure_tenant_id
  storage_allowed_locations = ($gold_url, $bronze_url);

-- After creation, run DESCRIBE INTEGRATION retail_adls_integration and grant consent in Azure.

create file format if not exists identifier($retail_database || '.RAW.JSON_FORMAT')
  type = json
  strip_outer_array = false;

create stage if not exists identifier($retail_database || '.RAW.POS_TRANSACTIONS_STAGE')
  url = $gold_sales_url
  storage_integration = retail_adls_integration
  file_format = identifier($retail_database || '.RAW.JSON_FORMAT');

create or replace table identifier($retail_database || '.RAW.POS_TRANSACTIONS') (
  event_id varchar,
  event_time timestamp_ntz,
  source_system varchar,
  store_id varchar,
  terminal_id varchar,
  transaction_id varchar,
  product_id varchar,
  quantity number(18, 4),
  gross_amount number(18, 4),
  currency varchar,
  quality_status varchar,
  processed_at timestamp_ntz
);

grant select, insert, update, delete on future tables in schema identifier($retail_database || '.RAW') to role identifier($loader_role);
grant select, insert, update, delete on future tables in schema identifier($retail_database || '.STAGING') to role identifier($dbt_role);
grant select, insert, update, delete on future tables in schema identifier($retail_database || '.GOLD') to role identifier($dbt_role);
