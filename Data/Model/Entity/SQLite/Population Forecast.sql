/*
 *	  $Author: michaelw $
 *	  Created: October 11, 2022
 *		$Date: $
 *	$Revision: $
 *	 $HeadURL: $
 *
 * Subject
 *	Subtype entities for Generated Population Projections.
 *  
 * Purpose
 *	There are two sets of projections one of which is used for the evaluation analysis and the other for the cohort analysis.
 *	Creating a parent entity and subtyping these is more complex than is required for this project.  Thus the two subtypes
 *	are just defined here as if they were two separte dependent entities.
 * 
 * Dependencies
 * 	-
 *
 * Notes
 *
 * Assumptions
 * 	-
 * 
 * References
 * 	-
 * 
 * TODO
 * 	-
 * 
 */


PRAGMA foreign_keys = 1;
PRAGMA journal_mode = TRUNCATE;


-- Evaluations
BEGIN TRANSACTION;


DROP TABLE IF EXISTS "population__forecast__evaluation";

CREATE TABLE "population__forecast__evaluation" (
	"id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	"year" CHARACTER(4) NOT NULL,
	"geoid" CHARACTER(5) NOT NULL,
	"race" CHARACTER(1) NOT NULL,
	"gender" CHARACTER(1) NOT NULL,
	"age_bracket" CHARACTER(2) NOT NULL,
	"type" CHARACTER(10) NOT NULL,
	"projection" FLOAT,
	"projection_low" FLOAT,
	"projection_high" FLOAT,
	CONSTRAINT "AlternateKey_Age" UNIQUE ("year", "geoid", "race", "gender", "age_bracket", "type")
);

CREATE INDEX "population__forecast__evaluation_index_geoid"
	ON "population__forecast__evaluation" ("geoid", "race", "gender", "age_bracket", "type");


COMMIT;


-- Projections
BEGIN TRANSACTION;


DROP TABLE IF EXISTS "population__forecast__projection";

CREATE TABLE "population__forecast__projection" (
	"id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	"year" CHARACTER(4) NOT NULL,
	"geoid" CHARACTER(5) NOT NULL,
	"race" CHARACTER(1) NOT NULL,
	"gender" CHARACTER(1) NOT NULL,
	"age_bracket" CHARACTER(2) NOT NULL,
	"type" CHARACTER(10) NOT NULL,
	"projection" FLOAT,
	"projection_low" FLOAT,
	"projection_high" FLOAT,
	CONSTRAINT "AlternateKey_Age" UNIQUE ("year", "geoid", "race", "gender", "age_bracket", "type")
);

CREATE INDEX "population__forecast__projection_index_geoid"
	ON "population__forecast__projection" ("geoid", "race", "gender", "age_bracket", "type");


COMMIT;
