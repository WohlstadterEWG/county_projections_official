/*
 *	  $Author: michaelw $
 *	  Created: December 14, 2022
 *	$Revision: $
 *	 $HeadURL: $
 *
 * Subject
 *	High Level Queries to Explore the Data
 * 
 * Purpose
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




-- Population Projections by Scenario
SELECT "p"."year", "p"."geoid", "p"."gender", "p"."race", "p"."age_bracket",
	SUM("p"."population_ssp1") AS "population_ssp1",
	SUM("p"."population_ssp2") AS "population_ssp2",
	SUM("p"."population_ssp3") AS "population_ssp3",
	SUM("p"."population_ssp4") AS "population_ssp4",
	SUM("p"."population_ssp5") AS "population_ssp5"
FROM "projection__cross_ssp" AS "p"
WHERE "p"."year" = '2100'
GROUP BY "p"."year", "p"."geoid", "p"."gender", "p"."race", "p"."age_bracket"
ORDER BY "p"."year", "p"."geoid", "p"."gender", "p"."race", "p"."age_bracket";


SELECT "p"."year",
	SUM("p"."population_ssp1") AS "population_ssp1",
	SUM("p"."population_ssp2") AS "population_ssp2",
	SUM("p"."population_ssp3") AS "population_ssp3",
	SUM("p"."population_ssp4") AS "population_ssp4",
	SUM("p"."population_ssp5") AS "population_ssp5"
FROM "projection__cross_ssp" AS "p"
GROUP BY "p"."year"
ORDER BY "p"."year";



-- Region
SELECT "p"."year", "p"."geoid",
	SUM("p"."population_ssp1") AS "population_ssp1",
	SUM("p"."population_ssp2") AS "population_ssp2",
	SUM("p"."population_ssp3") AS "population_ssp3",
	SUM("p"."population_ssp4") AS "population_ssp4",
	SUM("p"."population_ssp5") AS "population_ssp5"
FROM "hauer__cross_ssp_mo" AS "p"
WHERE "p"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
GROUP BY "p"."year", "p"."geoid"
ORDER BY "p"."year", "p"."geoid";


SELECT "p"."year",
	SUM("p"."population_ssp1") AS "population_ssp1",
	SUM("p"."population_ssp2") AS "population_ssp2",
	SUM("p"."population_ssp3") AS "population_ssp3",
	SUM("p"."population_ssp4") AS "population_ssp4",
	SUM("p"."population_ssp5") AS "population_ssp5"
FROM "hauer__cross_ssp" AS "p"
WHERE "p"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
GROUP BY "p"."year"
ORDER BY "p"."year";
