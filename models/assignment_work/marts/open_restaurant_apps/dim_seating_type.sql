-- Seating type dimension for open restaurant seating applications
WITH seating_types AS (
    SELECT DISTINCT
        -- Explicitly casting to STRING for BigQuery surrogate key compatibility
        CAST(CASE 
            WHEN LOWER(approved_sidewalk) = 'yes' THEN 'TRUE' 
            ELSE 'FALSE' 
        END AS STRING) AS approved_for_sidewalk,
        
        CAST(CASE 
            WHEN LOWER(approved_roadway) = 'yes' THEN 'TRUE' 
            ELSE 'FALSE' 
        END AS STRING) AS approved_for_roadway
        
    FROM {{ ref('stg_nyc_open_restaurant_apps') }}
    WHERE approved_sidewalk IS NOT NULL 
       OR approved_roadway IS NOT NULL
),

seating_dimension AS (
    SELECT
        -- Generate a unique key for each combination
        {{ dbt_utils.generate_surrogate_key([
            'approved_for_sidewalk',
            'approved_for_roadway'
        ]) }} AS seating_type_key,

        -- Label logic: Both, Roadway, Sidewalk, or None
        CASE 
            WHEN approved_for_sidewalk = 'TRUE' AND approved_for_roadway = 'TRUE' THEN 'Both'
            WHEN approved_for_roadway = 'TRUE' THEN 'Roadway'
            WHEN approved_for_sidewalk = 'TRUE' THEN 'Sidewalk'
            ELSE 'None'
        END AS seating_interest,

        approved_for_sidewalk,
        approved_for_roadway

    FROM seating_types
)

SELECT * FROM seating_dimension