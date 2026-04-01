-- Clean and standardize NYC Open Restaurant Applications data
-- One row per application

WITH source AS (
   SELECT * FROM {{ source('raw', 'source_nyc_open_restaurant_apps') }}
),

renamed_and_cleaned AS (
    SELECT
        -- Identifiers
        CAST(objectid AS STRING) AS request_id,
        CAST(globalid AS STRING) AS global_id,

        -- Date/Time
        CAST(time_of_submission AS TIMESTAMP) AS created_date,

        -- Business Details
        UPPER(TRIM(CAST(legal_business_name AS STRING))) AS legal_business_name,
        UPPER(TRIM(CAST(doing_business_as_dba AS STRING))) AS dba_name,
        UPPER(TRIM(CAST(restaurant_name AS STRING))) AS restaurant_name,
        CAST(food_service_establishment AS STRING) AS establishment_type,

        -- Address Standardization Logic
        -- 1. Standardize Suffixes (Rd, St, Ave, Blvd)
        -- 2. Standardize Prefixes (W, E, N, S)
        -- 3. Capitalize first letter of each word (INITCAP)
        INITCAP(
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    REGEXP_REPLACE(
                        REGEXP_REPLACE(
                            REGEXP_REPLACE(
                                REGEXP_REPLACE(
                                    REGEXP_REPLACE(
                                        REGEXP_REPLACE(CAST(street AS STRING), 
                                        r'(?i)\bRoad\b|\broad\b|\brd\b|\bRd\b|\broaf\b', 'Rd'),
                                    r'(?i)\bStreet\b|\bstreet\b|\bST\b|\bst\b', 'St'),
                                r'(?i)\bAvenue\b|\bave\.\b|\bAve\b', 'Ave'),
                            r'(?i)\bBoulevard\b|\bboulevard\b|\bblvd\.\b', 'Blvd'),
                        r'(?i)\bWest\b', 'W'),
                    r'(?i)\bEast\b', 'E'),
                r'(?i)\bNorth\b', 'N'),
            r'(?i)\bSouth\b', 'S')
        ) AS street_name,

        CAST(bulding_number AS STRING) AS building_number,
        CAST(business_address AS STRING) AS full_address,

        -- Standardized Borough Logic
        CASE
            WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
            WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
            WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
            WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
            WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
            ELSE 'UNKNOWN or CITYWIDE'
        END AS borough,

        -- Standardized Zip Code Logic
        CASE
            WHEN UPPER(TRIM(CAST(zip AS STRING))) IN ('N/A', 'NA') THEN NULL
            WHEN UPPER(TRIM(CAST(zip AS STRING))) = 'ANONYMOUS' THEN 'Anonymous'
            WHEN LENGTH(CAST(zip AS STRING)) = 5 THEN CAST(zip AS STRING)
            WHEN LENGTH(CAST(zip AS STRING)) = 9 THEN CAST(zip AS STRING)
            WHEN LENGTH(CAST(zip AS STRING)) = 10
                AND REGEXP_CONTAINS(CAST(zip AS STRING), r'^\d{5}-\d{4}')
            THEN CAST(zip AS STRING)
            ELSE NULL
        END AS zip_code,

        -- Geospatial
        CAST(latitude AS NUMERIC) AS latitude,
        CAST(longitude AS NUMERIC) AS longitude,

        -- Operational Details
        UPPER(TRIM(CAST(approved_for_roadway_seating AS STRING))) AS approved_roadway,
        UPPER(TRIM(CAST(approved_for_sidewalk_seating AS STRING))) AS approved_sidewalk,
        CAST(qualify_alcohol AS STRING) AS alcohol_eligible,
        
        -- Dimensions (Casting to strings or floats depending on your analysis needs)
        CAST(roadway_dimensions_area AS STRING) AS roadway_area,
        CAST(sidewalk_dimensions_area AS STRING) AS sidewalk_area,

        -- Admin/Legal
        CAST(bbl AS STRING) AS bbl,
        CAST(bin AS STRING) AS bin,
        CAST(community_board AS STRING) AS community_board,
        CAST(council_district AS STRING) AS council_district,
        CAST(sla_license_type AS STRING) AS sla_license_type,
        CAST(sla_serial_number AS STRING) AS sla_serial_number,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source

    -- Filter to keep data within 7-year rolling window as per DOT case
    WHERE objectid IS NOT NULL 
    AND time_of_submission IS NOT NULL
    AND CAST(time_of_submission AS DATE) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 YEAR)

    -- Deduplicate on objectid
    QUALIFY ROW_NUMBER() OVER (PARTITION BY objectid ORDER BY time_of_submission DESC) = 1
)

SELECT * FROM renamed_and_cleaned