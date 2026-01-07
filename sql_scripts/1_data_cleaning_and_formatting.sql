-- ===================================================
-- STEP 1: REMOVING DUPLICATE ROWS BASED ON RIDE ID
-- ===================================================


CREATE TABLE `urbanexus.tripdata_1` AS(
 SELECT *
 FROM(
   SELECT *,
     ROW_NUMBER() OVER(PARTITION BY ride_id ORDER BY ride_id) AS rn
   FROM `divvy_raw_data`
 )
 WHERE rn=1)


-- ==========================================================================
-- STEP 2: ALIGNING THE FORMAT OF TIMESTAMP FIELDS AND STATION COORDINATES
-- ==========================================================================


-- Truncate timestamps to remove microseconds
UPDATE `urbanexus.tripdata_1`
SET started_at = TIMESTAMP_TRUNC(started_at, second),
 ended_at = TIMESTAMP_TRUNC(ended_at, second)
WHERE started_at IS NOT NULL;


-- Add cleaned coordinate columns
ALTER TABLE `urbanexus.tripdata_1`
ADD COLUMN s_lat FLOAT64,
ADD COLUMN s_lng FLOAT64,
ADD COLUMN e_lat FLOAT64,
ADD COLUMN e_lng FLOAT64;


-- Round coordinates to 4 decimal places (street-level precision)
UPDATE `urbanexus.tripdata_1`
SET
 s_lat = ROUND(start_lat,4),
 s_lng = ROUND(start_lng,4),
 e_lat = ROUND(end_lat,4),
 e_lng = ROUND(end_lng,4)
WHERE start_lat IS NOT NULL;


-- =================================
-- STEP 3: CLEANING STATION NAMES
-- =================================


-- Add new columns to store cleaned station names
ALTER TABLE `urbanexus.tripdata_1`
ADD COLUMN cleaned_ss_name STRING,
ADD COLUMN cleaned_es_name STRING;


-- Clean station name prefixes using case-insensitive REGEXP
UPDATE `urbanexus.tripdata_1`
SET
 cleaned_ss_name = REGEXP_REPLACE(start_station_name, r'(?i)^public rack\s*-\s*', ''),
 cleaned_es_name = REGEXP_REPLACE(end_station_name, r'(?i)^public rack\s*-\s*', '')
WHERE TRUE;


-- =======================================================================
-- STEP 4: INVESTIGATING NULL VALUES IN START/END STATION NAMES AND IDS
-- =======================================================================


SELECT
-- Start station fields (547,596 records)
  SUM(CASE WHEN start_station_name IS NULL THEN 1 ELSE 0 END) AS ssn_null,
  SUM(CASE WHEN start_station_id IS NULL THEN 1 ELSE 0 END) AS ssid_null,


-- End station fields (578,241 records)
  SUM(CASE WHEN end_station_name IS NULL THEN 1 ELSE 0 END) AS esn_null,
  SUM(CASE WHEN end_station_id IS NULL THEN 1 ELSE 0 END) AS esid_null,


-- All 4 fields missing (526,332 records)
  SUM(CASE WHEN start_station_name IS NULL AND start_station_id IS NULL AND end_station_name IS NULL AND end_station_id IS NULL THEN 1 ELSE 0 END) AS all_null
FROM `urbanexus.tripdata_1`;


-- NOTE:
-- Due to coordinate fluctuations, missing station names/IDs could not be reliably completed.
-- Affected rows were excluded from the statistical dataset but retained for location-based analyses.


-- ==================================================================
-- STEP 5:  EXCLUDING RECORDS WITH MISSING END STATION COORDINATES
-- ==================================================================
-- Creates a new table excluding records with null values in end station latitude or longitude.
-- These records (7,192) were determined to be incomplete or erroneous trips.
CREATE TABLE `urbanexus.tripdata_2` AS(
  SELECT *
  FROM `urbanexus.tripdata_1`
  WHERE e_lat IS NOT NULL AND e_lng IS NOT NULL  
)
