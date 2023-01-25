/*
 *	  $Author: michaelw $
 *	  Created: September 26, 2022
 *	$Revision: $
 *	 $HeadURL: $
 *
 * Subject
 *	Population Projection from 2025 to 2100
 * 
 * Purpose
 *	Statements to pull the population projections as modeled by the Hauer Cohort Survival Model workflow.
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




-- Population
-- SQLite
SELECT "f"."year", "b"."geoid",
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
GROUP BY "f"."year", "b"."geoid"
ORDER BY "f"."year", "b"."geoid";


-- PostgreSQL
SELECT "f"."year", "b"."geoid",
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
		FROM "cohort"."population__estimate_cdc__projection"
		WHERE "year" = '2020'
		GROUP BY "geoid", "race"
	) AS "b"
	INNER JOIN (
		SELECT "a"."year", "a"."geoid", "a"."race",
			SUM("a"."population") AS "population_additive", SUM("m"."population") AS "population_multiplicative"
		FROM (
				SELECT "f"."year", "f"."geoid", "f"."gender", "f"."race", "f"."age_bracket",
					SUM("f"."projection_a") AS "population"
				FROM "cohort"."population__forecast__projection" AS "f"
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
				FROM "cohort"."population__forecast__projection" AS "f"
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
GROUP BY "f"."year", "b"."geoid"
ORDER BY "f"."year", "b"."geoid";



SELECT "f"."year", "b"."geoid", "b"."race",
	CASE
		WHEN "f"."population_additive" >= "b"."population" THEN
			"f"."population_additive"
		ELSE
			"f"."population_multiplicative"
	END AS "population"
FROM (
		SELECT "geoid", "race", SUM("population")::INTEGER AS "population"
		FROM "cohort"."population__estimate_cdc__evaluation"
		WHERE "year" = '2020'
		GROUP BY "geoid", "race"
	) AS "b"
	INNER JOIN (
		SELECT "a"."year", "a"."geoid", "a"."race",
			SUM("a"."population") AS "population_additive", SUM("m"."population") AS "population_multiplicative"
		FROM (
				SELECT "f"."year", "f"."geoid", "f"."gender", "f"."race", "f"."age_bracket",
					SUM("f"."projection_a") AS "population"
				FROM "cohort"."population__forecast__evaluation" AS "f"
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
				FROM "cohort"."population__forecast__evaluation" AS "f"
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
ORDER BY "f"."year", "b"."geoid", "b"."race";



-- County Level Population Estimates from CDC Data
SELECT "r"."year", SUBSTR("r"."county_race", 1, 5) AS "geoid", SUM("r"."a") AS "population_total"
FROM "population_eval_2000_2020__raw" AS "r"
WHERE SUBSTR("r"."county_race", 1, 5) IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
	AND "r"."type" = 'ADD'
GROUP BY "r"."year", SUBSTR("r"."county_race", 1, 5)
ORDER BY "r"."year", "geoid";


SELECT "r"."year", SUBSTR("r"."county_race", 1, 5) AS "geoid", SUM("r"."a") AS "population_total"
FROM "population_proj_2020_2100__raw" AS "r"
WHERE SUBSTR("r"."county_race", 1, 5) IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
	AND "r"."type" = 'ADD'
GROUP BY "r"."year", SUBSTR("r"."county_race", 1, 5)
ORDER BY "r"."year", "geoid";




-- Population Estimates
-- CDC Estimates 2020
SELECT "r"."year", "r"."geoid",
	SUM("r"."population") AS "population_total"
FROM "population__00_k05_launch__raw" AS "r"
WHERE "r"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
GROUP BY "r"."year", "r"."geoid"
ORDER BY "r"."year", "r"."geoid";


SELECT "r"."year", "r"."geoid", "r"."gender", "r"."race",
	SUM("r"."population") AS "population_total"
FROM "population__00_k05_launch__raw" AS "r"
WHERE "r"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
GROUP BY "r"."year", "r"."geoid", "r"."gender", "r"."race"
ORDER BY "r"."year", "r"."geoid", "r"."gender", "r"."race";


-- Generated Projections (CCD additive / CCR multiplicative) 2025 to 2100 in 5 year increments
SELECT "r"."year", "r"."geoid", "r"."type",
	SUM("r"."a") AS "population_total"
FROM "population__01_z__raw" AS "r"
WHERE "r"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
GROUP BY "r"."year", "r"."geoid", "r"."type"
ORDER BY "r"."year", "r"."geoid", "r"."type";


-- CDC Estimates 2020
SELECT "r"."geoid",
	SUM("r"."population") AS "population_total"
FROM "population__02_basesum__raw" AS "r"
WHERE "r"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
GROUP BY "r"."geoid"
ORDER BY "r"."geoid";


-- Generated Projections CCD only
SELECT "r"."geoid", "r"."type",
	SUM("r"."a") AS "population_total"
FROM "population__03_addsum__raw" AS "r"
WHERE "r"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
GROUP BY "r"."geoid", "r"."type"
ORDER BY "r"."geoid", "r"."type";


-- Check for Additive or Multiplicative
SELECT "r"."geoid", "r"."race", "r"."combined"
FROM "population__04_addmult__raw" AS "r"
WHERE "r"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
ORDER BY "r"."geoid", "r"."race";


SELECT "b"."geoid", "b"."race",
	SUM("b"."population_total") AS "population_total_baseline",
	SUM("a"."population_total") AS "population_total_additive",
	SUM("m"."population_total") AS "population_total_multiplicative",
	SUM(
		CASE
			WHEN "a"."population_total" >= "b"."population_total" THEN
				"a"."population_total"
			ELSE
				"m"."population_total"
		END
	) AS "population_total_change"
FROM (
		SELECT "r"."geoid", "r"."race",
			SUM("r"."population") AS "population_total"
		FROM "population__02_basesum__raw" AS "r"
		WHERE "r"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
		GROUP BY "r"."geoid", "r"."race"
	) AS "b"
	INNER JOIN (
		SELECT "r"."geoid", "r"."race",
			SUM("r"."a") AS "population_total"
		FROM "population__03_addsum__raw" AS "r"
		WHERE "r"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
		GROUP BY "r"."geoid", "r"."race"
	) AS "a" ON "b"."geoid" = "a"."geoid" AND "b"."race" = "a"."race"
	INNER JOIN (
		SELECT "r"."geoid", "r"."race",
			SUM("r"."a") AS "population_total"
		FROM "population__01_z__raw" AS "r"
		WHERE "r"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
			AND "r"."type" = 'Mult' AND "r"."year" = '2100'
		GROUP BY "r"."geoid", "r"."race"
	) AS "m" ON "b"."geoid" = "m"."geoid" AND "b"."race" = "m"."race"
GROUP BY "b"."geoid", "b"."race"
ORDER BY "p"."geoid", "b"."race";


SELECT "b"."geoid",
	SUM("b"."population_total") AS "population_total_baseline", SUM("a"."population_total") AS "population_total_additive",
	SUM(
		CASE
			WHEN "b"."population_total" > "a"."population_total" THEN
				"b"."population_total"
			ELSE
				"a"."population_total"
		END
	) AS "population_change"
FROM (
		SELECT "r"."geoid", "r"."race",
			SUM("r"."population") AS "population_total"
		FROM "population__02_basesum__raw" AS "r"
		WHERE "r"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
		GROUP BY "r"."geoid", "r"."race"
	) AS "b"
	INNER JOIN (
		SELECT "r"."geoid", "r"."race", "r"."type",
			SUM("r"."a") AS "population_total"
		FROM "population__03_addsum__raw" AS "r"
		WHERE "r"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
		GROUP BY "r"."geoid", "r"."race", "r"."type"
	) AS "a" ON "b"."geoid" = "a"."geoid" AND "b"."race" = "a"."race"
GROUP BY "b"."geoid"
ORDER BY "b"."geoid";


SELECT COUNT(*) AS "estimate_total"
FROM "population__04_addmult__raw" AS "r"
WHERE "r"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510');


SELECT COUNT(*) AS "estimate_total"
FROM (
		SELECT "r"."geoid",
			SUM("r"."population") AS "population_total"
		FROM "population__02_basesum__raw" AS "r"
		WHERE "r"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
		GROUP BY "r"."geoid"
	) AS "b"
	INNER JOIN (
		SELECT "r"."geoid", "r"."type",
			SUM("r"."a") AS "population_total"
		FROM "population__03_addsum__raw" AS "r"
		WHERE "r"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
		GROUP BY "r"."geoid", "r"."type"
	) AS "a" ON "b"."geoid" = "a"."geoid";




-- 06
SELECT "r"."year", "r"."geoid", SUM("r"."a") AS "population_total"
FROM "population__06_z2__raw" AS "r"
WHERE "r"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
GROUP BY "r"."year", "r"."geoid"
ORDER BY "r"."year", "r"."geoid";

	
	
-- Perform Blended Projection in SQL
SELECT "b"."geoid",
	SUM("b"."population_total") AS "population_total_baseline",
	SUM("a"."population_total") AS "population_total_additive",
	SUM("m"."population_total") AS "population_total_multiplicative",
	SUM(
		CASE
			WHEN "b"."population_total" > "a"."population_total" THEN
				"b"."population_total"
			ELSE
				"m"."population_total"
		END
	) AS "population_change"
FROM (
		SELECT "r"."geoid", "r"."race",
			SUM("r"."population") AS "population_total"
		FROM "population__02_basesum__raw" AS "r"
		WHERE "r"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
		GROUP BY "r"."geoid", "r"."race"
	) AS "b"
	INNER JOIN (
		SELECT "r"."geoid", "r"."race",
			SUM("r"."a") AS "population_total"
		FROM "population__03_addsum__raw" AS "r"
		WHERE "r"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
		GROUP BY "r"."geoid", "r"."race"
	) AS "a" ON "b"."geoid" = "a"."geoid" AND "b"."race" = "a"."race"
	INNER JOIN (
		SELECT "r"."geoid", "r"."race",
			SUM("r"."a") AS "population_total"
		FROM "population__01_z__raw" AS "r"
		WHERE "r"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
			AND "r"."type" = 'Mult' AND "r"."year" = '2100'
		GROUP BY "r"."geoid", "r"."race"
	) AS "m" ON "b"."geoid" = "m"."geoid" AND "b"."race" = "m"."race"
GROUP BY "b"."geoid"
ORDER BY "b"."geoid";



-- Additive vs Multiplicative Determination
SELECT "b"."geoid", "b"."race",
	CASE
		WHEN "a"."population_total" >= "b"."population_total" THEN
			'ADD'
		ELSE
			'Mult'
	END AS "projection_type"
FROM (
		SELECT "r"."geoid", "r"."race",
			SUM("r"."population") AS "population_total"
		FROM "population__02_basesum__raw" AS "r"
		WHERE "r"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
		GROUP BY "r"."geoid", "r"."race"
	) AS "b"
	INNER JOIN (
		SELECT "r"."geoid", "r"."race",
			SUM("r"."a") AS "population_total"
		FROM "population__03_addsum__raw" AS "r"
		WHERE "r"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
		GROUP BY "r"."geoid", "r"."race"
	) AS "a" ON "b"."geoid" = "a"."geoid" AND "b"."race" = "a"."race"
	INNER JOIN (
		SELECT "r"."geoid", "r"."race",
			SUM("r"."a") AS "population_total"
		FROM "population__01_z__raw" AS "r"
		WHERE "r"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
			AND "r"."type" = 'Mult' AND "r"."year" = '2100'
		GROUP BY "r"."geoid", "r"."race"
	) AS "m" ON "b"."geoid" = "m"."geoid" AND "b"."race" = "m"."race"
ORDER BY "b"."geoid", "b"."race";

CREATE VIEW "projection_type" AS
SELECT "b"."geoid", "b"."race",
	CASE
		WHEN "a"."population_total" >= "b"."population_total" THEN
			'ADD'
		ELSE
			'Mult'
	END AS "code"
FROM (
		SELECT "r"."geoid", "r"."race",
			SUM("r"."population") AS "population_total"
		FROM "population__02_basesum__raw" AS "r"
		WHERE "r"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
		GROUP BY "r"."geoid", "r"."race"
	) AS "b"
	INNER JOIN (
		SELECT "r"."geoid", "r"."race",
			SUM("r"."a") AS "population_total"
		FROM "population__03_addsum__raw" AS "r"
		WHERE "r"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
		GROUP BY "r"."geoid", "r"."race"
	) AS "a" ON "b"."geoid" = "a"."geoid" AND "b"."race" = "a"."race"
	INNER JOIN (
		SELECT "r"."geoid", "r"."race",
			SUM("r"."a") AS "population_total"
		FROM "population__01_z__raw" AS "r"
		WHERE "r"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
			AND "r"."type" = 'Mult' AND "r"."year" = '2100'
		GROUP BY "r"."geoid", "r"."race"
	) AS "m" ON "b"."geoid" = "m"."geoid" AND "b"."race" = "m"."race"
ORDER BY "b"."geoid", "b"."race";


-- Blended Projections
SELECT "p"."year", "p"."geoid", "p"."race", "p"."gender",
	SUM("p"."a") AS "population_total"
FROM "population__01_z__raw" AS "p"
	INNER JOIN "projection_type" AS "t"
		ON "p"."geoid" = "t"."geoid" AND "p"."race" = "t"."race" AND "p"."type" = "t"."code"
WHERE "p"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
GROUP BY "p"."year", "p"."geoid", "p"."race", "p"."gender"
ORDER BY "p"."year", "p"."geoid", "p"."race", "p"."gender";







-- Projection
SELECT *
FROM crosstab(
		$$
SELECT "r"."GEOID", "r"."YEAR", SUM("r"."SSP5") AS "population_total"
FROM "projection_final__raw" AS "r"
WHERE "r"."GEOID" IN ('17119','17133','17163','29071','29099','29183','29189','29510')
GROUP BY "r"."GEOID", "r"."YEAR"
ORDER BY "r"."GEOID", "r"."YEAR"
		$$,
		$$
SELECT DISTINCT "r"."YEAR" FROM "projection_final__raw" AS "r" ORDER BY "r"."YEAR"
		$$
	) AS "ct" (
		"County" VARCHAR,
		"2025" FLOAT,
		"2030" FLOAT,
		"2035" FLOAT,
		"2040" FLOAT,
		"2045" FLOAT,
		"2050" FLOAT,
		"2055" FLOAT,
		"2060" FLOAT,
		"2065" FLOAT,
		"2070" FLOAT,
		"2075" FLOAT,
		"2080" FLOAT,
		"2085" FLOAT,
		"2090" FLOAT,
		"2095" FLOAT,
		"2100" FLOAT
	);

	
	
	
	
SELECT "r"."year",
	SUM("r"."ssp1") AS "population_ssp1",
	SUM("r"."ssp2") AS "population_ssp2",
	SUM("r"."ssp3") AS "population_ssp3",
	SUM("r"."ssp4") AS "population_ssp4",
	SUM("r"."ssp5") AS "population_ssp5"
FROM "projection_ssp__raw" AS "r"
GROUP BY "r"."year"
ORDER BY "r"."year";


SELECT *
FROM "projection_ssp__raw" AS "r"
ORDER BY "r"."gender", "r"."age_group", "r"."year";


SELECT "r"."year",
	SUM("r"."ssp1") AS "population_ssp1",
	SUM("r"."ssp2") AS "population_ssp2",
	SUM("r"."ssp3") AS "population_ssp3",
	SUM("r"."ssp4") AS "population_ssp4",
	SUM("r"."ssp5") AS "population_ssp5"
FROM "projection_ssp__raw" AS "r"
GROUP BY "r"."year"
ORDER BY "r"."year";


SELECT "r"."year", "r"."geoid",
	SUM("r"."ssp1") AS "population_ssp1",
	SUM("r"."ssp2") AS "population_ssp2",
	SUM("r"."ssp3") AS "population_ssp3",
	SUM("r"."ssp4") AS "population_ssp4",
	SUM("r"."ssp5") AS "population_ssp5"
FROM "projection_final__raw" AS "r"
WHERE "r"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
GROUP BY "r"."year", "r"."geoid"
ORDER BY "r"."year", "r"."geoid";


SELECT "r"."year",
	SUM("r"."ssp1") AS "population_ssp1",
	SUM("r"."ssp2") AS "population_ssp2",
	SUM("r"."ssp3") AS "population_ssp3",
	SUM("r"."ssp4") AS "population_ssp4",
	SUM("r"."ssp5") AS "population_ssp5"
FROM "projection_final__raw" AS "r"
WHERE "r"."geoid" IN ('17119','17133','17163','29071','29099','29183','29189','29510')
GROUP BY "r"."year"
ORDER BY "r"."year";





-- Candidate
-- Note, "year" isn't actually used but the inclusion speeds up the query in PostgreSQL.
SELECT "b"."geoid", "b"."race",
	CASE
		WHEN "fa"."population" >= "b"."population" THEN
			"fa"."type"
		WHEN "fa"."population" < "b"."population" THEN
			"fm"."type"
		ELSE
			NULL
	END AS "type"
FROM (
		SELECT "p"."geoid", "p"."race",
			SUM("p"."population") AS "population"
		FROM "cohort"."population__estimate_cdc__projection" AS "p"
		WHERE "p"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
			AND "p"."year" = '2020'
		GROUP BY "p"."geoid", "p"."race"
	) AS "b"
	INNER JOIN (
		SELECT "p"."geoid", "p"."race", "p"."type",
			SUM("p"."projection_a") AS "population"
		FROM "cohort"."population__forecast__projection" AS "p"
		WHERE "p"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
			AND "p"."year" = '2100' AND "p"."type" = 'ADD'
		GROUP BY "p"."geoid", "p"."race", "p"."type"
	) AS "fa" ON "b"."geoid" = "fa"."geoid" AND "b"."race" = "fa"."race"
	INNER JOIN (
		SELECT "p"."geoid", "p"."race", "p"."type",
			SUM("p"."projection_a") AS "population"
		FROM "cohort"."population__forecast__projection" AS "p"
		WHERE "p"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
			AND "p"."year" = '2100' AND "p"."type" = 'Mult'
		GROUP BY "p"."geoid", "p"."race", "p"."type"
	) AS "fm" ON "b"."geoid" = "fm"."geoid" AND "b"."race" = "fm"."race"
ORDER BY "b"."geoid", "b"."race";


CREATE VIEW "forecast_type" AS
SELECT "b"."geoid", "b"."race",
	CASE
		WHEN "fa"."population" >= "b"."population" THEN
			"fa"."type"
		WHEN "fa"."population" < "b"."population" THEN
			"fm"."type"
		ELSE
			NULL
	END AS "type"
FROM (
		SELECT "p"."geoid", "p"."race",
			SUM("p"."population") AS "population"
		FROM "cohort"."population__estimate_cdc__projection" AS "p"
		WHERE "p"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
			AND "p"."year" = '2020'
		GROUP BY "p"."geoid", "p"."race"
	) AS "b"
	INNER JOIN (
		SELECT  "p"."year", "p"."geoid", "p"."race", "p"."type",
			SUM("p"."projection_a") AS "population"
		FROM "cohort"."population__forecast__projection" AS "p"
		WHERE "p"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
			AND "p"."year" = '2100' AND "p"."type" = 'ADD'
		GROUP BY "p"."year", "p"."geoid", "p"."race", "p"."type"
	) AS "fa" ON "b"."geoid" = "fa"."geoid" AND "b"."race" = "fa"."race"
	INNER JOIN (
		SELECT "p"."year", "p"."geoid", "p"."race", "p"."type",
			SUM("p"."projection_a") AS "population"
		FROM "cohort"."population__forecast__projection" AS "p"
		WHERE "p"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
			AND "p"."year" = '2100' AND "p"."type" = 'Mult'
		GROUP BY "p"."year", "p"."geoid", "p"."race", "p"."type"
	) AS "fm" ON "b"."geoid" = "fm"."geoid" AND "b"."race" = "fm"."race"
ORDER BY "b"."geoid", "b"."race";



SELECT "a"."year", "t"."geoid", "t"."race",
	CASE
		WHEN "t"."type" = 'ADD' THEN
			"a"."population"
		WHEN "t"."type" = 'Mult' THEN
			"m"."population"
		ELSE
			NULL
	END AS "population"
FROM "forecast_type" AS "t"
	LEFT JOIN (
		SELECT "p"."year", "p"."geoid", "p"."race",
			SUM("p"."projection_a") AS "population"
		FROM "cohort"."population__forecast__projection" AS "p"
		WHERE "p"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
		GROUP BY "p"."year", "p"."geoid", "p"."race"
	) AS "a" ON "t"."geoid" = "a"."geoid" AND "t"."race" = "a"."race"
	LEFT JOIN (
		SELECT "p"."year", "p"."geoid", "p"."race",
			SUM("p"."projection_a") AS "population"
		FROM "cohort"."population__forecast__projection" AS "p"
		WHERE "p"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
			AND "p"."type" = 'Mult'
		GROUP BY "p"."year", "p"."geoid", "p"."race"
	) AS "m" ON "t"."geoid" = "m"."geoid" AND "t"."race" = "m"."race"
WHERE "a"."year" = "m"."year"
ORDER BY "year", "t"."geoid", "t"."race";



-- SQLite
CREATE VIEW "forecast_type" AS
SELECT "b"."geoid", "b"."race",
	CASE
		WHEN "fa"."population" >= "b"."population" THEN
			"fa"."type"
		WHEN "fa"."population" < "b"."population" THEN
			"fm"."type"
		ELSE
			NULL
	END AS "type"
FROM (
		SELECT "p"."geoid", "p"."race",
			SUM("p"."population") AS "population"
		FROM "population__estimate_cdc__projection" AS "p"
		WHERE "p"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
			AND "p"."year" = '2020'
		GROUP BY "p"."geoid", "p"."race"
	) AS "b"
	INNER JOIN (
		SELECT "p"."geoid", "p"."race", "p"."type",
			SUM("p"."projection_a") AS "population"
		FROM "population__forecast__projection" AS "p"
		WHERE "p"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
			AND "p"."year" = '2100' AND "p"."type" = 'ADD'
		GROUP BY "p"."geoid", "p"."race", "p"."type"
	) AS "fa" ON "b"."geoid" = "fa"."geoid" AND "b"."race" = "fa"."race"
	INNER JOIN (
		SELECT "p"."geoid", "p"."race", "p"."type",
			SUM("p"."projection_a") AS "population"
		FROM "population__forecast__projection" AS "p"
		WHERE "p"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
			AND "p"."year" = '2100' AND "p"."type" = 'Mult'
		GROUP BY "p"."geoid", "p"."race", "p"."type"
	) AS "fm" ON "b"."geoid" = "fm"."geoid" AND "b"."race" = "fm"."race";

	
	
	
SELECT "a"."year", "t"."geoid", "t"."race",
	CASE
		WHEN "t"."type" = 'ADD' THEN
			"a"."population"
		WHEN "t"."type" = 'Mult' THEN
			"m"."population"
		ELSE
			NULL
	END AS "population"
FROM "forecast_type" AS "t"
	LEFT JOIN (
		SELECT "p"."year", "p"."geoid", "p"."race",
			SUM("p"."projection_a") AS "population"
		FROM "population__forecast__projection" AS "p"
		WHERE "p"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
		GROUP BY "p"."year", "p"."geoid", "p"."race"
	) AS "a" ON "t"."geoid" = "a"."geoid" AND "t"."race" = "a"."race"
	LEFT JOIN (
		SELECT "p"."year", "p"."geoid", "p"."race",
			SUM("p"."projection_a") AS "population"
		FROM "population__forecast__projection" AS "p"
		WHERE "p"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
			AND "p"."type" = 'Mult'
		GROUP BY "p"."year", "p"."geoid", "p"."race"
	) AS "m" ON "t"."geoid" = "m"."geoid" AND "t"."race" = "m"."race"
WHERE "a"."year" = "m"."year"
ORDER BY "a"."year", "t"."geoid", "t"."race";



SELECT "a"."year", "t"."geoid", "t"."race",
	SUM(
		CASE
			WHEN "t"."type" = 'ADD' THEN
				"a"."population"
			WHEN "t"."type" = 'Mult' THEN
				"m"."population"
			ELSE
				NULL
		END
	) AS "population"
FROM "forecast_type" AS "t"
	LEFT JOIN (
		SELECT "p"."year", "p"."geoid", "p"."race",
			SUM("p"."projection_a") AS "population"
		FROM "population__forecast__projection" AS "p"
		WHERE "p"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
		GROUP BY "p"."year", "p"."geoid", "p"."race"
	) AS "a" ON "t"."geoid" = "a"."geoid" AND "t"."race" = "a"."race"
	LEFT JOIN (
		SELECT "p"."year", "p"."geoid", "p"."race",
			SUM("p"."projection_a") AS "population"
		FROM "population__forecast__projection" AS "p"
		WHERE "p"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
			AND "p"."type" = 'Mult'
		GROUP BY "p"."year", "p"."geoid", "p"."race"
	) AS "m" ON "t"."geoid" = "m"."geoid" AND "t"."race" = "m"."race"
WHERE "a"."year" = "m"."year"
GROUP BY "a"."year", "t"."geoid", "t"."race"
ORDER BY "a"."year", "t"."geoid", "t"."race";





-- PostgreSQL
DROP VIEW "forecast_type";

CREATE VIEW "forecast_type" AS
SELECT "b"."geoid", "b"."race",
	CASE
		WHEN "fa"."population" >= "b"."population" THEN
			"fa"."type"
		WHEN "fa"."population" < "b"."population" THEN
			"fm"."type"
		ELSE
			NULL
	END AS "type"
FROM (
		SELECT "p"."geoid", "p"."race",
			SUM("p"."population") AS "population"
		FROM "public"."population_estimate" AS "p"
		WHERE "p"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
			AND "p"."year" = '2020'
		GROUP BY "p"."geoid", "p"."race"
	) AS "b"
	INNER JOIN (
		SELECT  "p"."geoid", "p"."race", "p"."type",
			SUM("p"."projection_a") AS "population"
		FROM "public"."population_forecast" AS "p"
		WHERE "p"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
			AND "p"."year" = '2100' AND "p"."type" = 'ADD'
		GROUP BY "p"."geoid", "p"."race", "p"."type"
	) AS "fa" ON "b"."geoid" = "fa"."geoid" AND "b"."race" = "fa"."race"
	INNER JOIN (
		SELECT "p"."geoid", "p"."race", "p"."type",
			SUM("p"."projection_a") AS "population"
		FROM "public"."population_forecast" AS "p"
		WHERE "p"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
			AND "p"."year" = '2100' AND "p"."type" = 'Mult'
		GROUP BY "p"."geoid", "p"."race", "p"."type"
	) AS "fm" ON "b"."geoid" = "fm"."geoid" AND "b"."race" = "fm"."race"
ORDER BY "b"."geoid", "b"."race";





SELECT "a"."year", "t"."geoid",
	SUM(
		CASE
			WHEN "t"."type" = 'ADD' THEN
				"a"."population"
			WHEN "t"."type" = 'Mult' THEN
				"m"."population"
			ELSE
				NULL
		END
	) AS "population"
FROM "forecast_type" AS "t"
	LEFT JOIN (
		SELECT "p"."year", "p"."geoid", "p"."race",
			SUM("p"."projection_a") AS "population"
		FROM "public"."population_forecast" AS "p"
		WHERE "p"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
		GROUP BY "p"."year", "p"."geoid", "p"."race"
	) AS "a" ON "t"."geoid" = "a"."geoid" AND "t"."race" = "a"."race"
	LEFT JOIN (
		SELECT "p"."year", "p"."geoid", "p"."race",
			SUM("p"."projection_a") AS "population"
		FROM "public"."population_forecast" AS "p"
		WHERE "p"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
			AND "p"."type" = 'Mult'
		GROUP BY "p"."year", "p"."geoid", "p"."race"
	) AS "m" ON "t"."geoid" = "m"."geoid" AND "t"."race" = "m"."race"
WHERE "a"."year" = "m"."year"
GROUP BY "a"."year", "t"."geoid"
ORDER BY "a"."year", "t"."geoid";




SELECT "p"."year", "p"."geoid",
	SUM("p"."population" * ("s"."ssp1" / "s"."ssp2")) AS "population_ssp1",
	SUM("p"."population" * ("s"."ssp2" / "s"."ssp2")) AS "population_ssp2",
	SUM("p"."population" * ("s"."ssp3" / "s"."ssp2")) AS "population_ssp3",
	SUM("p"."population" * ("s"."ssp4" / "s"."ssp2")) AS "population_ssp4",
	SUM("p"."population" * ("s"."ssp5" / "s"."ssp2")) AS "population_ssp5"
FROM (
		SELECT "a"."year", "a"."geoid", "a"."gender", "a"."age_bracket",
			SUM(
				CASE
					WHEN "t"."type" = 'ADD' THEN
						"a"."population"
					WHEN "t"."type" = 'Mult' THEN
						"m"."population"
					ELSE
						NULL
				END
			) AS "population"
		FROM "forecast_type" AS "t"
			INNER JOIN (
				SELECT "p"."year", "p"."geoid", "p"."race", "p"."gender", "p"."age_bracket",
					SUM("p"."projection_a") AS "population"
				FROM "public"."population_forecast" AS "p"
				WHERE "p"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
				GROUP BY "p"."year", "p"."geoid", "p"."race", "p"."gender", "p"."age_bracket"
			) AS "a" ON "t"."geoid" = "a"."geoid" AND "t"."race" = "a"."race"
			INNER JOIN (
				SELECT "p"."year", "p"."geoid", "p"."race", "p"."gender", "p"."age_bracket",
					SUM("p"."projection_a") AS "population"
				FROM "public"."population_forecast" AS "p"
				WHERE "p"."geoid" IN ('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510')
					AND "p"."type" = 'Mult'
				GROUP BY "p"."year", "p"."geoid", "p"."race", "p"."gender", "p"."age_bracket"
			) AS "m" ON "t"."geoid" = "m"."geoid" AND "t"."race" = "m"."race"
		WHERE "a"."year" = "m"."year" AND "a"."gender" = "m"."gender" AND "a"."age_bracket" = "m"."age_bracket"
		GROUP BY "a"."year", "a"."geoid", "a"."gender", "a"."age_bracket"
	) AS "p"
	INNER JOIN "ssp__01_prepared__raw" AS "s"
		ON "p"."year" = "s"."year" AND "p"."gender" = "s"."gender" AND "p"."age_bracket"::INTEGER = "s"."age_group"::INTEGER
GROUP BY "p"."year", "p"."geoid"
ORDER BY "p"."year", "p"."geoid";
