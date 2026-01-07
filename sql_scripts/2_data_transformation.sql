-- ==================================
-- STEP 6:  CALCULATING NEW FIELDS
-- ==================================
-- Add a new column to store travel distance in meters.
-- Calculate as the crow flies distance between trip start and end points using geographical coordinates.
ALTER TABLE `urbanexus.tripdata_2`
ADD COLUMN travel_dist_m INT64;

UPDATE `urbanexus.tripdata_2`
  SET travel_dist_m = CAST(ROUND(ST_DISTANCE(ST_GEOGPOINT(s_lng,s_lat), ST_GEOGPOINT(e_lng, e_lat)),0) AS INT64)
  WHERE TRUE;

-- Add a new column to store trip duration in minutes with two-decimal precision.
-- Calculated as the time difference between trip start and end timestamps
ALTER TABLE `urbanexus.tripdata_2`
ADD COLUMN trip_duration_min FLOAT64;

UPDATE `urbanexus.tripdata_2` AS td
  SET trip_duration_min = new_duration
  FROM (
    SELECT ride_id,
    ROUND(DATETIME_DIFF(ended_at, started_at, SECOND)/60, 2) AS new_duration
    FROM `urbanexus.tripdata_2`
      ) AS nd
  WHERE td.ride_id = nd.ride_id;

-- Identified 227 records with negative trip durations. These records were excluded from the dataset.
CREATE TABLE `urbanexus.tripdata_3` AS(
  SELECT *
  FROM `urbanexus.tripdata_2`
  WHERE trip_duration_min >= 0
);

-- Calculated travel speed (in km/h) and stored it in a new column,
-- based on travel distance and trip duration.
ALTER TABLE `urbanexus.tripdata_3`
ADD COLUMN travel_speed_kmph FLOAT64;

UPDATE `urbanexus.tripdata_3`
SET travel_speed_kmph=
 CASE
   WHEN trip_duration_min=0 THEN NULL
   ELSE ROUND((travel_dist_m/trip_duration_min)*0.06, 1)
 END
WHERE TRUE;

-- Extract trip month and day of week information from trip start timestamp.
-- and stored in new columns.
ALTER TABLE `urbanexus.tripdata_3`
ADD COLUMN month STRING,
ADD COLUMN day_of_week STRING;

UPDATE `urbanexus.tripdata_3`
SET month = FORMAT_DATETIME('%B', started_at)
WHERE TRUE;

UPDATE `urbanexus.tripdata_3`
SET day_of_week = FORMAT_DATETIME('%A', started_at)
WHERE TRUE;

-- Group trips into 2-hour time buckets based on trip start timestamp.
ALTER TABLE `urbanexus.tripdata_3`
ADD COLUMN hour_bucket STRING;

UPDATE `urbanexus.tripdata_3`
SET hour_bucket = FORMAT('%02d:00 - %02d:59',2 * CAST(FLOOR(EXTRACT(HOUR FROM started_at)/2) AS INT64), 2 * CAST(FLOOR(EXTRACT(HOUR FROM started_at)/2) AS INT64) +1)
WHERE TRUE;

-- ==========================================
-- STEP 7: FILTERING ANOMALIES AND EXTREMES
-- ==========================================
/*
Filtered out anomalies and extreme values by applying the following thresholds:
- Minimum trip duration: 1 minute
- Minimum travel distance: 100 meters
- Valid travel speed ranges per rideable type:
    - Classic Bike: 5–24 km/h
    - Electric Bike: 5–32 km/h
    - Electric Scooter: 5–24 km/h
Trips not meeting these criteria were excluded from the final dataset.
*/
CREATE TABLE urbanexus.tripdata_final AS(
 SELECT *
 FROM `urbanexus.tripdata_3`
 WHERE travel_speed_kmph>= 5   
   AND (
   (rideable_type ='electric_bike' AND travel_speed_kmph <= 32) 
     OR
     ((rideable_type = 'classic_bike' OR rideable_type = 'electric_scooter') AND travel_speed_kmph <= 24)
   ) AND trip_duration_min >=1 AND travel_dist_m >=100
