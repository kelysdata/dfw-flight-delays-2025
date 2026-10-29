SELECT
   YEAR,
   MONTH,
   COUNT(*) AS total_flights
FROM flights_raw
GROUP BY YEAR, MONTH;

PRAGMA table_info(flights_raw);

SELECT name, type
FROM pragma_table_info('flights_raw');

SELECT
   YEAR,
   MONTH,
   ORIGIN,
   COUNT(*) AS total_flights
FROM flights_raw
WHERE ORIGIN = 'DFW'
GROUP BY YEAR, MONTH, ORIGIN;

SELECT
   DEP_DELAY,
   ARR_DELAY,
   CANCELLED,
   DIVERTED
FROM flights_raw
WHERE ORIGIN = 'DFW'
LIMIT 20;

SELECT
   DEP_DELAY,
   COUNT(*) AS total
FROM flights_raw
WHERE ORIGIN = 'DFW'
GROUP BY DEP_DELAY
ORDER BY total DESC
LIMIT 15;

SELECT
   CANCELLED,
   COUNT(*) AS total_flights,
   SUM(
      CASE WHEN DEP_DELAY IS NULL THEN 1 ELSE 0 END
   ) AS missing_dep_delay
FROM flights_raw
WHERE ORIGIN = 'DFW'
GROUP BY CANCELLED;

SELECT
   DEP_DELAY AS 	original_delay,
   CAST(
      NULLIF(TRIM(DEP_DELAY), '') AS REAL
   ) AS numeric_delay
FROM flights_raw
WHERE ORIGIN = 'DFW'
LIMIT 20;

CREATE VIEW dfw_flights AS
SELECT
   *,
   CAST(NULLIF(TRIM(DEP_DELAY), '') AS REAL)
      AS dep_delay_num,
   CAST(NULLIF(TRIM(ARR_DELAY), '') AS REAL)
      AS arr_delay_num
FROM flights_raw
WHERE ORIGIN = 'DFW';

SELECT
   COUNT(*) AS total_flights,
   COUNT(dep_delay_num) AS with_departure_delay
FROM dfw_flights;

SELECT
   COUNT(*) AS scheduled_flights,
   SUM(CANCELLED) AS cancelled_flights,
   ROUND(
      100.0 * SUM(CANCELLED) / COUNT(*),
	  2
   ) AS cancellation_rate_pct
FROM dfw_flights;

SELECT
   CANCELLATION_CODE,
   COUNT(*) AS cancelled_flights
FROM dfw_flights
WHERE CANCELLED = 1
GROUP BY CANCELLATION_CODE
ORDER BY cancelled_flights DESC;

SELECT
   CASE CANCELLATION_CODE
      WHEN 'A' THEN 'Air Carrier'
	  WHEN 'B' THEN 'Weather'
	  WHEN 'C' THEN 'National Aviation System'
	  WHEN 'D' THEN 'Security'
	  ELSE 'Unknown'
   END AS cancellation_reason,
   COUNT(*) AS cancelled_flights
FROM dfw_flights	
WHERE CANCELLED = 1
GROUP BY CANCELLATION_CODE
ORDER BY cancelled_flights DESC;

SELECT
   COUNT(*) AS flights_with_data,
   SUM(
      CASE WHEN dep_delay_num >= 15 THEN 1 ELSE 0 END
   ) AS delayed_departures,
   ROUND(
      100.0 * SUM(
	     CASE WHEN dep_delay_num >= 15 THEN 1 ELSE 0 END
	  ) / COUNT(*),
	  2
   ) AS departure_delay_rate_pct
FROM dfw_flights
WHERE CANCELLED = 0
   AND dep_delay_num IS NOT NULL; 
   
SELECT
   OP_UNIQUE_CARRIER AS airline,
   COUNT(*) AS flights_with_data,
   SUM(
      CASE WHEN dep_delay_num >= 15 THEN 1 ELSE 0 END
   ) AS delayed_departures,
   ROUND(
      100.0 * SUM(
	     CASE WHEN dep_delay_num >= 15 THEN 1 ELSE 0 END
      ) / COUNT(*),
	  2
   ) AS departure_delay_rate_pct
FROM dfw_flights
WHERE CANCELLED = 0
   AND dep_delay_num IS NOT NULL
GROUP BY OP_UNIQUE_CARRIER
ORDER BY departure_delay_rate_pct DESC;

SELECT
   COUNT(*) AS flights_with_arrival_data,
   SUM(
      CASE WHEN arr_delay_num >= 15 THEN 1 ELSE 0 END 
   ) AS delayed_arrivals,
   ROUND(
      100.0 * SUM(
	     CASE WHEN arr_delay_num >= 15 THEN 1 ELSE 0 END
      ) / COUNT(*),
	  2
   ) AS arrival_delay_rate_pct
