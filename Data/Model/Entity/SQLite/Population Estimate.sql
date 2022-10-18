/*
 *	  $Author: michaelw $
 *	  Created: October 10, 2022
 *		$Date: $
 *	$Revision: $
 *	 $HeadURL: $
 *
 * Subject
 *	Subtype entities for CDC Population Estimates.
 *  
 * Purpose
 * 	There are two sets of estimates once of which is used for the evaluation analysis and the other for the projection
 * 	generation.  Creating a parent entity and subtyping these is more complex than is required for this project.  Thus
 * 	the two subtypes are just defined here as if they were two separte dependent entities.
 * 
 * Dependencies
 * 	-
 *
 * Notes
 *	- Data Source
 *		https://seer.cancer.gov/popdata/yr1969_2020.19ages/us.1969_2020.19ages.adjusted
 *		https://seer.cancer.gov/popdata/yr1990_2020.19ages/us.1990_2020.19ages.adjusted
 *	- The entity is somewhat denormalized in that the two fips columns can be derrived from the geoid.  This pattern is
 *	inconsistent across the entities and by the final iteration should be addressed.  The question to ask is, which representation
 *	is more relevant to the storage of the data.  Then refactor each of the entities to be consistent and denormalized.
 *	Finally, update the R code to construct any columns as relevant.
 *
 * Assumptions
 * 	-
 * 
 * References
 * 	- https://seer.cancer.gov/popdata/popdic.html (data dictionary)
 * 
 * TODO
 * 	-
 * 
 */


PRAGMA foreign_keys = 1;
PRAGMA journal_mode = TRUNCATE;


-- Evaluations
BEGIN TRANSACTION;

DROP TABLE IF EXISTS "population__estimate_cdc__evaluation";


CREATE TABLE "population__estimate_cdc__evaluation" (
	"id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	"year" CHARACTER(4) NOT NULL,
	"geoid" CHARACTER(5) NOT NULL,
	"state_abbreviation" CHARACTER(2) NOT NULL,
	"state_fips" CHARACTER(2) NOT NULL,
	"county_fips" CHARACTER(3) NOT NULL,
	"registry" CHARACTER(2) NOT NULL,
	"race" CHARACTER(1) NOT NULL,
	"origin" CHARACTER(1) NOT NULL,
	"gender" CHARACTER(1) NOT NULL,
	"age_bracket" CHARACTER(2) NOT NULL,
	"population" INTEGER NOT NULL,
	CONSTRAINT "AlternateKey_Age" UNIQUE ("year", "state_fips", "county_fips", "race", "gender", "age_bracket")
);

CREATE INDEX "population__estimate_cdc__evaluation_index_geoid"
	ON "population__estimate_cdc__evaluation" ("year", "geoid", "race", "gender", "age_bracket");


COMMIT;


-- Projections
BEGIN TRANSACTION;

DROP TABLE IF EXISTS "population__estimate_cdc__projection";


CREATE TABLE "population__estimate_cdc__projection" (
	"id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	"year" CHARACTER(4) NOT NULL,
	"geoid" CHARACTER(5) NOT NULL,
	"state_abbreviation" CHARACTER(2) NOT NULL,
	"state_fips" CHARACTER(2) NOT NULL,
	"county_fips" CHARACTER(3) NOT NULL,
	"registry" CHARACTER(2) NOT NULL,
	"race" CHARACTER(1) NOT NULL,
	"origin" CHARACTER(1) NOT NULL,
	"gender" CHARACTER(1) NOT NULL,
	"age_bracket" CHARACTER(2) NOT NULL,
	"population" INTEGER NOT NULL,
	CONSTRAINT "AlternateKey_Age" UNIQUE ("year", "state_fips", "county_fips", "race", "gender", "age_bracket")
);

CREATE INDEX "population__estimate_cdc__projection_index_geoid"
	ON "population__estimate_cdc__projection" ("year", "geoid", "race", "gender", "age_bracket");


COMMIT;
