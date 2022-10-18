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


SELECT "year", "geoid", "gender", "age_bracket", "type",
	COUNT(*) AS "duplicate_count"
FROM "population__forecast__evaluation"
GROUP BY "year", "geoid", "gender", "age_bracket", "type"
ORDER BY "year", "geoid", "gender", "age_bracket", "type";


SELECT "year", "geoid", "type",
	SUM("projection_a") AS "projection_a",
	SUM("projection_b") AS "projection_b",
	SUM("projection_c") AS "projection_c"
FROM "population__forecast__evaluation"
GROUP BY "year", "geoid", "type"
ORDER BY "year", "geoid", "type";



SELECT "year", "geoid", "type",
	SUM("projection_a") AS "projection_a",
	SUM("projection_b") AS "projection_b",
	SUM("projection_c") AS "projection_c"
FROM "population__forecast__projection"
GROUP BY "year", "geoid", "type"
ORDER BY "year", "geoid", "type";
