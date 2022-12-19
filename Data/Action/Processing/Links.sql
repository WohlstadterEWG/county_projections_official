/*
 *	  $Author: michaelw $
 *	  Created: October 13, 2022
 *	$Revision: $
 *	 $HeadURL: $
 *
 * Subject
 *	Create the Foreign Data Wrappers to Access Cohort Survival Model Data Stored in SQLite
 * 
 * Purpose
 *	This project is a cleanup of an externally developed workflow.  The end goal is to prepare the code and database for
 *	use by another member of the team.  Since they are unlikely to have PostgreSQL installed or have access to a database
 *	server, SQLite will be used for data storage.  However, in the development environment PostgreSQL is installed and
 *	available for use.  This link allows access to the SQLite database from within PostgreSQL.
 *
 * 
 * Dependencies
 * 	-
 *
 * Conversions
 *
 * Notes
 *	- The database path is dependent on the server context.
 *
 * Assumptions
 * 	- The sqlite_fdw extension is installed.
 * 
 * References
 * 	- https://github.com/pgspider/sqlite_fdw
 * 
 * TODO
 * 
 */


DROP SERVER IF EXISTS "cohort" CASCADE;

CREATE SERVER "cohort"
	FOREIGN DATA WRAPPER sqlite_fdw
	OPTIONS (database '/mnt/host/csm/Database.sqlite');

	

CREATE USER MAPPING FOR CURRENT_USER SERVER "cohort";


DROP SCHEMA IF EXISTS "cohort";

CREATE SCHEMA "cohort";

IMPORT FOREIGN SCHEMA "public"
	FROM SERVER "cohort"
	INTO "cohort";


-- Quick Test
SELECT COUNT(*) AS "forecast_count"
FROM "cohort"."population__forecast__projection";
