WITH veh_collision_data AS (
   SELECT * 
   FROM (
    SELECT *
        ,ROW_NUMBER() OVER (PARTITION BY collision_id ORDER BY crash_date DESC) AS RN
    FROM {{ source('raw', 'source_nyc_motor_vehicle_collisions') }}
   ) row_num
   WHERE RN = 1 -- removes duplicates
)

-- main --

SELECT 
     collision_id
    ,crash_date
    ,CASE
        WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
        WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
        WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
        WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
        WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
        ELSE 'UNKNOWN'
    END AS borough
    ,CASE 
        WHEN TRIM(zip_code) IS NULL THEN '00000'
        WHEN TRIM(zip_code) = '' THEN '00000'
        ELSE zip_code
    END AS zip_code
    ,on_street_name
    ,off_street_name
    ,cross_street_name
    ,latitude
    ,longitude
    ,contributing_factor_vehicle_1
    ,contributing_factor_vehicle_2
    ,contributing_factor_vehicle_3
    ,contributing_factor_vehicle_4
    ,contributing_factor_vehicle_5
    ,crash_time
    ,number_of_cyclist_injured
    ,number_of_cyclist_killed
    ,number_of_motorist_injured
    ,number_of_motorist_killed
    ,number_of_pedestrians_injured
    ,number_of_pedestrians_killed
    ,number_of_persons_injured
    ,number_of_persons_killed
    ,vehicle_type_code1
    ,vehicle_type_code2
    ,vehicle_type_code_3
    ,vehicle_type_code_4
    ,vehicle_type_code_5
    ,CURRENT_TIMESTAMP() AS load_datetime
FROM veh_collision_data