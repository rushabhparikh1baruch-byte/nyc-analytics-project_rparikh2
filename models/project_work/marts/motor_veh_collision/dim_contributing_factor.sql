WITH con_factor AS (
    SELECT DISTINCT
         contributing_factor_vehicle_1
        ,contributing_factor_vehicle_2
        ,contributing_factor_vehicle_3
        ,contributing_factor_vehicle_4
    FROM {{ ref('staging_tbl_veh_collision') }}
    WHERE contributing_factor_vehicle_1  IS NOT NULL
        OR contributing_factor_vehicle_2 IS NOT NULL
        OR contributing_factor_vehicle_3 IS NOT NULL
        OR contributing_factor_vehicle_4 IS NOT NULL

)

,dim_con_factor AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key([
            'contributing_factor_vehicle_1'
            ,'contributing_factor_vehicle_2'
            ,'contributing_factor_vehicle_3'
            ,'contributing_factor_vehicle_4'
        ]) }} AS factor_key

        ,contributing_factor_vehicle_1   AS factor_vehicle_1 
        ,contributing_factor_vehicle_2   AS factor_vehicle_2 
        ,contributing_factor_vehicle_3   AS factor_vehicle_3
        ,contributing_factor_vehicle_4   AS factor_vehicle_4
    FROM con_factor
)

SELECT *
FROM dim_con_factor