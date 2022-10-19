#
#	  $Author: michaelw $
#	  Created: September 18, 2022
#		$Date: $
#	$Revision: $
#	 $HeadURL: $
#
# Subject
#	Access Census Population Estimates and Generate Fertility Rates by State
#
# Purpose
#	This script processes the CDC population estimates from 1969 to 2020 to generate the fertility rates.  The data is
#	not used directly by this script rather this script stores the processed estimates in CSV files for use in other scripts.
#	
#	This script is derived from the R code written by Mathew E. Hauer (see References).
#
# Output
#	- fertility (Fertility rates as a ratio of newborns and women of childbearing years)
#
# Dependencies
#	- 000-Libraries.R
#	- 001-fipscodes.R 
#	- 002-basedataload.R
#
# Conversions
#
# Notes
#	- Fertility rates to be used with evaulations are keyed on the evaluation end year.
#	- Fertility rates to be used with projections are keyed on the projection end year.
#
# Assumptions
# 
# References
#	"Population Projections for U.S. Counties by Age, Sex, and Race Controlled to Shared Socioeconomic Pathway" by Mathew
#	E. Hauer
#
# TODO
#	- The coding style is somewhat obtuse and much of the data is shared through public variables.  Redesign the workflow.
#	- Refactor to eliminate redundancy.
#	- If a global storage is to be used, more clearly define what is global and what is not.
#
###############################################################################



###################
### DATA PREP
##################
source('./Script/000-Libraries.R')      # loading in the libraries



