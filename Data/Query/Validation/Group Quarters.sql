/*
 *	  $Author: michaelw $
 *	  Created: September 29, 2022
 *	$Revision: $
 *	 $HeadURL: $
 *
 * Subject
 *	Group Quarters Checks
 * 
 * Purpose
 *	Statements to visually validate the Group Quarters data that is pulled and aggregated.
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



-- 2000
SELECT "r"."year", "r"."state_fips", "r"."county_fips", SUM("r"."population") AS "population_total"
FROM "population__census_2000_gq__raw" AS "r"
WHERE (
		"r"."state_fips" = '17' AND "r"."county_fips" IN ('119','133','163')
	OR
		"r"."state_fips" = '29' AND "r"."county_fips" IN ('071','099','183','189','510')
	)
GROUP BY "r"."year", "r"."state_fips", "r"."county_fips"
ORDER BY "r"."year", "r"."state_fips", "r"."county_fips";


SELECT "r"."year", "r"."state_fips", "r"."county_fips",
	"r"."race", "r"."gender", "r"."age_group",
	"r"."population"
FROM "population__census_2000_gq__raw" AS "r"
WHERE (
		"r"."state_fips" = '17' AND "r"."county_fips" IN ('119','133','163')
	OR
		"r"."state_fips" = '29' AND "r"."county_fips" IN ('071','099','183','189','510')
	)
ORDER BY "r"."year", "r"."state_fips", "r"."county_fips", "r"."race", "r"."gender";



-- 2010
SELECT "r"."year", "r"."state_fips", "r"."county_fips", SUM("r"."population") AS "population_total"
FROM "population__census_2010_gq__raw" AS "r"
WHERE (
		"r"."state_fips" = '17' AND "r"."county_fips" IN ('119','133','163')
	OR
		"r"."state_fips" = '29' AND "r"."county_fips" IN ('071','099','183','189','510')
	)
GROUP BY "r"."year", "r"."state_fips", "r"."county_fips"
ORDER BY "r"."year", "r"."state_fips", "r"."county_fips";


SELECT "r"."year", "r"."state_fips", "r"."county_fips",
	"r"."race", "r"."gender", "r"."age_group",
	"r"."population"
FROM "population__census_2010_gq__raw" AS "r"
WHERE (
		"r"."state_fips" = '17' AND "r"."county_fips" IN ('119','133','163')
	OR
		"r"."state_fips" = '29' AND "r"."county_fips" IN ('071','099','183','189','510')
	)
ORDER BY "r"."year", "r"."state_fips", "r"."county_fips", "r"."race", "r"."gender";



SELECT COUNT(*) AS "population_count"
FROM "population__group_quarters_prior" AS "p"
	INNER JOIN "population__group_quarters" AS "c"
		ON "p"."year" = "c"."year"
			AND "p"."state_fips" = "c"."state_fips" AND "p"."county_fips" = "c"."county_fips"
			AND "p"."race" = "c"."race" AND "p"."gender" = "c"."gender" AND "p"."age_bracket" = "c"."age_bracket"
WHERE "p"."population" = "c"."population";