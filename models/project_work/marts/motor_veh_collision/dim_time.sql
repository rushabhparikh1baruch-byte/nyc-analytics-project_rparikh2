WITH time_values AS (
    SELECT DISTINCT 
        CAST(PARSE_TIME('%H:%M', crash_time) AS TIME) AS crash_time_obj
    FROM {{ ref('staging_tbl_veh_collision') }}
    WHERE crash_time IS NOT NULL 
),

final_dim AS (
    SELECT 
        crash_time_obj AS crash_time,
        EXTRACT(HOUR FROM crash_time_obj) AS hour,
        EXTRACT(MINUTE FROM crash_time_obj) AS minute,
        -- Added for analytical value
        CASE 
            WHEN EXTRACT(HOUR FROM crash_time_obj) BETWEEN 6 AND 9 THEN 'Morning Rush'
            WHEN EXTRACT(HOUR FROM crash_time_obj) BETWEEN 16 AND 19 THEN 'Evening Rush'
            WHEN EXTRACT(HOUR FROM crash_time_obj) BETWEEN 0 AND 5 THEN 'Overnight'
            ELSE 'Off-Peak'
        END AS time_of_day_category
    FROM time_values
)

SELECT 
    {{ dbt_utils.generate_surrogate_key(['hour', 'minute']) }} AS time_key,
    *
FROM final_dim