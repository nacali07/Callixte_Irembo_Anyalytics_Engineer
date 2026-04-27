{{ config(materialized='view') }}

SELECT *
FROM {{ source('teleclinic_raw', 'providers') }}
