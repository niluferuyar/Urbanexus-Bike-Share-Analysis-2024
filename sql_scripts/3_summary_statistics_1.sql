-- =================================
-- STEP 8: SUMMARY STATISTICS - 1
-- =================================
/* 
This step calculates key summary statistics for travel distance, trip duration, and travel speed, grouped by rider type and rideable type. Includes:
- Min, Max, Median, Average
- Quartiles (using APPROX_QUANTILES)
- IQR (Interquartile Range) and boxplot whiskers
*/


CREATE TABLE `urbanexus.tripdata_final_summary_statistics` AS(
WITH temp_table AS(
 SELECT member_casual, rideable_type, travel_dist_m, travel_speed_kmph, trip_duration_min,


--Travel Distance
 PERCENTILE_CONT(travel_dist_m, 0.25) OVER (PARTITION BY member_casual, rideable_type) AS travel_dist_1st_quartile,
 PERCENTILE_CONT(travel_dist_m, 0.5) OVER (PARTITION BY member_casual, rideable_type) AS travel_dist_median,
 PERCENTILE_CONT(travel_dist_m, 0.75) OVER (PARTITION BY member_casual, rideable_type) AS travel_3rd_quartile,
--Travel Speed
 PERCENTILE_CONT(travel_speed_kmph,0.25) OVER(PARTITION BY member_casual, rideable_type) AS travel_speed_1st_quartile,
 PERCENTILE_CONT(travel_speed_kmph,0.5) OVER(PARTITION BY member_casual, rideable_type) AS travel_speed_median,
 PERCENTILE_CONT(travel_speed_kmph,0.75) OVER(PARTITION BY member_casual, rideable_type) AS travel_speed_3rd_quartile,


--Trip Duration
 PERCENTILE_CONT(trip_duration_min, 0.25) OVER (PARTITION BY member_casual, rideable_type) AS trip_dur_1st_quartile,
 PERCENTILE_CONT(trip_duration_min, 0.5) OVER (PARTITION BY member_casual, rideable_type) AS trip_dur_median,
 PERCENTILE_CONT(trip_duration_min, 0.75) OVER (PARTITION BY member_casual, rideable_type) AS trip_dur_3rd_quartile,
FROM `urbanexus.tripdata_final`
),


temp_table_stats AS(
 SELECT member_casual, rideable_type,


 --Travel Distance Stats
 MIN(travel_dist_m) AS min_travel_dist,
 ROUND(AVG(travel_dist_m),2) AS avg_travel_dist_m,
 MIN(travel_dist_1st_quartile) AS travel_dist_1st_quartile,
 MIN(travel_dist_median) AS travel_dist_median,
 MIN(travel_3rd_quartile) AS travel_dist_3rd_quartile,
 MAX(travel_dist_m) AS max_travel_dist,


 --Travel Speed Stats
 MIN(travel_speed_kmph) AS min_travel_speed,
 ROUND(AVG(travel_speed_kmph),0) AS avg_travel_speed_kmph,
 MIN(travel_speed_1st_quartile) AS travel_speed_1st_quartile,
 MIN(travel_speed_median) AS travel_speed_median,
 MIN(travel_speed_3rd_quartile) AS travel_speed_3rd_quartile,
 MAX(travel_speed_kmph) AS max_travel_speed,


 --Trip Duration Stats
 MIN (trip_duration_min) AS min_trip_dur,
 ROUND(AVG(trip_duration_min),2) AS avg_trip_dur_min,
 MIN(trip_dur_1st_quartile) AS trip_dur_1st_quartile,
 MIN(trip_dur_median) AS trip_dur_median,
 MIN(trip_dur_3rd_quartile) AS trip_dur_3rd_quartile,
 MAX(trip_duration_min) AS max_trip_dur
 FROM temp_table
 GROUP BY 1,2


),


temp_table_2 AS(
 SELECT *,
--Interquartile ranges
 travel_dist_3rd_quartile - travel_dist_1st_quartile AS dist_iqr,
 ROUND(trip_dur_3rd_quartile - trip_dur_1st_quartile, 2) AS dur_iqr,
 ROUND(travel_speed_3rd_quartile - travel_speed_1st_quartile,2) AS speed_iqr
 FROM temp_table_stats
)


SELECT *,
--Boxplot whiskers for outlier detection
 GREATEST(min_travel_dist, (travel_dist_1st_quartile - 1.5* dist_iqr)) AS travel_dist_l_whisker,
 travel_dist_3rd_quartile + 1.5* dist_iqr AS travel_dist_u_whisker,
 GREATEST(min_trip_dur, (trip_dur_1st_quartile- 1.5* dur_iqr)) AS trip_dur_l_whisker,
 ROUND(trip_dur_3rd_quartile + 1.5* dur_iqr,2) AS trip_dur_u_whisker,
 GREATEST(min_travel_speed, (travel_speed_1st_quartile - 1.5* speed_iqr)) AS travel_speed_l_whisker,
 travel_speed_3rd_quartile + 1.5* speed_iqr AS travel_speed_u_whisker
FROM temp_table_2
)

 
-- =============================
-- STEP 9: FILTERING OUTLIERS
-- =============================
/* Electric scooters were in use between August 31, 2024 and October 1st, 2024. Because of their short usage period, electric scooters were excluded from the analysis.
*/
/*
Filtered the final dataset further to isolate typical rider behavior.
Group-specific upper thresholds were applied based on previously calculated
whiskers (Q3 + 1.5 × IQR) for each ride and rideable type combination.
The following group-specific conditions were used:
- Annual Member + Classic Bike:
    - Trip duration ≤ 29.18 min
    - Travel distance ≤ 5,126 m
    - Travel speed < 18 km/h
- Annual Member + Electric Bike:
    - Trip duration ≤ 26.41 min
    - Travel distance ≤ 6,831.5 m
    - Travel speed < 27 km/h
- Casual Rider + Classic Bike:
    - Trip duration ≤ 41.02 min
    - Travel distance ≤ 5,993.5 m
    - Travel speed < 17 km/h
- Casual Rider + Electric Bike:
    - Trip duration ≤ 29.8 min
    - Travel distance ≤ 6,431 m
    - Travel speed < 26 km/h
Trips exceeding any of these thresholds were excluded.
The resulting table contains the core behavioral dataset for analysis which consists of 4,450,636 rows.
*/
/*
Between the previous steps, rider type and rideable type labels were updated for clarity:
- "member" → "Annual Member"
- "casual" → "Casual Rider"
- "classic_bike" → "Classic Bike"
- "electric_bike" → "Electric Bike"
These updated labels were used in summary statistics and filtering steps 
to improve readability in analysis and visualizations.
*/
CREATE TABLE `urbanexus.tripdata_final.coredata` AS (
   SELECT *
 FROM `urbanexus.tripdata_final`
 WHERE
   CASE
     WHEN member_casual = 'Annual Member' AND rideable_type = 'Classic Bike' AND (trip_duration_min <= 29.18 AND travel_dist_m <= 5126 AND travel_speed_kmph < 18) THEN TRUE
     WHEN member_casual = 'Annual Member' AND rideable_type = 'Electric Bike'  AND (trip_duration_min <= 26.41 AND travel_dist_m <= 6831.5 AND travel_speed_kmph < 27) THEN TRUE
     WHEN member_casual = 'Casual Rider' AND rideable_type = 'Classic Bike' AND (trip_duration_min <= 41.02 AND travel_dist_m <= 5993.5 AND travel_speed_kmph < 17) THEN TRUE
     WHEN member_casual = 'Casual Rider' AND rideable_type = 'Electric Bike' AND (trip_duration_min <= 29.8 AND travel_dist_m <= 6431 AND travel_speed_kmph < 26) THEN TRUE
   ELSE FALSE
   END
 )