FROM dfw_flights
WHERE CANCELLED = 0
   AND DIVERTED = 0
   AND arr_delay_num IS NOT NULL;
   
SELECT
   COUNT(*) AS delayed_departures,
   SUM(
      CASE WHEN arr_delay_num < 15 THEN 1 ELSE 0 END
   ) AS arrived_under_15_min_late,
   ROUND(
      100.0 * SUM(
	     CASE WHEN arr_delay_num < 15 THEN 1 ELSE 0 END
      ) / COUNT(*),
	  2
   ) AS recovery_rate_pct
FROM dfw_flights
WHERE CANCELLED = 0
   AND DIVERTED = 0
   AND dep_delay_num >= 15
   AND arr_delay_num IS NOT NULL;
   
SELECT
   COUNT(*) AS non_cancelled_flights,
   SUM(
      CASE WHEN DIVERTED = 1 THEN 1 ELSE 0 END
   ) AS diverted_flights,
   SUM(
      CASE WHEN arr_delay_num IS NULL THEN 1 ELSE 0 END
   ) AS missing_arrival_delay
FROM dfw_flights
WHERE CANCELLED = 0;

SELECT
   DIVERTED,
   COUNT(*) AS total_flights,
   SUM(
      CASE WHEN arr_delay_num IS NULL THEN 1 ELSE 0 END
   ) AS missing_arrival_delay
FROM dfw_flights
WHERE CANCELLED = 0
GROUP BY DIVERTED;

SELECT 
   COUNT(*) AS delayed_departures,
   ROUND(AVG(dep_delay_num), 2) AS avg_delay_minutes,
   MAX(dep_delay_num) AS max_delay_minutes
FROM dfw_flights
WHERE CANCELLED = 0
   AND dep_delay_num >= 15;
   
SELECT
   FL_DATE,
   OP_UNIQUE_CARRIER,
   OP_CARRIER_FL_NUM,
   DEST,
   dep_delay_num,
   arr_delay_num,
   DIVERTED
FROM dfw_flights
WHERE CANCELLED = 0
ORDER BY dep_delay_num DESC
LIMIT 5;

WITH ranked_delays AS (
   SELECT
      dep_delay_num,
	  row_number() OVER (
	     ORDER BY dep_delay_num
      ) AS position,
	  COUNT(*) OVER () AS total
   FROM dfw_flights
   WHERE CANCELLED = 0
      AND dep_delay_num >= 15
)
SELECT
   AVG(dep_delay_num) AS median_delay_minutes
FROM ranked_delays
WHERE position IN(
   (total + 1) / 2,
   (total + 2) / 2
);

SELECT 'January' AS source, cid, name
FROM pragma_table_info('flights_raw')

UNION ALL

SELECT 'February' AS source, cid, name
FROM pragma_table_info('flights_feb_check')

ORDER BY cid, source;

SELECT name AS misssing_in_february
FROM pragma_table_info('flights_raw')

SELECT COUNT(*) AS column_count
FROM pragma_table_info('flights_feb_complete');

SELECT COUNT(*) AS column_count
FROM pragma_table_info('flights_feb_corrected');

SELECT COUNT(*) AS column_count
FROM pragma_table_info('flights_2025_02_verified');

SELECT cid, name
FROM pragma_table_info('flights_raw')
EXCEPT
SELECT cid, name
FROM pragma_table_info('flights_2025_02_verified');

SELECT
   'Current database' AS source,
   YEAR,
   MONTH,
   COUNT(*) AS total_flights
FROM flights_raw
GROUP BY YEAR, MONTH
UNION ALL
SELECT
   'Februeary file' AS source,
   YEAR,
   MONTH,
   COUNT(*) AS total_flights
FROM flights_2025_02_verified
GROUP BY YEAR, MONTH;

INSERT INTO flights_raw
SELECT *
FROM flights_2025_02_verified
WHERE YEAR = 2025
   AND MONTH = 2
   AND NOT EXISTS (
      SELECT 1
	  FROM flights_raw
	  WHERE YEAR = 2025 AND MONTH = 2
   );
   
SELECT YEAR, MONTH, COUNT(*) AS total_flights
FROM flights_raw
GROUP BY YEAR, MONTH
ORDER BY YEAR, MONTH;

SELECT
   YEAR,
   MONTH,
   COUNT(*) AS scheduled_flights,
   SUM(CANCELLED) AS cancelled_flights,
   ROUND(
      100.0 * SUM(CANCELLED) / COUNT(*),
	  2
   ) AS cancellation_rate_pct
FROM dfw_flights
GROUP BY YEAR, MONTH
ORDER BY YEAR, MONTH;

SELECT COUNT(*) AS column_count
FROM pragma_table_info('flights_2025_03_check');

