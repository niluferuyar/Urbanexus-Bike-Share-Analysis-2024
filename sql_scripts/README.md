## SQL Scripts – Urbanexus Bike Share Project

This folder contains all SQL scripts used in data cleaning, foramtting and transformation **+ STH** for the Urbanexus Bike Share 2024 project.

### Script Overview

| Filename | Description |
|------|-------------|
| `1_data_cleaning_and_formatting.sql` | Removes duplicates, formats timestamps and station names, handles null values, and aligns coordinate fields. |
| `2_data_transformation.sql` | Calculates travel distance, trip duration, and speed; extracts time-based features such as month, day of week, and 2-hour time buckets; and filters out anomalies and extreme values based on ride-type-specific thresholds. |
| `3_summary_statistics_1.sql` | Calculates summary statistics ( min, max, average, median, quartiles, IQR, boxplot whiskers) for travel distance, trip duration, and travel speed variables. Then filters out outliers using group-specific upper-whisker thresholds, creating a refined core dataset for analysis. |

Each script was executed in **Google BigQuery**, and the resulting datasets was used for visualisations in **Tableau**.

[Back to main project README](../README.md)
