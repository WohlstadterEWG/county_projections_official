#
#	  $Author: michaelw $
#	  Created: September 18, 2022
#		$Date: $
#	$Revision: $
#	 $HeadURL: $
#
# Subject
#	Download Census Population Estimates and Prepare for Cohort Survival Model Analysis Projection
#
# Purpose
#	This script downloads and prepares the data required to generate the projections.  Using the Census 2000 and 2010 base
#	data, population data are prepared to be used to generate projections for the years 2020 through 2100.  The data is
#	not used directly by this script rather this script stores the processed estimates in CSV files for use in other scripts.
#	
#	This script is derived from the R code written by Mathew E. Hauer (see References).
#
# Output
#	- population__group_quarters (Group Quarters populations for 2000 and 2010)
#
# Dependencies
#	- censusapi
#	- here
#	- properties
#	- tidycensus
#	- tidyverse
#	- tigris
#
# Conversions
#
# Notes
#
# Assumptions
#	- This script does not depend on the previous execution of other scripts and in fact clears the environment as the 
#	first step.  However, it does assume that all the relevant libraries have been installed are are ready to be loaded.
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
#	- There are several aspects of this script that are redundant and should be refactored to eliminate the redundancy.
#	- Review which variables are actually required and limit to just those variables.
#	- Refactor to be a load only script.  Extract preparation logic to new script or a preface in an existing script.
#	- Trim unneccessary columns from "variables".
#	- Recode "race" and "gender" to be consistent with the other tables.
#
###############################################################################



source('./Script/000-Libraries.R')      # loading in the libraries
source('./Script/001-fipscodes.R')      # Getting a Fips List


asc <- function(char, simplify = TRUE) {
	sapply(char, function(x) strtoi(charToRaw(x), 16L), simplify = simplify)
}

chr <- function(ascii) sapply(ascii, function(x) rawToChar(as.raw(x)))

