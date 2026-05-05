-- fact_service_request: One row per 311 service request
-- Joins to Date, Location, and Resolution dimensions

WITH service_requests AS (
    -- Reference the staging model for street condition complaints
    SELECT * FROM {{ ref('stg_nyc_311_street_complaints') }}
),

dim_location AS (
    SELECT * FROM {{ ref('dim_location') }}
),

dim_resolution AS (
    SELECT * FROM {{ ref('dim_resolution') }}
)

SELECT
    -- Primary Key (SR Key)
    {{ dbt_utils.generate_surrogate_key(['sr.request_id']) }} AS sr_key,

    -- Foreign Keys to dim_date (Created, Closed, and Resolution Action dates)
    {{ dbt_utils.generate_surrogate_key(['CAST(sr.created_date AS DATE)']) }} AS created_date_key,
    {{ dbt_utils.generate_surrogate_key(['CAST(sr.closed_date AS DATE)']) }} AS closed_date_key,
    
    -- The date the resolution was updated (mapped from staging metadata/updated field)
    {{ dbt_utils.generate_surrogate_key(['CAST(sr._stg_loaded_at AS DATE)']) }} AS resolution_action_date_key,

    -- Foreign Key to dim_location
    l.location_key,

    -- Foreign Key to dim_resolution
    r.resolution_key,

    -- Degenerate Dimensions / Attributes
    sr.descriptor AS problem_detail,
    sr.exact_location

FROM service_requests sr

-- Join to Location using the standardized intersection logic
LEFT JOIN dim_location l 
    ON sr.borough = l.borough 
    AND sr.incident_zip = l.zip_code
    AND (
        CASE 
            WHEN sr.cross_street_1 <= sr.cross_street_2 THEN sr.cross_street_1 
            ELSE sr.cross_street_2 
        END = l.cross_street_1
    )

-- Join to Resolution
LEFT JOIN dim_resolution r 
    ON sr.status = r.status
    AND sr.resolution_description = r.resolution_description