SELECT cid, name
FROM pragma_table_info('flights_raw')
EXCEPT
SELECT cid, name
FROM pragma_table_info('flights_2025_03_check');

SELECT YEAR, MONTH, COUNT(*) AS total_flights
FROM flights_2025_03_check
GROUP BY YEAR, MONTH;

INSERT INTO flights_raw
SELECT *
FROM flights_2025_03_check
WHERE YEAR = 2025
   AND MONTH = 3
   AND NOT EXISTS (
      SELECT 1
	  FROM flights_raw
	  WHERE YEAR = 2025 AND MONTH = 3
   );

SELECT YEAR, MONTH, COUNT(*) AS total_flights
FROM flights_raw
GROUP BY YEAR, MONTH
ORDER BY YEAR, MONTH;

SELECT
   YEAR,
   MONTH,
   COUNT(*) AS scheduled_flights,
   SUM(CANCELLED) AS cancelled_flights,
   ROUND(
      100.0 * SUM(CANCELLED) / COUNT(*),
	  2
   ) AS cancellation_rate_pct
FROM dfw_flights
GROUP BY YEAR, MONTH
ORDER BY YEAR, MONTH;

SELECT COUNT(*) AS column_count
FROM pragma_table_info('flights_2025_04_check');

SELECT COUNT(*) AS column_count
FROM pragma_table_info('flights_2025_04_verified');

SELECT cid, name
FROM pragma_table_info('flights_raw')
EXCEPT
SELECT cid, name
FROM pragma_table_info('flights_2025_04_verified');

SELECT YEAR, MONTH, COUNT(*) AS total_flights
FROM flights_2025_04_verified
GROUP BY YEAR, MONTH;

INSERT INTO flights_raw
SELECT *
FROM flights_2025_04_verified
WHERE YEAR = 2025
   AND MONTH = 4
   AND NOT EXISTS (
      SELECT 1
	  FROM flights_raw
	  WHERE YEAR = 2025 AND MONTH = 4
   );
   
SELECT YEAR, MONTH, COUNT(*) AS total_flights
FROM flights_raw
GROUP BY YEAR, MONTH
ORDER BY YEAR, MONTH;

SELECT
   YEAR,
   MONTH,
   COUNT(*) AS scheduled_flights,
   SUM(CANCELLED) AS cancelled_flights,
   ROUND(
      100.0 * SUM(CANCELLED) / COUNT(*),
	  2
   ) AS cancellation_rate_pct
FROM dfw_flights
GROUP BY YEAR, MONTH
ORDER BY YEAR, MONTH;

SELECT COUNT(*) AS column_count
FROM pragma_table_info('flights_2025_05_check');

SELECT cid, name
FROM pragma_table_info('flights_raw')
EXCEPT
SELECT cid, name
FROM pragma_table_info('flights_2025_05_check');

SELECT YEAR, MONTH, COUNT(*) AS total_flights
FROM flights_2025_05_check
GROUP BY YEAR, MONTH;

INSERT INTO flights_raw
SELECT *
FROM flights_2025_05_check
WHERE YEAR = 2025
   AND MONTH = 5
   AND NOT EXISTS (
      SELECT 1
	  FROM flights_raw
	  WHERE YEAR = 2025 AND MONTH = 5
   );

SELECT YEAR, MONTH, COUNT(*) AS total_flights
FROM flights_raw
GROUP BY YEAR, MONTH
ORDER BY YEAR, MONTH;

SELECT
   YEAR,
   MONTH,
   COUNT(*) AS scheduled_flights,
   SUM(CANCELLED) AS cancelled_flights,
   ROUND(
      100.0 * SUM(CANCELLED) / COUNT(*),
	  2
   ) AS cancellation_rate_pct
FROM dfw_flights
GROUP BY YEAR, MONTH
ORDER BY YEAR, MONTH;

SELECT COUNT(*) AS column_count
FROM pragma_table_info('flights_2025_06_check');

SELECT cid, name
FROM pragma_table_info('flights_raw')
EXCEPT
SELECT cid, name
FROM pragma_table_info('flights_2025_06_check');

SELECT YEAR, MONTH, COUNT(*) AS total_flights
FROM flights_2025_06_check
GROUP BY YEAR, MONTH;

INSERT INTO flights_raw
SELECT *
FROM flights_2025_06_check
WHERE YEAR = 2025
   AND MONTH = 6
   AND NOT EXISTS (
      SELECT 1
	  FROM flights_raw
	  WHERE YEAR = 2025 AND MONTH = 6
   );

SELECT YEAR, MONTH, COUNT(*) AS total_flights
FROM flights_raw
GROUP BY YEAR, MONTH
ORDER BY YEAR, MONTH;   

