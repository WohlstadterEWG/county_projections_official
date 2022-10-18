/*
 *	  $Author: michaelw $
 *	  Created: October, 17, 2022
 *	$Revision: $
 *	 $HeadURL: $
 *
 * Subject
 *	Data Checks during the Workflow
 * 
 * Purpose
 *	Statements to visually validate the Population Forecasts at checkpoints during the workflow.
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



-- 002 CDC Estimates
SELECT "r"."YEAR", "r"."STATE", "r"."COUNTY", SUM("r"."POPULATION") AS "population_total"
FROM "population__sum_1969_2020__raw" AS "r"
WHERE (
		"r"."STATE" = '17' AND "r"."COUNTY" IN ('119','133','163')
	OR
		"r"."STATE" = '29' AND "r"."COUNTY" IN ('071','099','183','189','510')
	)
GROUP BY "r"."YEAR", "r"."STATE", "r"."COUNTY"
ORDER BY "r"."YEAR", "r"."STATE", "r"."COUNTY";


-- 003 CDC Estimates
SELECT "r"."YEAR", "r"."STATE", "r"."COUNTY", SUM("r"."POPULATION") AS "population_total"
FROM "population__sum_1990_2020__raw" AS "r"
WHERE (
		"r"."STATE" = '17' AND "r"."COUNTY" IN ('119','133','163')
	OR
		"r"."STATE" = '29' AND "r"."COUNTY" IN ('071','099','183','189','510')
	)
GROUP BY "r"."YEAR", "r"."STATE", "r"."COUNTY"
ORDER BY "r"."YEAR", "r"."STATE", "r"."COUNTY";



-- 006 Compare Evaluation Forecasts against CDC Estimates
-- SQLite
SELECT "f"."year", "b"."geoid", SUM("e"."population") AS "population_estimate",
	SUM(
		CASE
			WHEN "f"."population_additive" >= "b"."population" THEN
				"f"."population_additive"
			ELSE
				"f"."population_multiplicative"
		END
	) AS "population_forecast"
FROM (
		SELECT "geoid", "race", SUM("population") AS "population"
		FROM "population__estimate_cdc__evaluation"
		WHERE "year" = '2000'
		GROUP BY "geoid", "race"
	) AS "b"
	INNER JOIN (
		SELECT "a"."year", "a"."geoid", "a"."race",
			SUM("a"."population") AS "population_additive", SUM("m"."population") AS "population_multiplicative"
		FROM (
				SELECT "f"."year", "f"."geoid", "f"."gender", "f"."race", "f"."age_bracket",
					SUM("f"."projection_a") AS "population"
				FROM "population__forecast__evaluation" AS "f"
				WHERE (
						"f"."geoid" IN ('17119','17133','17163')
					OR
						"f"."geoid" IN ('29071','29099','29183','29189','29510')
					)
					AND "f"."type" = 'ADD'
				GROUP BY "f"."year", "f"."geoid", "f"."gender", "f"."race", "f"."age_bracket"
			) AS "a"
			INNER JOIN (
				SELECT "f"."year", "f"."geoid", "f"."gender", "f"."race", "f"."age_bracket",
					SUM("f"."projection_a") AS "population"
				FROM "population__forecast__evaluation" AS "f"
				WHERE (
						"f"."geoid" IN ('17119','17133','17163')
					OR
						"f"."geoid" IN ('29071','29099','29183','29189','29510')
					)
					AND "f"."type" = 'Mult'
				GROUP BY "f"."year", "f"."geoid", "f"."gender", "f"."race", "f"."age_bracket"
			) AS "m"
				ON "a"."year" = "m"."year" AND "a"."geoid" = "m"."geoid"
					AND "a"."gender" = "m"."gender" AND "a"."race" = "m"."race" AND "a"."age_bracket" = "m"."age_bracket"
		GROUP BY "a"."year", "a"."geoid", "a"."race"
	) AS "f" ON "b"."geoid" = "f"."geoid" AND "b"."race" = "f"."race"
	INNER JOIN (
		SELECT "year", "geoid", "race", SUM("population") AS "population"
		FROM "population__estimate_cdc__evaluation"
		GROUP BY "year", "geoid", "race"
	) AS "e" ON "f"."year" = "e"."year" AND "f"."geoid" = "e"."geoid" AND "f"."race" = "e"."race"
GROUP BY "f"."year", "b"."geoid"
ORDER BY "f"."year", "b"."geoid";


-- 007
SELECT "f"."year", "b"."geoid", SUM("e"."population") AS "population_estimate",
	SUM(
		CASE
			WHEN "f"."population_additive" >= "b"."population" THEN
				"f"."population_additive"
			ELSE
				"f"."population_multiplicative"
		END
	) AS "population_forecast"
FROM (
		SELECT "geoid", "race", SUM("population") AS "population"
		FROM "population__estimate_cdc__projection"
		WHERE "year" = '2020'
		GROUP BY "geoid", "race"
	) AS "b"
	INNER JOIN (
		SELECT "a"."year", "a"."geoid", "a"."race",
			SUM("a"."population") AS "population_additive", SUM("m"."population") AS "population_multiplicative"
		FROM (
				SELECT "f"."year", "f"."geoid", "f"."gender", "f"."race", "f"."age_bracket",
					SUM("f"."projection_a") AS "population"
				FROM "population__forecast__projection" AS "f"
				WHERE (
						"f"."geoid" IN ('17119','17133','17163')
					OR
						"f"."geoid" IN ('29071','29099','29183','29189','29510')
					)
					AND "f"."type" = 'ADD'
				GROUP BY "f"."year", "f"."geoid", "f"."gender", "f"."race", "f"."age_bracket"
			) AS "a"
			INNER JOIN (
				SELECT "f"."year", "f"."geoid", "f"."gender", "f"."race", "f"."age_bracket",
					SUM("f"."projection_a") AS "population"
				FROM "population__forecast__projection" AS "f"
				WHERE (
						"f"."geoid" IN ('17119','17133','17163')
					OR
						"f"."geoid" IN ('29071','29099','29183','29189','29510')
					)
					AND "f"."type" = 'Mult'
				GROUP BY "f"."year", "f"."geoid", "f"."gender", "f"."race", "f"."age_bracket"
			) AS "m"
				ON "a"."year" = "m"."year" AND "a"."geoid" = "m"."geoid"
					AND "a"."gender" = "m"."gender" AND "a"."race" = "m"."race" AND "a"."age_bracket" = "m"."age_bracket"
		GROUP BY "a"."year", "a"."geoid", "a"."race"
	) AS "f" ON "b"."geoid" = "f"."geoid" AND "b"."race" = "f"."race"
	LEFT JOIN (
		SELECT "year", "geoid", "race", SUM("population") AS "population"
		FROM "population__estimate_cdc__projection"
		GROUP BY "year", "geoid", "race"
	) AS "e" ON "f"."year" = "e"."year" AND "f"."geoid" = "e"."geoid" AND "f"."race" = "e"."race"
GROUP BY "f"."year", "b"."geoid"
ORDER BY "f"."year", "b"."geoid";



-- 999 Read the Populations as projected from the CDC Estimates
SELECT "p"."year", SUM("p"."population_total") AS "population_total"
FROM (
		SELECT "p"."year", "p"."geoid", "p"."race", "p"."gender", "p"."age_group",
			SUM("p"."a") AS "population_total"
		FROM "population__01_z__raw" AS "p"
			INNER JOIN "projection_type" AS "t"
				ON "p"."geoid" = "t"."geoid" AND "p"."race" = "t"."race" AND "p"."type" = "t"."code"
		WHERE "p"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
		GROUP BY "p"."year", "p"."geoid", "p"."race", "p"."gender", "p"."age_group"
	) AS "p"
GROUP BY "p"."year"
ORDER BY "p"."year";


-- 999 CDC based projects factored by SSP
SELECT "p"."year", "p"."geoid", --SUM("p"."population_total") AS "population_total",
	SUM("p"."population_total" * ("s"."ssp1" / "s"."ssp2")) AS "population_total_ssp1",
	SUM("p"."population_total" * ("s"."ssp2" / "s"."ssp2")) AS "population_total_ssp2",
	SUM("p"."population_total" * ("s"."ssp3" / "s"."ssp2")) AS "population_total_ssp3",
	SUM("p"."population_total" * ("s"."ssp4" / "s"."ssp2")) AS "population_total_ssp4",
	SUM("p"."population_total" * ("s"."ssp5" / "s"."ssp2")) AS "population_total_ssp5"
FROM (
		SELECT "p"."year", "p"."geoid", "p"."race", "p"."gender", "p"."age_group",
			SUM("p"."a") AS "population_total"
		FROM "population__01_z__raw" AS "p"
			INNER JOIN "projection_type" AS "t"
				ON "p"."geoid" = "t"."geoid" AND "p"."race" = "t"."race" AND "p"."type" = "t"."code"
		WHERE "p"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
		GROUP BY "p"."year", "p"."geoid", "p"."race", "p"."gender", "p"."age_group"
	) AS "p"
	INNER JOIN "ssp__01_prepared__raw" AS "s"
		ON "p"."year" = "s"."year" AND "p"."gender" = "s"."gender" AND "p"."age_group" = "s"."age_group"::INTEGER
GROUP BY "p"."year", "p"."geoid"
ORDER BY "p"."year", "p"."geoid";


-- 999 SSP National Projections
SELECT "r"."year",
	SUM("r"."ssp1") AS "population_ssp1",
	SUM("r"."ssp2") AS "population_ssp2",
	SUM("r"."ssp3") AS "population_ssp3",
	SUM("r"."ssp4") AS "population_ssp4",
	SUM("r"."ssp5") AS "population_ssp5"
FROM "ssp__01_prepared__raw" AS "r"
GROUP BY "r"."year"
ORDER BY "r"."year";
