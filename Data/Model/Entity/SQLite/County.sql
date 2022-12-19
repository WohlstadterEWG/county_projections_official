/*
 *	  $Author: michaelw $
 *	  Created: October 10, 2022
 *		$Date: $
 *	$Revision: $
 *	 $HeadURL: $
 *
 * Subject
 *	Independent entity for Counties in the United States.
 *  
 * Purpose
 * 
 * Dependencies
 * 	-
 *
 * Notes
 *	- Data Source https://www2.census.gov/geo/docs/reference/codes/files/national_county.txt.
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

DROP TABLE IF EXISTS "county";


CREATE TABLE "county" (
	"id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	"geoid" CHARACTER(5) NOT NULL,
	"state_abbreviation" CHARACTER(2) NOT NULL,
	"state_fips" CHARACTER(2) NOT NULL,
	"county_fips" CHARACTER(3) NOT NULL,
	"county_name" VARYING CHARACTER(100) NOT NULL,
	"ansi_class" CHARACTER(2) NOT NULL,
	CONSTRAINT "NaturalKey" UNIQUE ("geoid"),
	CONSTRAINT "AlternateKey_GeoID" UNIQUE ("state_fips", "county_fips")
);



COMMIT;