SELECT
   YEAR,
   MONTH,
   COUNT(*) AS scheduled_flights,
   SUM(CANCELLED) AS cancelled_flights,
   ROUND(
      100.0 * SUM(CANCELLED) / COUNT(*),
	  2
   ) AS cancellation_rate_pct
FROM dfw_flights
GROUP BY YEAR, MONTH
ORDER BY YEAR, MONTH;

SELECT COUNT(*) AS column_count
FROM pragma_table_info('flights_2025_07_check');

SELECT cid, name
FROM pragma_table_info('flights_raw')
EXCEPT
SELECT cid, name
FROM pragma_table_info('flights_2025_07_check');

SELECT YEAR, MONTH, COUNT(*) AS total_flights
FROM flights_2025_07_check
GROUP BY YEAR, MONTH;

INSERT INTO flights_raw
SELECT *
FROM flights_2025_07_check
WHERE YEAR = 2025
   AND MONTH = 7
   AND NOT EXISTS (
      SELECT 1
	  FROM flights_raw
	  WHERE YEAR = 2025 AND MONTH = 7
   );
   
SELECT YEAR, MONTH, COUNT(*) AS total_flights
FROM flights_raw
GROUP BY YEAR, MONTH
ORDER BY YEAR, MONTH;

SELECT YEAR, MONTH, COUNT(*) AS total_flights
FROM flights_raw
GROUP BY YEAR, MONTH
ORDER BY YEAR, MONTH;   

SELECT
   YEAR,
   MONTH,
   COUNT(*) AS scheduled_flights,
   SUM(CANCELLED) AS cancelled_flights,
   ROUND(
      100.0 * SUM(CANCELLED) / COUNT(*),
	  2
   ) AS cancellation_rate_pct
FROM dfw_flights
GROUP BY YEAR, MONTH
ORDER BY YEAR, MONTH;

SELECT COUNT(*) AS column_count
FROM pragma_table_info('flights_2025_08_check');

SELECT cid, name
FROM pragma_table_info('flights_raw')
EXCEPT
SELECT cid, name
FROM pragma_table_info('flights_2025_08_check');

SELECT YEAR, MONTH, COUNT(*) AS total_flights
FROM flights_2025_08_check
GROUP BY YEAR, MONTH;

INSERT INTO flights_raw
SELECT *
FROM flights_2025_08_check
WHERE YEAR = 2025
   AND MONTH = 8
   AND NOT EXISTS (
      SELECT 1
	  FROM flights_raw
	  WHERE YEAR = 2025 AND MONTH = 8
   );

SELECT YEAR, MONTH, COUNT(*) AS total_flights
FROM flights_raw
GROUP BY YEAR, MONTH
ORDER BY YEAR, MONTH;   

SELECT
   YEAR,
   MONTH,
   COUNT(*) AS scheduled_flights,
   SUM(CANCELLED) AS cancelled_flights,
   ROUND(
      100.0 * SUM(CANCELLED) / COUNT(*),
	  2
   ) AS cancellation_rate_pct
FROM dfw_flights
GROUP BY YEAR, MONTH
ORDER BY YEAR, MONTH;

SELECT COUNT(*) AS column_count
FROM pragma_table_info('flights_2025_09_check');

SELECT cid, name
FROM pragma_table_info('flights_raw')
EXCEPT
SELECT cid, name
FROM pragma_table_info('flights_2025_09_check');

SELECT YEAR, MONTH, COUNT(*) AS total_flights
FROM flights_2025_09_check
GROUP BY YEAR, MONTH;

INSERT INTO flights_raw
SELECT *
FROM flights_2025_09_check
WHERE YEAR = 2025
   AND MONTH = 9
   AND NOT EXISTS (
      SELECT 1
	  FROM flights_raw
	  WHERE YEAR = 2025 AND MONTH = 9
   );
   
SELECT YEAR, MONTH, COUNT(*) AS total_flights
FROM flights_raw
GROUP BY YEAR, MONTH
ORDER BY YEAR, MONTH;

SELECT
   YEAR,
   MONTH,
   COUNT(*) AS scheduled_flights,
   SUM(CANCELLED) AS cancelled_flights,
   ROUND(
      100.0 * SUM(CANCELLED) / COUNT(*),
	  2
   ) AS cancellation_rate_pct
FROM dfw_flights
GROUP BY YEAR, MONTH
ORDER BY YEAR, MONTH;

SELECT COUNT(*) AS column_count
FROM pragma_table_info('flights_2025_10_check');

SELECT cid, name
FROM pragma_table_info('flights_raw')
EXCEPT
SELECT cid, name
FROM pragma_table_info('flights_2025_10_check');

SELECT YEAR, MONTH, COUNT(*) AS total_flights
FROM flights_2025_10_check
GROUP BY YEAR, MONTH;

