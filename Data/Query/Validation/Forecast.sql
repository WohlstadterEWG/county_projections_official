/*
 *	  $Author: michaelw $
 *	  Created: October, 12, 2022
 *	$Revision: $
 *	 $HeadURL: $
 *
 * Subject
 *	Forecast Checks
 * 
 * Purpose
 *	Statements to visually validate the Population Forecasts was Generated appropriately.
 *
 * 
 * Dependencies
 * 	-
 *
 * Conversions
 *
 * Notes
 *
 * Assumptions
 * 	-
 * 
 * References
 * 
 * TODO
 * 
 */


-- Progress
-- Evaluation
SELECT "year", "geoid", "gender", "race", "age_bracket", "type",
	COUNT(*) AS "forecast_count"
FROM "population__forecast__evaluation"
GROUP BY "year", "geoid", "gender", "race", "age_bracket", "type"
ORDER BY "year", "geoid", "gender", "race", "age_bracket", "type";


WITH "state" AS (
	SELECT DISTINCT "year", SUBSTR("geoid", 1, 2) AS "state_fips"
	FROM "population__forecast__evaluation"
)
SELECT "year", COUNT(*) AS "state_count"
FROM "state"
GROUP BY "year"
ORDER BY "year" DESC;


-- Projection
SELECT "year", "geoid", "gender", "race", "age_bracket", "type",
	COUNT(*) AS "forecast_count"
FROM "population__forecast__projection"
GROUP BY "year", "geoid", "gender", "race", "age_bracket", "type"
ORDER BY "year", "geoid", "gender", "race", "age_bracket", "type";


WITH "state" AS (
	SELECT DISTINCT "year", SUBSTR("geoid", 1, 2) AS "state_fips"
	FROM "population__forecast__projection"
)
SELECT "year", COUNT(*) AS "state_count"
FROM "state"
GROUP BY "year"
ORDER BY "year" DESC;



-- Look for duplicates
-- Evaluation
SELECT "year", "geoid", "race", "gender", "age_bracket", "type",
	COUNT(*) AS "instance_count"
FROM "population__forecast__evaluation"
GROUP BY "year", "geoid", "race", "gender", "age_bracket", "type"
HAVING "instance_count" > 1
ORDER BY "year", "geoid", "race", "gender", "age_bracket", "type";


-- Projection
SELECT "year", "geoid", "race", "gender", "age_bracket", "type",
	COUNT(*) AS "instance_count"
FROM "population__forecast__projection"
GROUP BY "year", "geoid", "race", "gender", "age_bracket", "type"
HAVING "instance_count" > 1
ORDER BY "year", "geoid", "race", "gender", "age_bracket", "type";



-- Subtotals
-- Evaluation
SELECT "year", "geoid", "race", "gender", "age_bracket", "type",
	SUM("projection_a") AS "projection_a",
	SUM("projection_b") AS "projection_b",
	SUM("projection_c") AS "projection_c"
FROM "population__forecast__evaluation"
GROUP BY "year", "geoid", "race", "gender", "age_bracket", "type"
ORDER BY "year", "geoid", "race", "gender", "age_bracket", "type";


-- Projection
SELECT "year", "geoid", "race", "gender", "age_bracket", "type",
	SUM("projection_a") AS "projection_a",
	SUM("projection_b") AS "projection_b",
	SUM("projection_c") AS "projection_c"
FROM "population__forecast__projection"
GROUP BY "year", "geoid", "race", "gender", "age_bracket", "type"
ORDER BY "year", "geoid", "race", "gender", "age_bracket", "type";



-- County Totals
-- Evaluation
SELECT "year", "geoid", "type",
	SUM("projection_a") AS "projection_a",
	SUM("projection_b") AS "projection_b",
	SUM("projection_c") AS "projection_c"
FROM "population__forecast__evaluation"
GROUP BY "year", "geoid", "type"
ORDER BY "year", "geoid", "type";


-- Projection
SELECT "year", "geoid", "type",
	SUM("projection_a") AS "projection_a",
	SUM("projection_b") AS "projection_b",
	SUM("projection_c") AS "projection_c"
FROM "population__forecast__projection"
GROUP BY "year", "geoid", "type"
ORDER BY "year", "geoid", "type";
