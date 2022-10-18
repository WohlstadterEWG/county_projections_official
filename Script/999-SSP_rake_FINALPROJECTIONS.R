#
#	  $Author: michaelw $
#	  Created: September 26, 2022
#		$Date: $
#	$Revision: $
#	 $HeadURL: $
#
# Subject
#	Final Population Projection Logic
#
# Purpose
#	
#	This script is derived from the R code written by Mathew E. Hauer (see References).
#
# Output
#
# Dependencies
#	- 000-Libraries.R
#	- 001-fipscodes.R 
#	- 003-proj_basedataloa.R
#
# Conversions
#
# Notes
#
# Assumptions
# 
# References
#	- "Population Projections for U.S. Counties by Age, Sex, and Race Controlled to Shared Socioeconomic Pathway" by Mathew
#	E. Hauer
#	- https://iiasa.ac.at/models-and-data/shared-socioeconomic-pathways-scenario-database
#
# TODO
#
###############################################################################



source('./Script/000-Libraries.R')      # loading in the libraries


if (!dbExistsTable(connection, 'population__model__projection')) {
	pathways <- read_csv(paste(path_data, 'SspDb_country_data_2013-06-12.csv', sep = delimiter_path),) %>%
			filter(REGION == "USA", grepl("Population", VARIABLE)) %>%
			separate(VARIABLE, c("VARIABLE", "VARIABLE1", "VARIABLE2", "VARIABLE3", "VARIABLE4"), sep = '\\|')
	
	pathways <- pathways %>%
		dplyr::select(-`1950`:-`2010`, -`2105`:-`2150`) %>%
		mutate(
				gender = case_when(
						VARIABLE1 == "Female" ~ '2',
						VARIABLE1 == "Male" ~ '1'
				),
				age_bracket = case_when(
						VARIABLE2 == 'Aged0-4' ~ '01',
						VARIABLE2 == 'Aged5-9' ~ '02',
						VARIABLE2 == 'Aged10-14' ~ '03',
						VARIABLE2 == 'Aged15-19' ~ '04',
						VARIABLE2 == 'Aged20-24' ~ '05',
						VARIABLE2 == 'Aged25-29' ~ '06',
						VARIABLE2 == 'Aged30-34' ~ '07',
						VARIABLE2 == 'Aged35-39' ~ '08',
						VARIABLE2 == 'Aged40-44' ~ '09',
						VARIABLE2 == 'Aged45-49' ~ '10',
						VARIABLE2 == 'Aged50-54' ~ '11',
						VARIABLE2 == 'Aged55-59' ~ '12',
						VARIABLE2 == 'Aged60-64' ~ '13',
						VARIABLE2 == 'Aged65-69' ~ '14',
						VARIABLE2 == 'Aged70-74' ~ '15',
						VARIABLE2 == 'Aged75-79' ~ '16',
						VARIABLE2 == 'Aged80-84' ~ '17',
						VARIABLE2 == 'Aged85-89' ~ '18',
						VARIABLE2 == 'Aged90-94' ~ '18',
						VARIABLE2 == 'Aged95-99' ~ '18',
						VARIABLE2 == 'Aged100+' ~ '18'
				),
				scenario = case_when(
						grepl("SSP1", SCENARIO) ~ "SSP1",
						grepl("SSP2", SCENARIO) ~ "SSP2",
						grepl("SSP3", SCENARIO) ~ "SSP3",
						grepl("SSP4", SCENARIO) ~ "SSP4",
						grepl("SSP5", SCENARIO) ~ "SSP5"
				)
		) %>%
		filter(is.na(VARIABLE4), !is.na(VARIABLE3), !is.na(VARIABLE2)) %>%
		dplyr::select(-MODEL:-UNIT) %>%
		na.omit %>%
		gather(year, population, `2015`:`2100`) %>%
		group_by(gender, age_bracket, scenario, year) %>%
		dplyr::summarise(population = sum(population)) %>%
		ungroup()
	
#	write_csv(pathways, paste(path_data, 'Processed', 'SSP_01_prepared.csv', sep = delimiter_path))
	
	
	dbExecute(connection, 'DROP TABLE IF EXISTS "population__model__projection";')
	
	
	sql <- '
CREATE TABLE "population__model__projection" (
	"id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	"scenario" CHARACTER(4) NOT NULL,
	"year" CHARACTER(4) NOT NULL,
	"gender" CHARACTER(1) NOT NULL,
	"age_bracket" CHARACTER(2) NOT NULL,
	"population" FLOAT,
	CONSTRAINT "AlternateKey_Age" UNIQUE ("year", "scenario", "gender", "age_bracket")
);
'
	
	dbExecute(connection, sql)
	
	
	sql <- '
INSERT INTO "population__model__projection" (
	"scenario", "year", "gender", "age_bracket", "population" 
)
VALUES (
	:scenario, :year, :gender, :age_bracket, :population
);
'
	
	insert <- dbSendStatement(connection, sql)
	
	dbBind(insert,
			params = list(
					scenario = pathways$scenario,
					year = pathways$year,
					gender = pathways$gender,
					age_bracket = pathways$age_bracket,
					population = pathways$population
			)
	)
	
	dbClearResult(insert)
}


sql <- '
SELECT "year", "scenario", "gender", "age_bracket", "population"
FROM "population__model__projection"
ORDER BY "year", "gender", "age_bracket", "scenario";
'

pathways <- dbGetQuery(connection, sql)