INSERT INTO flights_raw
SELECT *
FROM flights_2025_10_check
WHERE YEAR = 2025
   AND MONTH = 10
   AND NOT EXISTS (
      SELECT 1
	  FROM flights_raw
	  WHERE YEAR = 2025 AND MONTH = 10
   );

SELECT YEAR, MONTH, COUNT(*) AS total_flights
FROM flights_raw
GROUP BY YEAR, MONTH
ORDER BY YEAR, MONTH;

SELECT
   YEAR,
   MONTH,
   COUNT(*) AS scheduled_flights,
   SUM(CANCELLED) AS cancelled_flights,
   ROUND(
      100.0 * SUM(CANCELLED) / COUNT(*),
	  2
   ) AS cancellation_rate_pct
FROM dfw_flights
GROUP BY YEAR, MONTH
ORDER BY YEAR, MONTH;

SELECT COUNT(*) AS column_count
FROM pragma_table_info('flights_2025_11_check');

SELECT cid, name
FROM pragma_table_info('flights_raw')
EXCEPT
SELECT cid, name
FROM pragma_table_info('flights_2025_11_check');

SELECT YEAR, MONTH, COUNT(*) AS total_flights
FROM flights_2025_11_check
GROUP BY YEAR, MONTH;

INSERT INTO flights_raw
SELECT *
FROM flights_2025_11_check
WHERE YEAR = 2025
   AND MONTH = 11
   AND NOT EXISTS (
      SELECT 1
	  FROM flights_raw
	  WHERE YEAR = 2025 AND MONTH = 11
   );

SELECT YEAR, MONTH, COUNT(*) AS total_flights
FROM flights_raw
GROUP BY YEAR, MONTH
ORDER BY YEAR, MONTH;

SELECT
   YEAR,
   MONTH,
   COUNT(*) AS scheduled_flights,
   SUM(CANCELLED) AS cancelled_flights,
   ROUND(
      100.0 * SUM(CANCELLED) / COUNT(*),
	  2
   ) AS cancellation_rate_pct
FROM dfw_flights
GROUP BY YEAR, MONTH
ORDER BY YEAR, MONTH;

SELECT COUNT(*) AS column_count
FROM pragma_table_info('flights_2025_12_check');

SELECT cid, name
FROM pragma_table_info('flights_raw')
EXCEPT
SELECT cid, name
FROM pragma_table_info('flights_2025_12_check');

SELECT YEAR, MONTH, COUNT(*) AS total_flights
FROM flights_2025_12_check
GROUP BY YEAR, MONTH;

INSERT INTO flights_raw
SELECT *
FROM flights_2025_12_check
WHERE YEAR = 2025
   AND MONTH = 12
   AND NOT EXISTS (
      SELECT 1
	  FROM flights_raw
	  WHERE YEAR = 2025 AND MONTH = 12
   );
   
SELECT YEAR, MONTH, COUNT(*) AS total_flights
FROM flights_raw
GROUP BY YEAR, MONTH
ORDER BY YEAR, MONTH;

SELECT
   YEAR,
   MONTH,
   COUNT(*) AS scheduled_flights,
   SUM(CANCELLED) AS cancelled_flights,
   ROUND(
      100.0 * SUM(CANCELLED) / COUNT(*),
	  2
   ) AS cancellation_rate_pct
FROM dfw_flights
GROUP BY YEAR, MONTH
ORDER BY YEAR, MONTH;

SELECT
   FL_DATE,
   OP_UNIQUE_CARRIER,
   OP_CARRIER_FL_NUM,
   ORIGIN,
   DEST,
   CRS_DEP_TIME,
   COUNT(*) AS record_count
FROM dfw_flights
GROUP BY
   FL_DATE,
   OP_UNIQUE_CARRIER,
   OP_CARRIER_FL_NUM,
   ORIGIN,
   DEST,
   CRS_DEP_TIME
HAVING COUNT(*) > 1;

SELECT
   CANCELLED,
   DIVERTED,
   COUNT(*) AS total_flights
FROM dfw_flights
GROUP BY CANCELLED, DIVERTED
ORDER BY CANCELLED, DIVERTED;

SELECT
   CANCELLED,
   DIVERTED,
   COUNT(*) AS total_flights,
   SUM(CASE
      WHEN NULLIF(TRIM(DEP_DELAY), '') IS NULL
	  THEN 1 ELSE 0
   END) AS missing_dep_delay,
   SUM(CASE
      WHEN NULLIF(TRIM(ARR_DELAY), '') IS NULL
	  THEN 1 ELSE 0
   END) AS missing_arr_delay
FROM dfw_flights
GROUP BY CANCELLED, DIVERTED
ORDER BY CANCELLED, DIVERTED;