get_group_quarters = function(state_fips, year) {
	tryCatch(
			{
				
				# Getting the census data from the API
				pull_census <- function(state_fips, year, variables, prefix, metadata) {
					
					population <- getCensus(
								name = "dec/sf1", # This is the Estimates datafile
								vintage = year, # Vintage year is set to the variable set above
								key = key, # inputting my Census API key
								vars = variables, # gathering these variables
								region = "COUNTY:*",
								regionin = paste0("state:", state_fips)
						) %>%
						dplyr::rename(
								state_fips = state,
								county_fips = county,
								county_name = NAME
						) %>%
						pivot_longer(cols = starts_with(prefix), names_to = 'variable', values_to = 'total') %>%
						left_join(metadata, by = c('variable' = 'name')) %>%
						mutate(race_code = substr(variable, nchar(prefix) + 1, nchar(prefix) + 1)) %>%
						separate(label, c('drop', 'gender', 'age_range'), sep = '!!') %>%
						separate(age_range, c('age_label', 'drop'), sep = " t") %>%
						mutate(
								age_break = case_when(
										age_label == "Under 5 years" ~ '0',
										age_label == "18 and 19 years" ~ '15',
										age_label == "20 years" ~ '20',
										age_label == "21 years" ~ '20',
										age_label == "22" ~ '20',
										age_label == "60 and 61 years" ~ '60',
										age_label == "62" ~ '60',
										age_label == "65 and 66 years" ~ '65',
										age_label == "67" ~ '65',
										age_label == "85 years and over" ~ '85',
										TRUE ~ age_label
								),
								race_label = case_when(
										race_code == "B" ~ "BLACK, NH",
										race_code %in% c("C", "D", "E", "F", "G") ~ "OTHER, NH",
										race_code == "H" ~ "HISPANIC",
										race_code == "I" ~ "WHITE, NH"
								)
						) %>%
						mutate(age_break = as.integer(age_break)) %>%
						select(state_fips, county_fips, gender, race_label, age_break, total) %>%
						group_by(state_fips, county_fips, gender, race_label, age_break) %>%		# , county_name
						dplyr::summarise(total = sum(total))
				
					return(population)
					
				}
				
				# listing the available census variables in the population estimates agegroups data file
				parts <- NULL
				for (i in asc('B'):asc('I')) {
					parts <- c(parts, paste0(chr(i), sprintf('%03d', c(3:25, 27:49))))
				}
				
				variables_population <- c(paste0('P012', parts), 'COUNTY', 'NAME')
				variables_household <- c(paste0('PCT013', parts), 'COUNTY', 'NAME')
				
				metadata <- listCensusMetadata(name = "dec/sf1", vintage = year, type = 'variables')
				
				population <- pull_census(state_fips, year, variables_population, 'P012', metadata)
				household <- pull_census(state_fips, year, variables_household, 'PCT013', metadata)
				
				
				joined <- left_join(
								population, household,
								by = c('state_fips', 'county_fips', 'gender', 'race_label', 'age_break'),
								suffix = c('.population', '.household')
						) %>%
						ungroup() %>%
						mutate(
								population = total.population - total.household,
								year = year,
								gender = case_when(
										gender == "Female" ~ "FEMALE",
										gender == "Male" ~ "MALE"
								),
								age_bracket = case_when(
										age_break == 0 ~ '01',
										age_break == 5 ~ '02',
										age_break == 10 ~ '03',
										age_break == 15 ~ '04',
										age_break == 20 ~ '05',
										age_break == 25 ~ '06',
										age_break == 30 ~ '07',
										age_break == 35 ~ '08',
										age_break == 40 ~ '09',
										age_break == 45 ~ '10',
										age_break == 50 ~ '11',
										age_break == 55 ~ '12',
										age_break == 60 ~ '13',
										age_break == 65 ~ '14',
										age_break == 70 ~ '15',
										age_break == 75 ~ '16',
										age_break == 80 ~ '17',
										age_break == 85 ~ '18'
								)
						) %>%
						dplyr::rename(race = race_label) %>%
						dplyr::select(-age_break, -total.population, -total.household)
				
			return(joined)
			
		},
		error = function(e) { cat("ERROR :", conditionMessage(e), "\n") }
	)
}



if (!dbExistsTable(connection, 'population__group_quarters')) {
	dbExecute(connection, 'DROP TABLE IF EXISTS "population__group_quarters";')
	
	sql <- '
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
'
	
	dbExecute(connection, sql)
	
	sql <- '
INSERT INTO "population__group_quarters" (
	"year", "state_fips", "county_fips", "race", "gender", "age_bracket", "population"
)
VALUES (
	:year, :state_fips, :county_fips, :race, :gender, :age_bracket, :population
);
'
	
	insert <- dbSendStatement(connection, sql)
	
	data <- pbmclapply(state_fips, get_group_quarters, '2010', mc.cores = cores)
	group_quarters <- rbindlist(data)
	
	dbBind(
			insert,
			params = list(
					year = group_quarters$year,
					state_fips = group_quarters$state_fips,
					county_fips = group_quarters$county_fips,
					race = group_quarters$race,
					gender = group_quarters$gender,
					age_bracket = group_quarters$age_bracket,
					population = group_quarters$population
			)
	)
	
	data <- pbmclapply(state_fips, get_group_quarters, '2000', mc.cores = cores)
	group_quarters <- rbindlist(data)
	
	dbBind(
			insert,
			params = list(
					year = group_quarters$year,
					state_fips = group_quarters$state_fips,
					county_fips = group_quarters$county_fips,
					race = group_quarters$race,
					gender = group_quarters$gender,
					age_bracket = group_quarters$age_bracket,
					population = group_quarters$population
			)
	)
	
	dbClearResult(insert)
	
	rm(list = c('group_quarters', 'insert'))
}

dbDisconnect(connection)
