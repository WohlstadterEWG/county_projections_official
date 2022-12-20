#
#	  $Author: michaelw $
#	  Created: September 18, 2022
#		$Date: $
#	$Revision: $
#	 $HeadURL: $
#
# Subject
#	Download Census Counties and Prepare for Cohort Survival Model Analysis Evaluation
#
# Purpose
#	Pull the list of states and counties in the United States.  This script was originally developed by Matthew Hauer and
#	the analysis was performed on the entire United States.  That is no longer the intended use and thus the data pull
#	is rather vestigal.  Even though the technique to set the state and county lists is no longer relevant, the larger
#	goal to set the states and counties is retained.
#
#	This script is derived from the R code written by Mathew E. Hauer (see References).
#
# Output (datasets set for global use but not persistently stored)
#	- countynames
#	- statenames
#
# Dependencies
#
# Conversions
#
# Notes
#
# Assumptions
#	- This script is not designed to run independently and therefore assumes that it is called by a parent script that 
#	sets an appropriate environment including all the necessaries libraries.
# 
# References
#	- "Population Projections for U.S. Counties by Age, Sex, and Race Controlled to Shared Socioeconomic Pathway" by Mathew
#	E. Hauer
#
# TODO
#	- Check to see if data is already downloaded and use existing if present.  Possibly set flag (default to false) to
#	refresh.
#	- Change the entire download and process workflow to load the data into a local database server.  The data is more
#	efficiently sorted and grouped by a database server than by interconnected R scripts.  Since the volume of data is 
#	small, SQLite could be used as the local data repository.  A significant advantage is that the source and data remain
#	very portable from one workstation to another without incuring the significant costs required to maintain a database
#	server.
#	- Set an application level flag to reload the County entity.
#	- Refactor to be a load only script.  Extract preparation logic to new script or a preface in an existing script.
#
###############################################################################


###------FIPSCODES-----
## @knitr fipscodes


# Only download and create local entity if County does not exist.
if (!dbExistsTable(connection, 'county')) {
	counties <- read_csv(file = constants$source_census_county, col_names = FALSE) %>%
			mutate(geoid = paste0(X2, X3)) %>%			# was GEOID
			dplyr::rename(
					state_abbreviation = X1,			# was state
	                state_fips = X2,					# was STATEID
	                county_fips = X3,					# was CNTYID
	                county_name = X4,					# was NAME
					ansi_class = X5
			) %>%
			filter(!state_fips %in% c('60', '66', '69', '72', '74', '78'))		# Only for full country analysis.
			#filter(geoid %in% unlist(str_split(constants$analysis_county_list, ',')))

	dbExecute(connection, 'DROP TABLE IF EXISTS "county";')
	
	sql <- '
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
'
	
	dbExecute(connection, sql)
	
	sql <- '
INSERT INTO "county" ("geoid", "state_abbreviation", "state_fips", "county_fips", "county_name", "ansi_class")
VALUES (:geoid, :state_abbreviation, :state_fips, :county_fips, :county_name, :ansi_class);
'
	
	insert <- dbSendStatement(connection, sql)
	
	dbBind(
			insert,
			params = list(
					geoid = counties$geoid,
					state_abbreviation = counties$state_abbreviation,
					state_fips = counties$state_fips,
					county_fips = counties$county_fips,
					county_name = counties$county_name,
					ansi_class = counties$ansi_class
			)
	)
	
	dbClearResult(insert)
	
	rm(list = c('counties', 'insert'))
}

sql <- 'SELECT * FROM "county";'
	
counties <- dbGetQuery(connection, sql)

# States to generate projections for
state_fips = unlist(list(unique(counties$state_fips)))					# used to be stateid

geoids = unlist(list(unique(counties$geoid)))							# used to be GEOID

state_names <- group_by(counties, state_fips, state_abbreviation) %>%	# used to be statenames
		dplyr::summarise()

county_names <- group_by(counties, geoid, county_name, state_abbreviation) %>%	# used to be countynames
		dplyr::summarise()