SELECT DISTINCT
   DEP_DELAY,
   ARR_DELAY
FROM 	dfw_flights
WHERE TRIM(DEP_DELAY) GLOB '*[^0-9.+-]*'
   OR TRIM(ARR_DELAY) GLOB '*[^0-9.+-]*';

WITH delay_values AS (
   SELECT 'DEP_DELAY' AS field_name,
      TRIM(DEP_DELAY) AS value 
   FROM dfw_flights
   UNION ALL
   SELECT 'ARR_DELAY', TRIM(ARR_DELAY)
   FROM dfw_flights
),
unsigned_values AS (
   SELECT *,
      CASE 
	     WHEN SUBSTR(value, 1, 1) IN ('+', '-')
		 THEN SUBSTR(value, 2)
		 ELSE value 
      END AS unsigned_value
   FROM delay_values
)
SELECT DISTINCT field_name, value 
FROM unsigned_values
WHERE value IS NOT NULL
   AND value <> ''
   AND (
      unsigned_value GLOB '*[^0-9.]*'
	  OR unsigned_value NOT GLOB '*[0-9]*'
	  OR unsigned_value GLOB '*.*.*'
);

SELECT
   MIN(dep_delay_num) AS min_dep_delay,
   MAX(dep_delay_num) AS max_dep_delay,
   MIN(CASE WHEN DIVERTED = 0
      THEN arr_delay_num END) AS min_arr_delay,
   MAX(CASE WHEN DIVERTED = 0
      THEN arr_delay_num END) AS max_arr_delay
FROM dfw_flights
WHERE CANCELLED = 0;

SELECT
   FL_DATE,
   OP_UNIQUE_CARRIER,
   OP_CARRIER_FL_NUM,
   DEST,
   dep_delay_num,
   arr_delay_num,
   DIVERTED
FROM dfw_flights
WHERE CANCELLED = 0
   AND (
      dep_delay_num IN (-32, 1766)
	  OR (
	     DIVERTED = 0
		 AND arr_delay_num IN (-63, 1756)
      )
   )
ORDER BY dep_delay_num DESC;

SELECT
   COUNT(*) AS eligible_departures,
   SUM(CASE WHEN dep_delay_num >= 15
      THEN 1 ELSE 0 END) AS delayed_departures,
   ROUND(
      100.0 * SUM(CASE WHEN dep_delay_num >= 15
	     THEN 1 ELSE 0 END) / COUNT(*),
      2
   ) AS departure_delay_rate_pct
FROM dfw_flights
WHERE CANCELLED = 0
   AND dep_delay_num IS NOT NULL;
   
SELECT
   COUNT(*) AS eligible_arrivals,
   SUM(CASE WHEN arr_delay_num >= 15
      THEN 1 ELSE 0 END) AS delayed_arrivals,
   ROUND(
      100.0 * SUM(CASE WHEN arr_delay_num >= 15
	     THEN 1 ELSE 0 END) / COUNT(*),
      2
   ) AS arrival_delay_rate_pct
FROM dfw_flights
WHERE CANCELLED = 0
   AND DIVERTED = 0
   AND arr_delay_num IS NOT NULL;
   
SELECT
   YEAR,
   MONTH,
   COUNT(*) AS eligible_departures,
   SUM(CASE WHEN dep_delay_num >= 15
      THEN 1 ELSE 0 END) AS delayed_departures,
   ROUND(
      100.0 * SUM(CASE WHEN dep_delay_num >= 15
	     THEN 1 ELSE 0 END) / COUNT(*),
      2
   ) AS departure_delay_rate_pct
FROM dfw_flights
WHERE CANCELLED = 0
   AND dep_delay_num IS NOT NULL
GROUP BY YEAR, MONTH
ORDER BY YEAR, MONTH;


SELECT
   OP_UNIQUE_CARRIER,
   COUNT(*) AS eligible_departures,
   SUM(CASE WHEN dep_delay_num >= 15
      THEN 1 ELSE 0 END) AS delayed_departures,
   ROUND(
      100.0 * SUM(CASE WHEN dep_delay_num >= 15
	     THEN 1 ELSE 0 END) / COUNT(*),
      2
   ) AS departure_delay_rate_pct
FROM dfw_flights
WHERE CANCELLED = 0
   AND dep_delay_num IS NOT NULL
GROUP BY OP_UNIQUE_CARRIER
ORDER BY departure_delay_rate_pct DESC;

-- Cancellation rate by operating carrier
SELECT
   OP_UNIQUE_CARRIER,
   COUNT(*) AS scheduled_flights,
   SUM(CANCELLED) AS cancelled_flights,
   ROUND(
      100.0 * SUM(CANCELLED) / COUNT(*),
	  2
   ) AS cancellation_rate_pct
