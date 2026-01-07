-- =======================================
-- STEP 10: URBANEXUS STATIONS POPULARITY
-- =======================================
/* Station names brought back from the previous versions of core data.*/

CREATE TABLE urbanexus.tripdata_final.coredata_stations AS(
   SELECT f.ride_id,f.member_casual,    
     s.start_station_id,s.cleaned_ss_name,
     s.end_station_id,s.cleaned_es_name
   FROM `urbanexus.tripdata_final.coredata` AS f
   LEFT JOIN `urbanexus.tripdata_2` AS s
     ON f.ride_id = s.ride_id
   WHERE s.cleaned_es_name IS NOT NULL 
      OR s.cleaned_ss_name IS NOT NULL
  ); 

/* Station popularity was evaluated by visit frequency (start + end stations both count). This produced 7,396,066 station records linked to 4,231,272 unique trips. 322,875 trips had null vales in station name fields. */

CREATE TABLE `urbanexus.stations.popularity` AS(
/* start stations*/
WITH stations_1 AS(
SELECT ride_id,member_casual,cleaned_ss_name AS cleaned_station_name, "Start" as station
FROM
 `urbanexus.tripdata_final.coredata_stations`
WHERE cleaned_ss_name IS NOT NULL),

/* end stations*/
stations_2 AS(
SELECT ride_id, member_casual,cleaned_es_name AS cleaned_station_name, "End" as station
FROM
 `urbanexus.tripdata_final.coredata_stations`
WHERE cleaned_es_name IS NOT NULL)

SELECT *
FROM stations_1
UNION ALL
SELECT *
FROM stations_2
);

-- ===========================================
-- STEP 11: URBANEXUS STATIONS ACROSS CHICAGO
-- ===========================================
/* 
Current active Divvy station data were downloaded from the City of Chicago Data Portal. 
As of August 3, 2025, the dataset listed 1,078 active stations. 
At six locations, two stations shared the same name but were placed on opposite sides of the road, each with a different ID and coordinates. 
Because our stations popularity table references stations primarily by name, we merged each opposite-side pair into a single station to avoid double-counting.
Therefore, final stations table contained data of 1072 stations.
*/

CREATE TABLE `urbanexus.stations`AS(
 WITH divvy_stations AS (
  SELECT *,
  ROW_NUMBER() OVER (PARTITION BY `Station Name` ORDER BY ID) AS rn
  FROM `urbanexus.Divvy_Bicycle_Stations`
 ) 
 SELECT * EXCEPT(rn)
 FROM divvy_stations
 WHERE rn = 1
)

/*
Station pairs were identified: at six locations, the same station name appeared twice
(on opposite sides of the road) with distinct station IDs and coordinates.
*/
 
WITH stations AS (
  SELECT
    `Station Name`, ID,
    ROW_NUMBER() OVER (PARTITION BY `Station Name` ORDER BY ID) AS rn
  FROM `urbanexus.Divvy_Bicycle_Stations`
),
station_pairs AS (
  SELECT DISTINCT `Station Name`
  FROM stations
  WHERE rn > 1
)
SELECT *
FROM `urbanexus.Divvy_Bicycle_Stations`
WHERE `Station Name` IN (SELECT `Station Name` FROM station_pairs)
ORDER BY `Station Name`, ID;
