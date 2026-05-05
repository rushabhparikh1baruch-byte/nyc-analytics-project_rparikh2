-- fact_vehicle_collision: One row per collision event
-- Joins to Date, Time, Location, Casualty, and Contributing Factor dimensions

WITH collisions AS (
    SELECT * FROM {{ ref('staging_tbl_veh_collision') }}
),

dim_location AS (
    SELECT * FROM {{ ref('dim_location') }}
),

dim_casualty AS (
    SELECT * FROM {{ ref('dim_casualty') }}
),

dim_con_factor AS (
    SELECT * FROM {{ ref('dim_con_factor') }}
)

SELECT
    -- Primary Key
    {{ dbt_utils.generate_surrogate_key(['c.collision_id']) }} AS collision_key,

    -- Foreign Keys (Matching the Logic in your Dimensions)
    {{ dbt_utils.generate_surrogate_key(['c.crash_date']) }} AS crash_date_key,
    
    {{ dbt_utils.generate_surrogate_key([
        'EXTRACT(HOUR FROM PARSE_TIME("%H:%M", c.crash_time))',
        'EXTRACT(MINUTE FROM PARSE_TIME("%H:%M", c.crash_time))'
    ]) }} AS crash_time_key,

    l.location_key,
    ca.casualty_key,
    f.factor_key,

    -- Degenerate Dimension / Exact Location Attribute
    c.exact_location

FROM collisions c
-- Join to Location using the standardized keys
LEFT JOIN dim_location l 
    ON c.borough = l.borough 
    AND c.zip_code = l.zip_code
    AND (
        CASE 
            WHEN c.on_street_name <= c.off_street_name THEN c.on_street_name 
            ELSE c.off_street_name 
        END = l.cross_street_1
    )
-- Join to Casualty
LEFT JOIN dim_casualty ca 
    ON CAST(c.number_of_persons_injured AS INT64) = ca.persons_injured
    AND CAST(c.number_of_persons_killed AS INT64) = ca.persons_killed
-- Join to Factors
LEFT JOIN dim_con_factor f 
    ON c.contributing_factor_vehicle_1 = f.factor_vehicle_1
    AND c.contributing_factor_vehicle_2 = f.factor_vehicle_2