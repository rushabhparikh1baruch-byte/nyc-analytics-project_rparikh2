WITH time AS (
    SELECT DISTINCT 
        CAST(PARSE_TIME('%H:%M', crash_time) AS TIME) AS crash_time  -- converting crash time to HH:MM:SS
    FROM {{ref('staging_tbl_veh_collision')}}
    WHERE crash_time IS NOT NULL 

)

,dim_time AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key([
            'EXTRACT(HOUR FROM crash_time)'
            ,'EXTRACT(MINUTE FROM crash_time)'
        ]) }} AS time_key
        ,CAST(COALESCE(EXTRACT(HOUR FROM crash_time),0) AS INT)   AS hour -- extracting the hour from the time and replacing the NULLs with 0
        ,CAST(COALESCE(EXTRACT(MINUTE FROM crash_time),0) AS INT) AS minute -- extracting the minute from the time and replacing the NULLs with 0
    FROM time
)

SELECT *
FROM dim_time