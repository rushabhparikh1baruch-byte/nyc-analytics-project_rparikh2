-- Seating type dimension for status and resolution
WITH resolutions AS (
   SELECT DISTINCT
       status,
       resolution_description
   FROM {{ ref('stg_nyc_311_street_complaints') }} --TODO: reference the appropriate staging table!
   WHERE status IS NOT NULL
),
resolution_dimension AS (
   SELECT
       {{ dbt_utils.generate_surrogate_key([
           'status',
           'resolution_description'
       ]) }} AS resolution_key,
        status,
        resolution_description

   FROM resolutions
)

SELECT * FROM resolution_dimension