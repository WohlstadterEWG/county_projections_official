/*
 *	  $Author: michaelw $
 *	  Created: September 29, 2022
 *	$Revision: $
 *	 $HeadURL: $
 *
 * Subject
 *	CDC Population Estimates Checks
 * 
 * Purpose
 *	Statements to visually validate the CDC Population Estimates data that is pulled and aggregated.
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



SELECT "r"."year", SUBSTR("r"."county_race", 1, 5) AS "geoid", "r"."type",
	SUM("r"."a") AS "population_total"
FROM "population_eval_2000_2020__raw" AS "r"
WHERE SUBSTR("r"."county_race", 1, 5) IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
GROUP BY "r"."year", SUBSTR("r"."county_race", 1, 5), "r"."type"
ORDER BY "r"."year", "geoid", "r"."type";


SELECT "r"."year", SUBSTR("r"."county_race", 1, 5) AS "geoid", "r"."gender", "r"."age", "r"."type",
	SUM("r"."a") AS "population_a", SUM("r"."b") AS "population_b", SUM("r"."c") AS "population_c"
FROM "population_eval_2000_2020__raw" AS "r"
WHERE SUBSTR("r"."county_race", 1, 5) IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
GROUP BY "r"."year", SUBSTR("r"."county_race", 1, 5), "r"."gender", "r"."age", "r"."type"
ORDER BY "r"."year", "geoid", "r"."gender", "r"."age"::INTEGER, "r"."type";



SELECT "r"."year", SUBSTR("r"."county_race", 1, 5) AS "geoid", "r"."type",
	SUM("r"."a") AS "population_total"
FROM "population_eval_2000_2020__raw" AS "r"
WHERE SUBSTR("r"."county_race", 1, 5) IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
GROUP BY "r"."year", SUBSTR("r"."county_race", 1, 5), "r"."type"
ORDER BY "r"."year", "geoid", "r"."type";


SELECT "r"."year", SUBSTR("r"."county_race", 1, 5) AS "geoid", "r"."gender", "r"."age", "r"."type",
	SUM("r"."a") AS "population_a", SUM("r"."b") AS "population_b", SUM("r"."c") AS "population_c"
FROM "population_eval_2000_2020__raw" AS "r"
WHERE SUBSTR("r"."county_race", 1, 5) IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
GROUP BY "r"."year", SUBSTR("r"."county_race", 1, 5), "r"."gender", "r"."age", "r"."type"
ORDER BY "r"."year", "geoid", "r"."gender", "r"."age"::INTEGER, "r"."type";



SELECT "r"."year", SUBSTR("r"."county_race", 1, 5) AS "geoid", "r"."type",
	SUM("r"."a") AS "population_total"
FROM "population_proj_2020_2100__raw" AS "r"
WHERE SUBSTR("r"."county_race", 1, 5) IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
GROUP BY "r"."year", SUBSTR("r"."county_race", 1, 5), "r"."type"
ORDER BY "r"."year", "geoid", "r"."type";


SELECT "r"."year", SUBSTR("r"."county_race", 1, 5) AS "geoid", "r"."gender", "r"."age", "r"."type",
	SUM("r"."a") AS "population_a", SUM("r"."b") AS "population_b", SUM("r"."c") AS "population_c"
FROM "population_proj_2020_2100__raw" AS "r"
WHERE SUBSTR("r"."county_race", 1, 5) IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
GROUP BY "r"."year", SUBSTR("r"."county_race", 1, 5), "r"."gender", "r"."age", "r"."type"
ORDER BY "r"."year", "geoid", "r"."gender", "r"."age"::INTEGER, "r"."type";
