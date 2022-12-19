#
#	  $Author: michaelw $
#	   Forked: September 18, 2022
#		$Date: $
#	$Revision: $
#	 $HeadURL: $
#
# Subject
#	Download CDC Population Estimates and Prepare for Cohort Survival Model Analysis Projection
#
# Purpose
#	This script downloads and prepares the data required to generate the projections.  Using the CDC 1990 - 2020 base data,
#	population data are prepared to be used to generate projections for the years 2020 through 2100.  The data is not used
#	directly by this script rather this script is called from other scripts that depend upon the initialized data frames.
#	
#	This script is derived from the R code written by Mathew E. Hauer (see References).
#
# Output
#	Persistent Storage
#		- population__estimate_cdc__projection (Population Estimates for each year in the range 1969 to 2000)
#	Memory Storage
#	- estimates (Population Estimates for each year in the range 1990 to 2000 - read from persistent storage)
#	- estimates_projection_baseline (Population Estimates for the year 2020)
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
#	- Refactor to be a load only script.  Extract preparation logic to new script or a preface in an existing script.
#
###############################################################################


###------DATA LOAD-----
## @knitr projbasedata


# Setting the groupings
group_list <- c('geoid', 'year', 'age_bracket', 'race', 'gender')


# TEST YEAR IS SET TO 2015 (is used in 005, 006, and 007)
year_start <- constants$analysis_year_start_projection

# LAUNCH YEAR IS THE SAME AS THE TEST YEAR
year_baseline <- year_start

# THE NUMBER OF AGE GROUPS
age_bracket_count <- 18

# NUMBER OF PROJECTION STEPS
projection_step_count <- (as.integer(constants$analysis_year_end_projection) - as.integer(year_baseline)) / 5

forecast_length <- projection_step_count * 5


# This should probably be generated from a template 'us.{year_base}_{year_current}.19ages.adjusted'.
# URL in the download should also be generated from an appropriate template.
if (!dbExistsTable(connection, 'population__estimate_cdc__projection')) {
	file <- constants$source_cdc_population_projection_file
	
	download.file(
			paste(constants$source_cdc_population_projection_host, paste(file, 'txt.gz', sep = '.'), sep = '/'),
			paste(path_data, paste(file, 'txt.gz', sep = '.'), sep = delimiter_path)
	)
	gunzip(paste(path_data, paste(file, 'txt.gz', sep = '.'), sep = delimiter_path), overwrite = TRUE, remove = TRUE)
	
	estimates <- read.table(paste(path_data, paste(file, 'txt', sep = '.'), sep = delimiter_path))
	
	# Parse the Downloaded Data
	estimates$year <- substr(estimates$V1, 1, 4)
	estimates$state_abbreviation <- substr(estimates$V1, 5, 6)
	estimates$state_fips <- substr(estimates$V1, 7, 8)
	estimates$county_fips <- substr(estimates$V1, 9, 11)
	estimates$registry <- substr(estimates$V1, 12, 13)
	estimates$race <- substr(estimates$V1, 14, 14)
#	estimates$race[estimates$race == '3'] <- '4'							# Reset Hispanic (based on origin)
	estimates$origin <- substr(estimates$V1, 15, 15)
	estimates$gender <- substr(estimates$V1, 16, 16)
	estimates$age_bracket <- substr(estimates$V1, 17, 18)
	#estimates$age_bracket[estimates$age_bracket == '00'] <- '01'			# Collapse newborns into 1-4 bracket
	estimates$population <- as.integer(substr(estimates$V1, 19, 30))
	
	# Generate Key Columns
	estimates$geoid <- paste0(estimates$state_fips, estimates$county_fips)
	
	dbExecute(connection, 'DROP TABLE IF EXISTS "population__estimate_cdc__projection";')
	
	
	sql <- '
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
	"population" INTEGER NOT NULL --,
--	CONSTRAINT "AlternateKey_Age" UNIQUE ("year", "state_fips", "county_fips", "race", "gender", "age_bracket")
);
'
	
	dbExecute(connection, sql)
	
	
	# This process takes a long time at work.  Run it overnight.
	sql <- '
INSERT INTO "population__estimate_cdc__projection" (
	"year", "geoid", "state_abbreviation", "state_fips", "county_fips",
	"registry", "race", "origin", "gender", "age_bracket",
	"population"
)
VALUES (
	:year, :geoid, :state_abbreviation, :state_fips, :county_fips,
	:registry, :race, :origin, :gender, :age_bracket,
	:population
);
'
	
	insert <- dbSendStatement(connection, sql)
	
	dbBind(
			insert,
			params = list(
					year = estimates$year,
					geoid = estimates$geoid,
					state_abbreviation = estimates$state_abbreviation,
					state_fips = estimates$state_fips,
					county_fips = estimates$county_fips,
					registry = estimates$registry,
					race = estimates$race,
					origin = estimates$origin,
					gender = estimates$gender,
					age_bracket = estimates$age_bracket,
					population = estimates$population
			)
	)
	
	dbClearResult(insert)
	
	
	sql <- '
CREATE INDEX "population__estimate_cdc__projection_index_geoid"
	ON "population__estimate_cdc__projection" ("year", "geoid", "race", "gender", "age_bracket");
'
	
	dbExecute(connection, sql)
	
	rm(list = c('estimates', 'insert'))
}

sql <- '
SELECT "e"."year", "e"."geoid", "e"."race", "e"."gender", "e"."age_bracket",
	SUM("e"."population") AS "population"
FROM "population__estimate_cdc__projection" AS "e"
-- WHERE "e"."year" = :year
GROUP BY "e"."year","e"."geoid", "e"."race", "e"."gender", "e"."age_bracket";
'

estimates <- dbGetQuery(connection, sql)


# THE DATA NEED TO BE AGGREGATED TO THE LEVEL OF ANALYSIS BASED ON THE GROUPING FROM ABOVE. THIS IS TO SUM THE 0 AND 1-4 AGE GROUPS
# INTO THE 0-4 AGE GROUP
estimates$race[estimates$race == '3'] <- '4'
estimates$race[estimates$origin == '1'] <- '3'					# Set Hispanic based upon origin = Hispanic (review paper)
estimates$age_bracket[estimates$age_bracket == '00'] <- '01'

estimates %>%
		group_by(across(all_of(group_list))) %>%
		dplyr::summarise(population = sum(population))


# SEPARATING OUT THE LAUNCH POPULATION AND SUMMING TO THE COUNTY TOTAL.
estimates_projection_baseline <- estimates[which(estimates$year == year_baseline),] %>%
		group_by(geoid) %>%
		dplyr::summarise(population = sum(population)) %>%
		ungroup()
