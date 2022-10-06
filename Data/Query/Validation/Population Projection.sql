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
 *	Statements to pull the population projects as modeled by the Hauer Cohort Survival Model workflow.
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
SELECT "r"."YEAR", "r"."STATE", "r"."COUNTY", SUM("r"."POPULATION") AS "population_total"
FROM "population__sum_1990_2020__raw" AS "r"
WHERE (
		"r"."STATE" = '17' AND "r"."COUNTY" IN ('119','133','163')
	OR
		"r"."STATE" = '29' AND "r"."COUNTY" IN ('071','099','183','189','510')
	)
GROUP BY "r"."YEAR", "r"."STATE", "r"."COUNTY"
ORDER BY "r"."YEAR", "r"."STATE", "r"."COUNTY";


SELECT "r"."YEAR", "r"."STATE", "r"."COUNTY", SUM("r"."POPULATION") AS "population_total"
FROM "population__sum_1969_2020__raw" AS "r"
WHERE (
		"r"."STATE" = '17' AND "r"."COUNTY" IN ('119','133','163')
	OR
		"r"."STATE" = '29' AND "r"."COUNTY" IN ('071','099','183','189','510')
	)
GROUP BY "r"."YEAR", "r"."STATE", "r"."COUNTY"
ORDER BY "r"."YEAR", "r"."STATE", "r"."COUNTY";



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
