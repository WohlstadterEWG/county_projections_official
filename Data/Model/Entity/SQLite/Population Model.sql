/*
 *	  $Author: michaelw $
 *	  Created: October 17, 2022
 *		$Date: $
 *	$Revision: $
 *	 $HeadURL: $
 *
 * Subject
 *	Subtype Entity for Shared Socioeconomic Pathways Population Projections
 *  
 * Purpose
 *	The Shared Socioeconomic Pathways (SSP) scenarios are used to adjust the Cohort Survival Model by different pathways.
 * 
 * Dependencies
 * 	-
 *
 * Notes
 *	- This model does not represent the full set of SSP attributes.  Model rows are limited to the USA region which in
 *	turn limits the model to "IIASA-WiC POP".  Each of the 5 scenarios used are coded to SSP1 through SSP5.  The logic
 *	is consistent with the workflow as described by Hauer.
 *	- Source populations are in millions and are not converted.
 *
 * Assumptions
 * 	-
 * 
 * References
#	- "Population Projections for U.S. Counties by Age, Sex, and Race Controlled to Shared Socioeconomic Pathway" by Mathew
#	E. Hauer
 * 
 * TODO
 * 	-
 * 
 */


PRAGMA foreign_keys = 1;
PRAGMA journal_mode = TRUNCATE;


BEGIN TRANSACTION;


DROP TABLE IF EXISTS "population__model__projection";

CREATE TABLE "population__model__projection" (
	"id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	"scenario" CHARACTER(4) NOT NULL,
	"year" CHARACTER(4) NOT NULL,
	"gender" CHARACTER(1) NOT NULL,
	"age_bracket" CHARACTER(2) NOT NULL,
	"population" FLOAT,
	CONSTRAINT "AlternateKey_Age" UNIQUE ("year", "scenario", "gender", "age_bracket")
);


COMMIT;
