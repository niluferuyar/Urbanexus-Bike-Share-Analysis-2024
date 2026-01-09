# <img src="./images/Urbanexus_Logo_1.png" width="160" alt="Urbanexus logo" /> Urbanexus-Bike-Share-Analysis-2024 

**Tableau Public Story:** [Interactive dashboards](https://public.tableau.com/views/Urbanexus_Bike_Share_Analysis_2024/Story1?:language=en-GB&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)

URBANEXUS is a fictional bike-share company based in Chicago. This project explores rider preferences based on rideable type, season, day of week, time of day, and station-level demand grouped by urban area type (e.g. business, commercial, residential, etc.).

## Project Overview
In this project, the **2024 Divvy bike-share trip records** from Chicago—over **5 million** rows—were analyzed to understand rider behaviour and usage patterns. To enrich the trip data with spatial context and uncover insights about travel purpose, additional datasets were incorporated, including the **Chicago city map**, **bike station geolocations**, and **Chicago zoning classifications**.

The project enriches large-scale bike-share data with zoning and spatial insights to reveal deeper patterns of urban mobility while effectively managing big data challenges.

## Business Objectives
This analysis aims to support marketing strategies to convert casual riders into annual members by addressing the following:
- **Discover riders' trip purposes** by analyzing travel distance, duration, and speed.
- **Identify time-based preferences** of annual members and casual riders across months, weekdays, and times of day, segmented by rideable type.
- **Reveal deeper usage characteristics** by identifying station urban area types and analyzing station-level popularity.
- **Detect high-potential conversion moments** based on when and where casual riders behave similarly to annual members.
- **Provide data-driven insights** to support targeted promotions tailored to casual riders.

## Tools Used 🖥️ 🔍 
- BigQuery and SQL (for data cleaning and transformation)
- Tableau (data exploration, visualisations and interactive dashboards)
- GitHub (Project sharing)

## Data Sources ⛁ ⛃
- 12 months of 2024 Divvy Bikes trip data from Divvy Bikes website [Divvy Data](https://divvybikes.com/system-data).
- Stations geolocation data from City of [Chicago Data Portal](https://data.cityofchicago.org/Transportation/Divvy-Bicycle-Stations-Map/bk89-9dk7).
- Urban area type data from [Chicago Second City Zoning website](https://secondcityzoning.org/zones/).

## Project Structure
```text
Urbanexus/
│── sql_scripts/
│── sample_datasets/
│── tableau_dashboards/
│── images/
│── README.md
```

## Data Cleaning, Formatting, and Transformation 🧹✨
**Data cleaning**, **formatting** and **transformation** were performed in **BigQuery** using **SQL**. 

You can view the full SQL script used in this step [here](./sql_scripts/).

### Data Cleaning and Formatting
- Removed 211 duplicate rows.
- Aligned the format of timestamp fields and station coordinates:
  - Standardized timestamp fields to **ISO 8601 format** (YYYY-MM-DD hh-mm-ss).
  - Ensured latitude and longitude values were formatted consistently with uniform decimal precision (4 decimals). The following information was considered when determining appropriate coordinate precision:
    - **Coordinate Precision Guide**
      
        | Decimal Places | Approx. Accuracy           | Use Case                                 |
      |----------------|----------------------------|-------------------------------------------|
      | 2 decimals | ~1.1 km (0.7 mi)           | Rough city-level accuracy                 |
      | 3 decimals| ~110 m                     | neighbourhood or block-level               |
      | 4 decimals | ~11 m (about 1 car length) | Street-level accuracy (most common)       |
      | 5 decimals| ~1.1 m                     | Doorstep / bike rack level (ideal here)   |
      | 6+ decimals| < 0.1 m                    | Overkill unless doing GIS or surveying    |
      
- Cleaned station names to ensure consistency across all entries.
  - In many records, station names included the prefix “Public Rack” (e.g. "Public Rack - Western Ave & 104th St"), while the same stations also appeared without the prefix. The issue was resolved by removing the unnecessary prefix.
- Investigated null values in the start station, end station, and station ID columns.
    - Due to coordinate fluctuations ranging from several to dozens of meters, there was no reliable way to infer missing station names or IDs based solely on available location data.
    - As a result, these fields were excluded from the main statistical analysis dataset to ensure accuracy.
    - However, station name and ID fields were later reintroduced in a separate, derived dataset used for station popularity analysis.
    - Furthermore, there were 7,192 records with missing end station data (coordinates, station names and IDs). These were identified as incomplete or erroneous trips and excluded from analysis.
- The raw dataset contained **5,860,568 rows**.
- After cleaning **5,853,165 rows** remained for analysis.
    
### Data Transformation
- Derived new fields for:
    - **Travel distance**
    - **Trip duration**
    - **Travel speed**
- Identified 227 records with **negative trip duration**. These records were excluded.
    - After this step, **5,852,938 rows** remained in the dataset. 
- Extracted **month** and **day** information from the trip timestamp.
- Grouped trips into **2-hour time buckets** to analyse time-of-day patterns.
- **Anomalies** and **extreme values** were filtered out to ensure realistic and reliable trip data. To achieve this, rideable-type-specific thresholds were defined for:
	- **Minimum trip duration**
	- **Minimum travel distance**
	- **Expected travel speed ranges**
- If a trip’s calculated speed falls within these ranges, it is considered a **real commute** or **purposeful ride**. Trips outside these ranges may reflect **idle use**, **anomalous data**, or **extremes**, and were therefore excluded to prevent skewing the analysis.
- **Defined thresholds**:
	- **Minimum trip duration (all rideable types)**: 1 minute
	- **Minimum travel distance (all rideable types)**: 100 meters
- **Valid travel speed ranges**:
	- **Classic Bike**: 5–24 km/h
	- **Electric Bike**: 5–32 km/h
    - **Electric Scooter**: 5–24 km/h
- Following the removal of values falling outside the defined ranges, **4,950,253 rows** remained in the dataset.
  
### Summary Statistics/Removing Outliers
-  **Electric Scooter Exclusion:** Electric scooters were excluded from the analysis due to limited data availability and minimal contribution to rider usage patterns. The available trip data spans from **31 August 2024 to 1 October 2024**, representing a short observation window. As a result, **electric scooter trips (109,204 records)** were excluded from the analysis.
-  To better understand user behaviour and ride patterns, summary statistics were calculated for travel distance, trip duration, and travel speed, grouped by rider type and rideable type. These metrics include:
	- Minimum, average, and maximum values
	- Median and quartiles
	- Interquartile ranges (IQRs) to measure data spread
	- Boxplot whiskers calculated using Tukey’s method (1.5 × IQR above and below the 1st (OR min. value in our case) and 3rd quartiles) to identify potential outliers

- The calculated statistics were applied to remove outliers, allowing for a more accurate and focused analysis of typical user behaviour.
- Following the removal of outliers, the dataset was reduced to **4,450,636 rows for in-depth analysis**.

### Travel Purpose Inference

The trip dataset does not include an explicit travel-purpose label. To infer likely usage intent,**median travel speed**, **travel distance**, and **trip duration** were analysed by rider type and rideable type.

**Median travel speed** was used as the **primary indicator for dominant travel purpose**, based on the assumption that **higher median speeds** are more characteristic of **commute-oriented travel**, while **lower median speeds** are more characteristic of **leisure-oriented travel**.

**Median travel distance and trip duration** were treated as **secondary indicators**, providing insight into **non-dominant travel purpose**.
To enable consistent comparison across rider and rideable types, median values were grouped into relative categories (shortest → longest and slowest → fastest). These classifications represent relative behavioural tendencies rather than definitive trip purposes.

### Temporal Patterns
Trip demand shows clear temporal differences between annual members and casual riders across **seasonality**, **day of week**, and **time of day**.
	•	**Annual members** exhibit broader and more consistent demand throughout the year, with high usage from **May to October**, stronger **weekday demand**, and clear **morning and afternoon rush-hour peaks**, indicating **commute-oriented usage**.
	•	**Casual riders** concentrate their activity in the summer months (**June to August**), with higher demand on **weekends** and increased usage around **midday and early afternoon**, reflecting **leisure-focused** travel. However, commuting-related timing patterns are also observed among a subset of casual trips.

These temporal differences further support the distinction between commute-oriented usage among annual members and leisure-oriented usage among casual riders, while also highlighting conversion opportunities among commute-focused casual users.
  
### Deriving Station Popularity
- **Station visits:** To evaluate station popularity, station-related fields (trip ID, start/end station names, coordinates, and station IDs) were extracted from the trip data. Because many station names were missing and coordinate/ID inconsistencies prevented reliable matching, only trips with non-null start or end station names were included.
	- Station popularity was measured by visit frequency, counting every start or end as one visit.
	- This produced 7,396,066 total station-visit records, which will be referred as station popularity data.

- **Active stations:** The latest Divvy station dataset was downloaded from the [Chicago Data Portal](https://data.cityofchicago.org/Transportation/Divvy-Bicycle-Stations-Map/bk89-9dk7) on 3 August 2025, listing **1,078 active stations**.
	- At the time of download (**3 August 2025**), the dataset listed **1,078 active bike stations** across Chicago.
	- Six locations had duplicate station names—two stations on opposite sides of the road, each with its own ID and coordinates. Since the station popularity data relied on distinct station names, each pair was merged, reducing 12 stations to 6.
	- The final cleaned station list contained **1,072 stations**.
	- On the other hand, the station popularity data included **1,017 of these stations**. Since the analysis is based on 2024 data, this difference between the 2025 and 2024 active-station counts is acceptable.

- **Chicago community areas**: Chicago is divided into 77 community areas. The list of the areas were downloaded from [Chicago Data Portal](https://data.cityofchicago.org/Facilities-Geographic-Boundaries/Boundaries-Community-Areas-Map/cauq-8yn6). Some stations were located outside the official community area boundaries, so their community area was recorded as “unassigned” in the table. 
  
- **Chicago area types**: Urban area type information was downloaded from [Chicago Second City Zoning website](https://secondcityzoning.org/zones/). For this project, **six urban area types** were derived from the original Chicago zoning classes to create a more meaningful categorization that aligns with the analysis. Here are the six urban area types:
  | Urban Area Type | Description |
  |-----------------|-------------|
  | Business/Commercial | Downtown business districts, major retail corridors, office complexes, and manufacturing zones |
  | Residential/Commercial | Mixed-use corridors combining housing with small retail, restaurants, and services |
  | Leisure/Recreation | Parks, beaches, lakefront trails, museums, and entertainment districts |
  | Residential | Low- to medium-density housing districts |
  | Transportation | Major rail terminals, bus depots, and intermodal transit areas |
  | Institutional | Universities, hospitals, schools, and civic/government campuses |

- **Station popularity with community area and urban area type granularity**: Each station was first assigned to a Chicago community area based on its geographic coordinates. Google Maps and local spatial context were then used to evaluate the station’s surrounding urban environment. However, assigning a single dominant urban area type to an entire community area is not always precise, as many community areas cover large areas and contain multiple urban functions. For this reason, the urban area type of each station was evaluated individually, rather than assuming the community area’s dominant type. For example, some stations located in a predominantly residential community area were classified as residential/commercial due to their proximity to major commercial corridors.
## Dataset Versions and Descriptions 🗂️ ✎𓂃
- Sample datasets can be found [here](./sample_datasets/).

  | Version       | Filename                   | Description                                  |
  |---------------|----------------------------|----------------------------------------------|
  | Raw Data   | `urbanexus_raw_sample.csv` | Unaltered 50-row sample from original data   |
  | Cleaned    | `urbanexus_cleaned_sample.csv` | Cleaned and formatted             |
  | Core Data  | `urbanexus_core_sample.csv`    | Transformed, filtered and outliers removed with IQR thresholds |
  | Raw Stations| `urbanexus_raw_stations.csv` | Original Divvy station data downloaded on 03 August 2025 |
  | Station&nbsp;Pairs| `urbanexus_station_pairs.csv` | Merged station pairs located on opposite sides of the same road |
  | Cleaned&nbsp;Stations | `urbanexus_stations.csv` | Final station list after merging pairs |
  | Main&nbsp;Stations | `urbanexus_station_popularity_sample.csv` | Sample of station-level visit counts combining trip, station, community area, and urban area type information  |

## Transformed Attributes and Derived Fields
### Derived Fields
- **Travel Distance** (m)
- **Trip Duration** (min)
- **Travel Speed** (km/h)
- **Month**
- **Day of Week**
- **Time-of-Day Buckets** (2-hour intervals)
### Temporal Features 
Time-based categorizations derived from calculated or extracted fields.
- **Seasonal Buckets of Months** (High, Medium-High, Medium-Low, Low)
- **Weekday Popularity Buckets** (High, Medium-High, Medium-Low, Low)
- **Time-of Day Popularity Buckets** (Peak, Busy Hours, Moderate Hours, Off-Peak)
### Categorized Fields
- **Rider Type** (annual members, casual riders)
- **Rideable Type** (classic bike, electric bike, electric scooter)
- **Station Area Type** (Business/Commercial, Institutional, Leisure/Recreational, Residential, Residential/Commercial, Transportation)
- **Station Popularity Groups** (Top, High, Moderate, Low)

## Key Insight and Findings
- **Key Insight 1: Travel Purpose** (Commute vs Leisure)
  
  Based on travel distance, speed, and duration summary statistics, **annual members predominantly use bikes for commuting**, while **casual riders tend to use them for leisure**.
  More specifically, the likely purpose of travel is:
  
  |               | Annual Members       | Casual Riders     |
  |---------------|----------------------|-------------------|
  | Classic Bike  | commuting/leisure    |   leisure         |
  | Electric Bike | commuting       |   commuting / leisure  |
  
  This indicates that annual members use bike-share as part of their daily mobility, whereas casual riders use it more for recreational or occasional trips.

- **Key Insight 2: Seasonality and Time Patterns**
  
  Annual members demonstrate broader seasonal and weekday demand patterns, while casual riders concentrate their usage in summer months and weekends. In more detail:
  
  |               | Annual Members                                                                 | Casual Riders                                        |
  |---------------|--------------------------------------------------------------------------------|------------------------------------------------------|
  | High season   | May to October                                                                | June to August                                       |
  | Popular&nbsp;days  | Weekdays                                                                      | Weekends and Fridays                                 |
  | Peak&nbsp;hours    | 4–6 pm (afternoon rush hour)                                                  | 4–6 pm (afternoon rush hour)                         |
  | Busy&nbsp;hours    | 8–10 am (morning rush hour); <br> 12–4 pm (midday trips);<br> 6–8 pm (evening commute) | 12–4 pm (midday trips);<br> 6–8 pm (evening commute) |

  Demand from annual members peaks during morning and afternoon rush hours, which further supports their commute-oriented usage, while casual riders show a more leisure-oriented,
  weekend-heavy pattern. 

- **Key Insight 3: Station Demand by Urban Area Type**
  
  For **annual members**, station demand is highly concentrated in **business/commercial** areas, followed by **residential/commercial** areas and, thirdly, stations located near major **transportation links**. This pattern supports the interpretation that annual members primarily use bike-share for **daily commuting**. In addition, top station demand around **institutional** areas points to the popularity of annual membership among students.
  
  For **casual riders**, the highest demand is in **business/commercial** areas, followed by **leisure/recreational** and **residential/commercial** areas. This suggests a mix of **commute-oriented** trips in business, commercial, and residential-commercial districts, and **leisure-oriented** usage around parks and recreational destinations. When we evaluate **top and high-demand stations** for casual riders, usage around **transport hubs** and **institutional areas** also becomes noticeable, highlighting an opportunity to convert more of these casual riders into annual members.
  
## Recommendations
- **From Insights 1 & 2: Travel Purpose, Seasonality and Time Patterns**

  Casual riders can be split into two behavioural segments: **commute-focused** and **leisure-focused**. To convert more of these riders into members:

- **Introducing short-term memberships** (e.g. monthly or 3-month options) targeted at commute-focused casual riders who are not ready to commit to a full year but travel regularly.
- Furthermore, offering **daily and weekly passes** that leverage high season and weekend demand, and using these as a stepping stone toward longer membership options.
    
  **From Insights 3: Station Demand by Urban Area Type**

  Popular stations’ urban area types and neighbourhood information can be used to design **user-group- and location-specific campaigns**. 
  In particular, stations around **Transportation Hubs** and **Institutional areas** carry **significant potential** for converting casual riders into members.
  
## Dashboards

- **Tableau Public:** [Interactive dashboards](https://public.tableau.com/views/Urbanexus_Bike_Share_Analysis_2024/Story1?:language=en-GB&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)
- **Dashboard screenshots:** See the [dashboards](./dashboards/) folder for selected screenshots and brief descriptions. 

## Limitations and Assumptions
- **Data Scope**

This analysis was based on **Chicago Divvy bike-share data from 2024**.
  
- **Trip Purpose Inference**

Travel purpose (commute vs leisure) was inferred using trip distance, duration, and speed, and was further supported by temporal patterns. Rider intent was not directly available in the dataset.
  
- **Spatial Data & Station Popularity**

Station popularity analysis included only trips with available start and/or end station names. Trips with missing station names were excluded due to incomplete station IDs and variability in recorded trip start and end coordinates. To maximise spatial coverage, demand was calculated using both start and end stations.
  
- **Community Areas & Urban Area Type Classification**

Each bike station was assigned to a Chicago community area using its geographic coordinates. Urban area type classification was derived from Chicago Second City Zoning and assigned according to the dominant surrounding land use in which the station was located. Classifications should be interpreted as approximate, particularly in mixed-use environments.

- **Data Cleaning Assumptions**

Minimum thresholds were applied to remove anomalous trips (e.g. implausible values for travel distance, duration, and speed). While this improved overall data quality, some valid edge-case trips may have been excluded.

## Future Enhancements

- **Demographic enrichment:** Incorporate demographic information (e.g. age groups, socioeconomic indicators) to support more targeted user-type campaigns and to add an additional layer of context to the urban area type analysis.
