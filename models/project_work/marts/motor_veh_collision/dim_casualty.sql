-- Setting up the dimension table for dim_casualty with the below SQL code. 

WITH casualty AS (
    SELECT DISTINCT 
         CAST(number_of_persons_injured AS INT) AS persons_injured 
        ,CAST(number_of_persons_killed AS INT)  AS persons_killed
    FROM {{ref('staging_tbl_veh_collision')}}
    WHERE number_of_persons_killed IS NOT NULL 
        OR number_of_persons_injured  IS NOT NULL

)

,dim_casualty AS (
    SELECT 
        {{ dbt_utils.generate_surrogate_key(['persons_injured', 'persons_killed']) }} AS casualty_key
        ,persons_injured 
        ,persons_killed
    FROM casualty
)

SELECT *
FROM dim_casualty