if (!dbExistsTable(connection, 'fertility')) {
	source('./Script/001-fipscodes.R')      # Getting a Fips List
	
	# Initialize Storage
	dbExecute(connection, 'DROP TABLE IF EXISTS "fertility";')
	
	sql <- '
CREATE TABLE "fertility" (
	"id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	"year" CHARACTER(4) NOT NULL,
	"state_fips" CHARACTER(2) NOT NULL,
	"race" CHARACTER(1) NOT NULL,
	"gender" CHARACTER(1) NOT NULL,
	"rate" FLOAT NOT NULL,
	CONSTRAINT "AlternateKey_Race" UNIQUE ("year", "state_fips", "race", "gender")
);
'
	
	dbExecute(connection, sql)
	
	# Fertility Rate Determination
	
	# 2000 to 2020
	source('./Script/002-basedataload.R')   # loading the base data
	
	# The variable "group_list" is set in 002.
	estimates <- estimates %>%
			group_by(across(all_of(group_list))) %>%
			dplyr::summarise(population = sum(population))
	
	estimates <- mutate(estimates, state_fips = substr(geoid, 1, 2))
	
	races <- unique(estimates$race)
	
	fertility <- data.frame()
	
	# The variable "state_fips" is defined in 002.  There should be a more obvious "global" store for this.
	for (this.state in state_fips) {
		for (this.race in races) {
			population_race <- estimates[which(estimates$state_fips == this.state & estimates$race == this.race),] %>%
					group_by(year, state_fips, race, gender, age_bracket) %>%
					dplyr::summarise(population = sum(population)) %>%
					ungroup()
					
			population_newborns <- population_race %>%
					filter(
							age_bracket == '01'
					) %>%
					group_by(state_fips, race, year) %>%
					dplyr::summarise(newborns = sum(population))
			
			population_women_childbearing <- population_race %>%
					filter(
							age_bracket %in% c('04', '05', '06', '07', '08', '09', '10'),
							gender == '2'
					) %>%
					group_by(state_fips, year) %>%
					dplyr::summarise(women_childbearing = sum(population)) %>%
					left_join(., population_newborns) %>%
					mutate(newborn_ratio = newborns / women_childbearing) %>%
					filter(year <= constants$analysis_year_start_evaluation)
			
			population_women_childbearing[mapply(is.infinite, population_women_childbearing)] <- NA
			population_women_childbearing[mapply(is.nan, population_women_childbearing)] <- NA
			population_women_childbearing[is.na(population_women_childbearing)] <- 0
			
			# The variable "forecast_length" should be more clearly defined (i.e. more obvious global store).
			years <- seq(1, forecast_length)
			
			rate <- as_tibble(
					forecast(
							arima(population_women_childbearing$newborn_ratio, order = arima_order),
							h = forecast_length
					)$mean[c(years)])
			
			fertility <- rbind(
					fertility,
					rate %>% mutate(state_fips = this.state, race = this.race, gender = '2')
			)
		}
	}
	
	sql <- '
INSERT INTO "fertility" (
	"year", "state_fips", "race", "gender", "rate"
)
VALUES (
	:year, :state_fips, :race, :gender, :rate
);
'
	
	insert <- dbSendStatement(connection, sql)
	
	fertility <- unique(fertility)
	fertility$year <- constants$analysis_year_end_evaluation
	
	dbBind(
			insert,
			params = list(
					year = fertility$year,
					state_fips = fertility$state_fips,
					race = fertility$race,
					gender = fertility$gender,
					rate = fertility$value
			)
	)
	
	dbClearResult(insert)
	
	
	# 2020 to 2100
	source('./Script/003-proj_basedataload.R')
	
	# The variable "group_list" is set in 003.
	estimates <- estimates %>%
			group_by(across(all_of(group_list))) %>%
			dplyr::summarise(population = sum(population))
	
	estimates <- mutate(estimates, state_fips = substr(geoid, 1, 2))
	
	races <- unique(estimates$race)
	
	fertility <- data.frame()
	
	for (this.state in state_fips) {
		for (this.race in races) {
			population_race <- estimates[which(estimates$state_fips == this.state & estimates$race == this.race),] %>%
					group_by(year, state_fips, race, gender, age_bracket) %>%
					dplyr::summarise(population = sum(population)) %>%
					ungroup()
			
			population_newborns <- population_race %>%
					filter(
							age_bracket == '01'
					) %>%
					group_by(state_fips, race, year) %>%
					dplyr::summarise(newborns = sum(population))
			
			population_women_childbearing <- population_race %>%
					filter(
							age_bracket %in% c('04', '05', '06', '07', '08', '09', '10'),
							gender == '2'
					) %>%
					group_by(state_fips, year) %>%
					dplyr::summarise(women_childbearing = sum(population)) %>%
					left_join(., population_newborns) %>%
					mutate(newborn_ratio = newborns / women_childbearing) %>%
					filter(year <= constants$analysis_year_start_projection)
			
			population_women_childbearing[mapply(is.infinite, population_women_childbearing)] <- NA
			population_women_childbearing[mapply(is.nan, population_women_childbearing)] <- NA
			population_women_childbearing[is.na(population_women_childbearing)] <- 0

			
			# The variable "forecast_length" is defined in 003.
			years <- seq(1, forecast_length)
			
			rate <- as_tibble(
					forecast(
							arima(population_women_childbearing$newborn_ratio, order = arima_order),
							h = forecast_length
					)$mean[c(years)])
			
			fertility <- rbind(
					fertility,
					rate %>% mutate(state_fips = this.state, race = this.race, gender = '2')
			)
		}
	}
	
	fertility <- unique(fertility)
	fertility$year <- constants$analysis_year_end_projection
	
	sql <- '
INSERT INTO "fertility" (
	"year", "state_fips", "race", "gender", "rate"
)
VALUES (
	:year, :state_fips, :race, :gender, :rate
);
'
	
	insert <- dbSendStatement(connection, sql)
	
	dbBind(
			insert,
			params = list(
					year = fertility$year,
					state_fips = fertility$state_fips,
					race = fertility$race,
					gender = fertility$gender,
					rate = fertility$value
			)
	)
	
	dbClearResult(insert)
	
	rm(list = c('fertility', 'insert'))
}

dbDisconnect(connection)
