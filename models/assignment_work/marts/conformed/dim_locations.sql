-- Location dimension shared by both restaurant applications and 311 service reqs
-- This ensures a "single version of the truth" for NYC geography across datasets

WITH all_locations AS (
    -- Get locations from 311 requests
    -- We alias incident_zip to zip_code to match the restaurant data for the UNION
    SELECT DISTINCT
        borough,
        incident_zip AS zip_code
    FROM {{ ref('stg_nyc_311_dot') }}
    WHERE borough IS NOT NULL

    UNION DISTINCT

    -- Get locations from restaurant applications
    SELECT DISTINCT
        borough,
        zip_code
    FROM {{ ref('stg_nyc_open_restaurant_apps') }}
    WHERE borough IS NOT NULL
),

location_dimension AS (
    SELECT
        -- Generate a unique surrogate key based on the natural keys
        {{ dbt_utils.generate_surrogate_key(['borough', 'zip_code']) }} AS location_key,
        borough,
        zip_code
    FROM all_locations
)

-- Final selection of the conformed dimension attributes
SELECT * FROM location_dimension