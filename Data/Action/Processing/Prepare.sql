/*
 *	  $Author: michaelw $
 *	  Created: October 17, 2022
 *	$Revision: $
 *	 $HeadURL: $
 *
 * Subject
 * 	Wrangle Data
 * 
 * Purpose
 *	The raw data comes from a variety of sources and is projected to a variety of coordinate systems.  This script along
 *	with SQL statements (in another file) loads and then refactors the data into a usable structure.
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



CREATE TABLE "population__cdc_1969_2020" AS
SELECT
	SUBSTR("r"."raw", 1, 4)::CHARACTER(4) AS "year",
	SUBSTR("r"."raw", 5, 2)::CHARACTER(2) AS "state_abbreviation",
	SUBSTR("r"."raw", 7, 2)::CHARACTER(2) AS "state_fips",
	SUBSTR("r"."raw", 9, 3)::CHARACTER(3) AS "county_fips",
	SUBSTR("r"."raw", 12, 2)::CHARACTER(2) AS "registry",
	SUBSTR("r"."raw", 14, 1)::CHARACTER(1) AS "race",
	SUBSTR("r"."raw", 15, 1)::CHARACTER(1) AS "origin",
	SUBSTR("r"."raw", 16, 1)::CHARACTER(1) AS "gender",
	SUBSTR("r"."raw", 17, 2)::CHARACTER(2) AS "age_bracket",
	SUBSTR("r"."raw", 19, 8)::INTEGER AS "population"
FROM "population__cdc_1969_2020__raw" AS "r"
ORDER BY "year", "state_fips", "county_fips", "race", "gender", "age_bracket";


CREATE INDEX "population__cdc_1969_2020_indx_year"
	ON "population__cdc_1969_2020" ("year", "state_fips", "county_fips", "race", "gender", "age_bracket");