FROM dfw_flights
GROUP BY OP_UNIQUE_CARRIER
ORDER BY cancellation_rate_pct DESC;

-- Distribution of cancellation codes
SELECT
   CANCELLATION_CODE,
   COUNT(*) AS cancelled_flights,
   ROUND(
      100.0 * COUNT(*) /
	  (SELECT COUNT(*)
	  FROM dfw_flights
	  WHERE CANCELLED = 1),
	  2
   ) AS share_of_cancellations_pct
FROM dfw_flights
WHERE CANCELLED = 1
GROUP BY CANCELLATION_CODE
ORDER BY cancelled_flights DESC;

-- Monthly cancellations by reported reason
SELECT
   YEAR,
   MONTH,
   COUNT(*) AS cancelled_flights,
   SUM(CASE WHEN CANCELLATION_CODE = 'A'
      THEN 1 ELSE 0 END) AS carrier_cancellations,
   SUM(CASE WHEN CANCELLATION_CODE = 'B'
      THEN 1 ELSE 0 END) AS weather_cancellations,
   SUM(CASE WHEN CANCELLATION_CODE = 'C'
      THEN 1 ELSE 0 END) AS nas_cancellations,
   SUM(CASE WHEN CANCELLATION_CODE = 'D'
      THEN 1 ELSE 0 END) AS security_cancellations
FROM dfw_flights
WHERE CANCELLED = 1
GROUP BY YEAR, MONTH
ORDER BY YEAR, MONTH;

-- Departure delay severity by month
SELECT
   YEAR,
   MONTH,
   COUNT(*) AS delayed_departures,
   ROUND(AVG(dep_delay_num), 2) AS avg_delay_minutes,
   MAX(dep_delay_num) AS max_delay_minutes
FROM dfw_flights
WHERE CANCELLED = 0
   AND dep_delay_num >= 15
GROUP BY YEAR, MONTH
ORDER BY YEAR, MONTH;

-- Median departure delay among delayed flights
WITH ranked_delays AS (
   SELECT
      YEAR,
	  MONTH,
	  dep_delay_num,
	  ROW_NUMBER() OVER (
	     PARTITION BY YEAR, MONTH
		 ORDER BY dep_delay_num
      ) AS rn,
	  COUNT(*) OVER (
	     PARTITION BY YEAR, MONTH
      ) AS total
   FROM dfw_flights
   WHERE CANCELLED = 0
      AND dep_delay_num >= 15
)
SELECT
   YEAR,
   MONTH,
   ROUND(AVG(dep_delay_num), 2) AS median_delay_minutes
FROM ranked_delays
WHERE rn IN ((total + 1) / 2, (total + 2) / 2)
GROUP BY YEAR, MONTH
ORDER BY YEAR, MONTH;

-- Arrival recovery among delayed departures
SELECT
   COUNT(*) AS eligible_delayed_departures,
   SUM(CASE WHEN arr_delay_num < 15
      THEN 1 ELSE 0 END) AS recovered_flights,
   ROUND(
      100.0 * SUM(CASE WHEN arr_delay_num < 15
	     THEN 1 ELSE 0 END) / COUNT(*),
      2
   ) AS recovery_rate_pct
FROM dfw_flights
WHERE CANCELLED = 0
   AND DIVERTED = 0
   AND dep_delay_num >= 15
   AND arr_delay_num IS NOT NULL;
 
--Monthly arrival recovery among delayed departures 
SELECT
   YEAR,
   MONTH,
   COUNT(*) AS eligible_delayed_departures,
   SUM(CASE WHEN arr_delay_num < 15
      THEN 1 ELSE 0 END) AS recovered_flights,
   ROUND(
      100.0 * SUM(CASE WHEN arr_delay_num < 15
	     THEN 1 ELSE 0 END) / COUNT(*),
      2
   ) AS recovery_rate_pct
FROM dfw_flights
WHERE CANCELLED = 0
   AND DIVERTED = 0
   AND dep_delay_num >= 15
   AND arr_delay_num IS NOT NULL
GROUP BY YEAR, MONTH
ORDER BY YEAR, MONTH;

--Arrival recovery by operating carrier
SELECT
   OP_UNIQUE_CARRIER,
   COUNT(*) AS eligible_delayed_departures,
   SUM(CASE WHEN arr_delay_num < 15
      THEN 1 ELSE 0 END) AS recovered_flights,
   ROUND(
      100.0 * SUM(CASE WHEN arr_delay_num < 15
	     THEN 1 ELSE 0 END) / COUNT(*),
      2
   ) AS recovery_rate_pct
FROM dfw_flights
WHERE CANCELLED = 0
   AND DIVERTED = 0
   AND dep_delay_num >= 15
   AND arr_delay_num IS NOT NULL
