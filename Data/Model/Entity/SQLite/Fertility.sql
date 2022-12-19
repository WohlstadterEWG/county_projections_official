/*
 *	  $Author: michaelw $
 *	  Created: October 11, 2022
 *		$Date: $
 *	$Revision: $
 *	 $HeadURL: $
 *
 * Subject
 *	Independent Entity for Fertility Rates
 *  
 * Purpose
 * 
 * Dependencies
 * 	-
 *
 * Notes
 * 	- These values are derived from the CDC and Census population data using an ARIMA model to identify the trend.
 * 	- The gender column doesn't seem relevant, but is included in the original analysis.  It is retained for consistency
 * 	and "clarity".
 * 	- The "year" column is the last year in the series the trend was calculated from.
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


BEGIN TRANSACTION;

DROP TABLE IF EXISTS "fertility";


CREATE TABLE "fertility" (
	"id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	"year" CHARACTER(4) NOT NULL,
	"state_fips" CHARACTER(2) NOT NULL,
	"race" CHARACTER(1) NOT NULL,
	"gender" CHARACTER(1) NOT NULL,
	"rate" FLOAT NOT NULL,
	CONSTRAINT "AlternateKey_Race" UNIQUE ("year", "state_fips", "race", "gender")
);


COMMIT;
