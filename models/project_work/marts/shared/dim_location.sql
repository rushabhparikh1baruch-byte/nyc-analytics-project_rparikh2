-- Location dimension shared by both vehicle collisions and 311 service reqs

WITH all_locations AS (
   -- Get locations from 311 requests
   SELECT DISTINCT
      borough,
      incident_zip as zip_code ,
    case 
        when intersection_street_1 is null then intersection_street_2
        when intersection_street_2 is null then intersection_street_1
        when intersection_street_1 <= intersection_street_2 then intersection_street_1
    else intersection_street_2 end as cross_street_1,
    case 
        when intersection_street_1 is null then null
        when intersection_street_2 is null then null
        when intersection_street_1 <= intersection_street_2 then intersection_street_2
    else intersection_street_1 end as cross_street_2
   FROM {{ ref('stg_nyc_311_street_complaints') }}
   WHERE borough IS NOT NULL

   UNION DISTINCT

   -- Get locations from vehicle collisions
   SELECT DISTINCT
       borough,
       zip_code ,
    case 
        when on_street_name is null then off_street_name
        when off_street_name is null then on_street_name
        when on_street_name <= off_street_name then on_street_name
    else off_street_name end as cross_street_1,
    case 
        when on_street_name is null then null
        when off_street_name is null then null
        when on_street_name <= off_street_name then off_street_name
    else on_street_name end as cross_street_2
   FROM {{ ref('staging_tbl_veh_collision') }}
   WHERE borough IS NOT NULL
),

location_dimension AS (
   SELECT
       {{ dbt_utils.generate_surrogate_key(['borough', 'zip_code', 'cross_street_1', 'cross_street_2']) }} AS location_key,
       borough,
       zip_code,
       cross_street_1,
       cross_street_2
   FROM all_locations
)

SELECT * FROM location_dimension