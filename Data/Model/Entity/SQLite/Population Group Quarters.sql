/*
 *	  $Author: michaelw $
 *	  Created: October 11, 2022
 *		$Date: $
 *	$Revision: $
 *	 $HeadURL: $
 *
 * Subject
 *	Subtype entities for Census Group Quarters Population.
 *  
 * Purpose
 * 
 * Dependencies
 * 	-
 *
 * Notes
 *	- Data Source
 *		U.S. Census via api dec/sf1
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

DROP TABLE IF EXISTS "population__group_quarters";


CREATE TABLE "population__group_quarters" (
	"id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	"year" CHARACTER(4) NOT NULL,
	"state_fips" CHARACTER(2) NOT NULL,
	"county_fips" CHARACTER(3) NOT NULL,
	"race" VARYING CHARACTER(15) NOT NULL,
	"gender" VARYING CHARACTER(10) NOT NULL,
	"age_bracket" CHARACTER(2) NOT NULL,
	"population" INTEGER NOT NULL,
	CONSTRAINT "AlternateKey_age" UNIQUE ("year", "state_fips", "county_fips", "race", "gender", "age_bracket")
);


COMMIT;
