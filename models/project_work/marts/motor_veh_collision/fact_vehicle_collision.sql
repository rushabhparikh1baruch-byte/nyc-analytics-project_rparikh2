-- fact_vehicle_collisions: One row per collision event
-- Joins to Date, Time, Location, Casualty, and Contributing Factor dimensions

WITH collisions AS (
    -- Reference the project_work version of the staging table
    -- We explicitly alias the casualty columns here to resolve the BigQuery 400 error
    SELECT 
        * EXCEPT(number_of_persons_injured, number_of_persons_killed),
        CAST(number_of_persons_injured AS INT64) AS persons_injured,
        CAST(number_of_persons_killed AS INT64) AS persons_killed
    FROM {{ ref('staging_tbl_veh_collision') }}
),

dim_location AS (
    SELECT * FROM {{ ref('dim_location') }}
),

dim_casualty AS (
    SELECT * FROM {{ ref('dim_casualty') }}
),

dim_contributing_factor AS (
    SELECT * FROM {{ ref('dim_contributing_factor') }}
)

SELECT
    -- Primary Key
    {{ dbt_utils.generate_surrogate_key(['c.collision_id']) }} AS collision_key,

    -- Foreign Keys (Generated to match dimension logic)
    {{ dbt_utils.generate_surrogate_key(['c.crash_date']) }} AS crash_date_key,
    
    {{ dbt_utils.generate_surrogate_key([
        'EXTRACT(HOUR FROM PARSE_TIME("%H:%M", c.crash_time))',
        'EXTRACT(MINUTE FROM PARSE_TIME("%H:%M", c.crash_time))'
    ]) }} AS crash_time_key,

    l.location_key,
    ca.casualty_key,
    f.factor_key,

    -- Degenerate Dimensions / Exact Location
    c.exact_location

FROM collisions c

-- Join to Location using the alphabetical street sorting logic
LEFT JOIN dim_location l 
    ON c.borough = l.borough 
    AND c.zip_code = l.zip_code
    AND (
        CASE 
            WHEN c.on_street_name <= c.off_street_name THEN c.on_street_name 
            ELSE c.off_street_name 
        END = l.cross_street_1
    )
    AND (
        CASE 
            WHEN c.on_street_name <= c.off_street_name THEN c.off_street_name 
            ELSE c.on_street_name 
        END = l.cross_street_2
    )

-- Join to Casualty (Now matches the aliases created in the CTE above)
LEFT JOIN dim_casualty ca 
    ON c.persons_injured = ca.persons_injured
    AND c.persons_killed = ca.persons_killed

-- Join to Contributing Factors
LEFT JOIN dim_contributing_factor f 
    ON c.factor_1 = f.factor_vehicle_1
    AND c.factor_2 = f.factor_vehicle_2