pathways <- pathways %>%
		filter(as.integer(year) >= 2020 & as.integer(year) <= 2100) %>%
		pivot_wider(names_from = scenario, values_from = population)


#source('./Script/001-fipscodes.R')      # Getting a Fips List

#source('./Script/003-proj_basedataload.R')   # loading the base data


sql <- '
SELECT "f"."year", "f"."geoid", "f"."gender", "f"."race", "f"."age_bracket",
	SUM("f"."projection_a") AS "population"
FROM "population__forecast__projection" AS "f"
WHERE (
		"f"."geoid" IN (\'17119\',\'17133\',\'17163\')
	OR
		"f"."geoid" IN (\'29071\',\'29099\',\'29183\',\'29189\',\'29510\')
	)
	AND "f"."type" = :method AND "f"."year" >= :year_begin AND "f"."year" <= :year_end
GROUP BY "f"."year", "f"."geoid", "f"."gender", "f"."race", "f"."age_bracket"
'

select <- dbSendStatement(connection, sql)

dbBind(select,
		params = list(
				method = 'ADD',
				year_begin = constants$analysis_year_start_projection,
				year_end = as.character(as.integer(constants$analysis_year_start_projection) + forecast_length)
		)
)
projections_additive <- dbFetch(select)

dbBind(select,
		params = list(
				method = 'Mult',
				year_begin = constants$analysis_year_start_projection,
				year_end = as.character(as.integer(constants$analysis_year_start_projection) + forecast_length)
		)
)
projections_multiplicative <- dbFetch(select)

dbClearResult(select)

#write_csv(projections_additive, paste(path_data, 'Processed', 'Projection_additive.csv', sep = delimiter_path))
#write_csv(projections_multiplicative, paste(path_data, 'Processed', 'Projection_multiplicative.csv', sep = delimiter_path))


sql <- '
SELECT "f"."year", "f"."geoid", "f"."gender", "f"."race", "f"."age_bracket",
	SUM("f"."projection_a") AS "population"
FROM "population__estimate_cdc__projection" AS "f"
WHERE (
		"f"."geoid" IN (\'17119\',\'17133\',\'17163\')
	OR
		"f"."geoid" IN (\'29071\',\'29099\',\'29183\',\'29189\',\'29510\')
	)
	AND "f"."type" = :method AND "f"."year" >= :year_begin AND "f"."year" <= :year_end
GROUP BY "f"."year", "f"."geoid", "f"."gender", "f"."race", "f"."age_bracket"
'

select <- dbSendStatement(connection, sql)

dbBind(select,
		params = list(
				method = 'ADD',
				year_begin = constants$analysis_year_start_projection,
				year_end = as.character(as.integer(constants$analysis_year_start_projection) + forecast_length)
		)
)
projections_additive <- dbFetch(select)


sql <- '
SELECT "e"."geoid", "e"."race",
	SUM("e"."population") AS "population"
FROM "population__estimate_cdc__projection" AS "e"
WHERE (
		"e"."geoid" IN (\'17119\',\'17133\',\'17163\')
	OR
		"e"."geoid" IN (\'29071\',\'29099\',\'29183\',\'29189\',\'29510\')
	)
	AND "e"."year" = :year
GROUP BY "e"."geoid", "e"."race";
'

select <- dbSendStatement(connection, sql)

dbBind(select,
		params = list(
				year = constants$analysis_year_start_projection
		)
)

projections_check <- dbFetch(select)


projections <- left_join(
				projections_additive, projections_multiplicative,
				by = c('year', 'geoid', 'gender', 'race', 'age_bracket'),
				suffix = c('.additive', '.multiplicative')
		)

# Compares the CCD projection against the future population to determine direction.  Increasing population uses the additive
# method (CCD) and decreasing population uses the multiplicative (CCR) method.
changes <- projections_additive %>%
		filter(year == as.character(as.integer(constants$analysis_year_start_projection) + forecast_length)) %>%
		group_by(geoid, race) %>%
		dplyr::summarise(
				population_additive = sum(population)
		) %>%
		left_join(projections_check, by = c('geoid', 'race')) %>%
		mutate(
				type = if_else(
						population_additive >= population, 'additive', 'multiplicative'
				)
		) %>%
		select(-population_additive, -population)

#write_csv(projections, paste(path_data, 'Processed', 'Projection_preprocess.csv', sep = delimiter_path))


projections <- left_join(projections, changes, by = c('geoid', 'race')) %>%
		mutate(population.change = if_else(type == 'additive', population.additive, population.multiplicative)) %>%
		select(-population.additive, -population.multiplicative, -type) %>%
		rename(
				population = population.change
		)

#write_csv(projections, paste(path_data, 'Processed', 'Projection_combined.csv', sep = delimiter_path))


# Set the "Middle of the Road" (SSP2) as the baseline pathway and adjust the population by the ratio to SSP2.
projections <- left_join(projections, pathways, by = c('year', 'gender', 'age_bracket')) %>%
		mutate(
				population_ssp1 = population * (SSP1 / SSP2),
				population_ssp2 = population * (SSP2 / SSP2),
				population_ssp3 = population * (SSP3 / SSP2),
				population_ssp4 = population * (SSP4 / SSP2),
				population_ssp5 = population * (SSP5 / SSP2)
		) %>%
		select(-population, -(SSP1:SSP5))

write_csv(projections, paste(path_data, 'Processed', 'SSP_asrc.csv', sep = delimiter_path))


dbDisconnect(connection)
