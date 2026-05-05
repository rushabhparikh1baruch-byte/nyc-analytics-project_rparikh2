WITH collisions AS (
    SELECT 
        * EXCEPT(number_of_persons_injured, number_of_persons_killed),
        CAST(COALESCE(number_of_persons_injured, 0) AS INT64) AS persons_injured,
        CAST(COALESCE(number_of_persons_killed, 0) AS INT64) AS persons_killed,
        CAST(PARSE_TIME('%H:%M', crash_time) AS TIME) AS crash_time_obj
    FROM {{ ref('staging_tbl_veh_collision') }}
),

-- Reference existing dimensions
dim_location AS ( SELECT * FROM {{ ref('dim_location') }} ),
dim_casualty AS ( SELECT * FROM {{ ref('dim_casualty') }} ),
dim_con_factor AS ( SELECT * FROM {{ ref('dim_contributing_factor') }} ),
dim_date AS ( SELECT * FROM {{ ref('dim_date') }} ),
dim_time AS ( SELECT * FROM {{ ref('dim_time') }} )

SELECT
    -- Primary Key
    {{ dbt_utils.generate_surrogate_key(['c.collision_id']) }} AS collision_key,

    -- Foreign Keys from Joined Dimensions
    d.date_key AS crash_date_key,
    t.time_key AS crash_time_key,
    l.location_key,
    ca.casualty_key,
    f.factor_key,

    -- Measures & Coordinates
    c.latitude,
    c.longitude,
    c.persons_injured,
    c.persons_killed

FROM collisions c

-- 1. Join to Date
LEFT JOIN dim_date d 
    ON CAST(c.crash_date AS DATE) = d.full_date

-- 2. Join to Time (Simplified join on the TIME object)
LEFT JOIN dim_time t 
    ON c.crash_time_obj = t.crash_time

-- 3. Join to Location (Handling the street sorting logic)
LEFT JOIN dim_location l 
    ON c.borough = l.borough 
    AND c.zip_code = l.zip_code
    AND (CASE 
            WHEN c.on_street_name IS NULL THEN c.off_street_name
            WHEN c.off_street_name IS NULL THEN c.on_street_name
            WHEN c.on_street_name <= c.off_street_name THEN c.on_street_name 
            ELSE c.off_street_name 
         END) = l.cross_street_1
    AND (CASE 
            WHEN c.on_street_name IS NULL OR c.off_street_name IS NULL THEN NULL
            WHEN c.on_street_name <= c.off_street_name THEN c.off_street_name 
            ELSE c.on_street_name 
         END) = l.cross_street_2

-- 4. Join to Casualty 
LEFT JOIN dim_casualty ca 
    ON c.persons_injured = ca.persons_injured
    AND c.persons_killed = ca.persons_killed

-- 5. Join to Contributing Factors (Corrected column names from staging)
LEFT JOIN dim_con_factor f 
    ON COALESCE(c.contributing_factor_vehicle_1, 'Unspecified') = f.factor_vehicle_1
    AND COALESCE(c.contributing_factor_vehicle_2, 'Unspecified') = f.factor_vehicle_2
    AND COALESCE(c.contributing_factor_vehicle_3, 'Unspecified') = f.factor_vehicle_3
    AND COALESCE(c.contributing_factor_vehicle_4, 'Unspecified') = f.factor_vehicle_4