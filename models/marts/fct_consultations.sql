{{ config(materialized='table') }}

SELECT *
FROM {{ ref('int_consultations_enriched') }}