GROUP BY OP_UNIQUE_CARRIER
ORDER BY recovery_rate_pct DESC;

-- Recovery by departure delay range 
WITH delay_groups AS (
   SELECT
      CASE
	     WHEN dep_delay_num < 30 THEN '15-29 min'
		 WHEN dep_delay_num < 60 THEN '30-59 min'
		 WHEN dep_delay_num < 120 THEN '60-119 min'
		 ELSE '120+ min'
      END AS departure_delay_range,
	  CASE
	     WHEN dep_delay_num < 30 THEN 1
		 WHEN dep_delay_num < 60 THEN 2
		 WHEN dep_delay_num < 120 THEN 3
		 ELSE 4
      END AS range_order,
	  arr_delay_num
   FROM dfw_flights
   WHERE CANCELLED = 0
      AND DIVERTED = 0 
	  AND dep_delay_num >= 15
	  AND arr_delay_num IS NOT NULL
)
SELECT
   departure_delay_range,
   COUNT(*) AS eligible_delayed_departures,
   SUM(CASE WHEN arr_delay_num < 15
      THEN 1 ELSE 0 END) AS recovered_flights,
   ROUND(
      100.0 * SUM(CASE WHEN arr_delay_num < 15
	     THEN 1 ELSE 0 END) / COUNT(*),
      2
   ) AS recovery_rate_pct
FROM delay_groups
GROUP BY departure_delay_range, range_order
ORDER BY range_order;

-- Departure delay rate by scheduled time block
SELECT
   DEP_TIME_BLK,
   COUNT(*) AS eligible_departure,
   SUM(CASE WHEN dep_delay_num >= 15
      THEN 1 ELSE 0 END) AS delayed_departures,
   ROUND(
      100.0 * SUM(CASE WHEN dep_delay_num >= 15
	     THEN 1 ELSE 0 END) / COUNT(*),
      2
   ) AS departure_delay_rate_pct
FROM dfw_flights
WHERE CANCELLED = 0
   AND dep_delay_num IS NOT NULL
GROUP BY DEP_TIME_BLK
ORDER BY DEP_TIME_BLK;

-- Departure delay rate by day of week
SELECT
   DAY_OF_WEEK,
   COUNT(*) AS eligible_departures,
   SUM(CASE WHEN dep_delay_num >= 15
      THEN 1 ELSE 0 END) AS delayed_departures,
   ROUND(
      100.0 * SUM(CASE WHEN dep_delay_num >= 15
	     THEN 1 ELSE 0 END) / COUNT(*),
      2
   ) AS departure_delay_rate_pct
FROM dfw_flights
WHERE CANCELLED = 0
   AND dep_delay_num IS NOT NULL
GROUP BY DAY_OF_WEEK
ORDER BY DAY_OF_WEEK;

-- Top 10 destinations by departure delay rate
-- Includes destinations with at least 1,000 eligible departures
SELECT
   DEST,
   COUNT(*) AS eligible_departures,
   SUM(CASE WHEN dep_delay_num >= 15
      THEN 1 ELSE 0 END) AS delayed_departures,
   ROUND(
      100.0 * SUM(CASE WHEN dep_delay_num >= 15
	     THEN 1 ELSE 0 END) / COUNT(*),
      2
   ) AS departure_delay_rate_pct
FROM dfw_flights
WHERE CANCELLED = 0
   AND dep_delay_num IS NOT NULL
GROUP BY DEST
HAVING COUNT(*) >= 1000
ORDER BY departure_delay_rate_pct DESC, DEST
LIMIT 10;

-- Top 10 destinations by cancellation rate
-- Includes destinations with at least 1,000 scheduled departures
SELECT
   DEST,
   COUNT(*) AS scheduled_flights,
   SUM(CANCELLED) AS cancelled_flights,
   ROUND(
      100.0 * SUM(CANCELLED) / COUNT(*),
	  2
   ) AS cancellation_rate_pct
FROM dfw_flights
GROUP BY DEST
HAVING COUNT(*) >= 1000
ORDER BY cancellation_rate_pct DESC, DEST
LIMIT 10;

-- Flight-level dataset for Power BI
SELECT
   YEAR,
   MONTH,
   DAY_OF_WEEK,
   FL_DATE,
   OP_UNIQUE_CARRIER,
   OP_CARRIER_FL_NUM,
   ORIGIN,
   DEST,
   DEST_CITY_NAME,
   DEST_STATE_ABR,
   CRS_DEP_TIME,
   DEP_TIME_BLK,
   CANCELLED,
   CANCELLATION_CODE,
   DIVERTED,
   dep_delay_num,
   arr_delay_num,
   DISTANCE
FROM dfw_flights
WHERE YEAR = 2025;
      