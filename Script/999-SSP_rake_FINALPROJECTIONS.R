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
#	- 002-basedataload.R	- Maybe.  It is not referenced in the original Hauer code, but the data frame is referenced below
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
source('./Script/001-fipscodes.R')      # Getting a Fips List
# 002 is not called in original 999 script.  However K05_launch2 is referenced below.  That data table is created in 002.
source('./Script/002-basedataload.R')   # loading the base data
source('./Script/003-proj_basedataload.R')   # loading the base data


K05_launch <- K05_pop[which(K05_pop$YEAR == launch_year),] %>%
		group_by(STATE, COUNTY, GEOID, YEAR, RACE, SEX) %>%
		dplyr::summarise(POPULATION = sum(POPULATION)) %>%
		ungroup()

# CDC Population Estimates 2020
write_csv(K05_launch, paste(path_data, 'Processed', 'Population_00_K05_launch.csv', sep = delimiter_path))


files <- paste(
		path_data,
		'Projections',
		'Proj',
		list.files(path = paste(path_data, 'Projections', 'Proj', sep = delimiter_path), pattern = '.csv'),
		sep = delimiter_path
)

# Generated Population Projections (CCD additive / CCR multiplicative) 2025 to 2100 in 5 year increments
z <- rbindlist(lapply(as.list(files), fread)) %>%
		mutate(
				STATE = substr(COUNTYRACE, 1, 2),
				COUNTY = substr(COUNTYRACE, 3, 5),
				GEOID = paste0(STATE, COUNTY),
				A = as.numeric(A),
				B = as.numeric(B),
				C = as.numeric(C),
				A = if_else(A < 0, 0, A),
				B = if_else(B < 0, 0, B),
				C = if_else(C < 0, 0, C),
				RACE = substr(COUNTYRACE, 7, 7)
		)


write_csv(z, paste(path_data, 'Processed', 'Population_01_z.csv', sep = delimiter_path))


z[is.na(z)] <- 0

# CDC Population Estimates 2020 (only contains 2020, why filter?)
basesum <- K05_launch[which(K05_launch$YEAR == launch_year),] %>%
		dplyr::select(STATE, COUNTY, GEOID, POPULATION, RACE)

write_csv(basesum, paste(path_data, 'Processed', 'Population_02_basesum.csv', sep = delimiter_path))

# Generated Population Projections (CCD only) 2100
addsum <- z[which(z$TYPE == "ADD" & z$YEAR == (launch_year + FORLEN)),] %>%
		group_by(STATE, COUNTY, GEOID, RACE, TYPE) %>%
		dplyr::summarise(A = sum(A))

write_csv(addsum, paste(path_data, 'Processed', 'Population_03_addsum.csv', sep = delimiter_path))



# This logic is broken


# CDC Population Estimates 2020 Compared to Generated Population Projections 2100
# See page 3 in article, paragraph 2 of "Cohort Change Differences" beginning "CCDs are just as parsimonious".
# "A" is projection, "POPULATION" is estimate
addmult <- left_join(addsum, basesum) %>%
		mutate(COMBINED = if_else(A >= POPULATION, "ADD", "Mult")) %>%
		dplyr::select(STATE, COUNTY, GEOID, RACE, COMBINED)

write_csv(addmult, paste(path_data, 'Processed', 'Population_04_addmult.csv', sep = delimiter_path))


# Never used.  What other variables are set in other scripts that are never used in those scripts but are used here?
# For example, K05_launch2 is used here but not defined here.  Is it an artifact that was part of Hauer's environment?
#basesum2 <- K05_launch[which(K05_launch$YEAR == launch_year),] %>%
#		dplyr::select(STATE, COUNTY, GEOID, POPULATION, RACE) %>%
#		group_by(GEOID, RACE) %>%
#		dplyr::summarise(poptot = sum(POPULATION))



combined <- left_join(z, addmult) %>%
		filter(TYPE == COMBINED) %>%
		mutate(TYPE = "ADDMULT") %>%
		dplyr::select(-COMBINED)

write_csv(combined, paste(path_data, 'Processed', 'Population_05_combined.csv', sep = delimiter_path))

z2 <- rbind(z, combined) # %>%

write_csv(z2, paste(path_data, 'Processed', 'Population_06_z2.csv', sep = delimiter_path))

# Where does K05_launch2 come from?  The 002-basedataload script defines it, but 002-basedataload is not referenced in
# the original script.
K05_launch2$SEX = as.integer(K05_launch2$SEX)

z2 <- left_join(as.data.frame(z2), as.data.frame(K05_launch2))

write_csv(z2, paste(path_data, 'Processed', 'Population_07_z2.csv', sep = delimiter_path))

z2 <- left_join(z2, countynames)

write_csv(z2, paste(path_data, 'Processed', 'Population_08_z2.csv', sep = delimiter_path))

z2[is.na(z2)] <- 0
z2 <- filter(
		z2,
		!GEOID %in% c("02900", "04910", "15900", "35910", "36910", "51910", "51911", "51911", "51913", "51914", "51915", "51916", "51918")
)


z3 <- filter(z2, TYPE == "ADDMULT")

write_csv(z3, paste(path_data, 'Processed', 'Population_09_z3.csv', sep = delimiter_path))

	 
totals <- z3 %>%
		group_by(AGE, SEX, YEAR) %>%
		dplyr::summarise(poptot = sum(A))

write_csv(totals, paste(path_data, 'Processed', 'Population_10_totals.csv', sep = delimiter_path))


# This is the percent population of the total analysis area.  In Hauer, that is the United States.  However, this only
# includes the EWG region.
totals2 <- left_join(z3, totals) %>%
		mutate(percentage = (A / poptot))



write_csv(totals2, paste(path_data, 'Processed', 'Population_11_totals2.csv', sep = delimiter_path))

#unzip(
#		zipfile = paste(path_data, 'SspDb_country_data_2013-06-12.csv.zip', sep = delimiter_path),
#		exdir = path_data
#)

#asc <- function(x) { strtoi(charToRaw(x), 16L) }

#chr <- function(n) { rawToChar(as.raw(n)) }


SSPs <- read_csv(paste(path_data, 'SspDb_country_data_2013-06-12.csv', sep = delimiter_path),) %>%
		filter(REGION == "USA", grepl("Population", VARIABLE)) %>%
		separate(VARIABLE, c("VARIABLE", "VARIABLE1", "VARIABLE2", "VARIABLE3", "VARIABLE4"), sep = '\\|')


SSPs2 <- SSPs %>%
		dplyr::select(-`1950`:-`2010`, -`2105`:-`2150`) %>%
		mutate(
				SEX = case_when(
						VARIABLE1 == "Female" ~ 2,
						VARIABLE1 == "Male" ~ 1
				),
				AGE = case_when(
						grepl('^Aged0', VARIABLE2) ~ 1,
						grepl('^Aged5', VARIABLE2) ~ 2,
						grepl('^Aged10', VARIABLE2) ~ 3,
						grepl('^Aged15', VARIABLE2) ~ 4,
						grepl('^Aged20', VARIABLE2) ~ 5,
						grepl('^Aged25', VARIABLE2) ~ 6,
						grepl('^Aged30', VARIABLE2) ~ 7,
						grepl('^Aged35', VARIABLE2) ~ 8,
						grepl('^Aged40', VARIABLE2) ~ 9,
						grepl('^Aged45', VARIABLE2) ~ 10,
						grepl('^Aged50', VARIABLE2) ~ 11,
						grepl('^Aged55', VARIABLE2) ~ 12,
						grepl('^Aged60', VARIABLE2) ~ 13,
						grepl('^Aged65', VARIABLE2) ~ 14,
						grepl('^Aged70', VARIABLE2) ~ 15,
						grepl('^Aged75', VARIABLE2) ~ 16,
						grepl('^Aged80', VARIABLE2) ~ 17,
						grepl('^Aged85', VARIABLE2) ~ 18,
						grepl('^Aged90', VARIABLE2) ~ 18,
						grepl('^Aged95', VARIABLE2) ~ 18,
						grepl('^Aged100', VARIABLE2) ~ 18
				),
				SSP = case_when(
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
		gather(YEAR, Population, `2015`:`2100`) %>%
		group_by(SEX, AGE, SSP, YEAR) %>%
		dplyr::summarise(Population = sum(Population)) %>%
		ungroup() %>%
		spread(SSP, Population) %>%
		mutate(YEAR = as.integer(YEAR))

write_csv(SSPs2, paste(path_data, 'Processed', 'SSP_01_prepared.csv', sep = delimiter_path))


# Rates
SSP_baseline <- SSPs2 %>%
		filter(YEAR == 2020) %>%
		dplyr::rename(
				SSP1_baseline = SSP1,
				SSP2_baseline = SSP2,
				SSP3_baseline = SSP3,
				SSP4_baseline = SSP4,
				SSP5_baseline = SSP5
		) %>%
		select(SEX, AGE, SSP1_baseline:SSP5_baseline)

write_csv(SSP_baseline, paste(path_data, 'Processed', 'SSP_02_baseline.csv', sep = delimiter_path))


SSP_rates <- left_join(SSPs2, SSP_baseline) %>%
#		arrange(SEX, AGE, YEAR) %>%		# Only for use with lag()
		mutate(
				SSP1_rate = (SSP1 - SSP1_baseline) / SSP1_baseline,
				SSP2_rate = (SSP2 - SSP2_baseline) / SSP2_baseline,
				SSP3_rate = (SSP3 - SSP3_baseline) / SSP3_baseline,
				SSP4_rate = (SSP4 - SSP4_baseline) / SSP4_baseline,
				SSP5_rate = (SSP5 - SSP5_baseline) / SSP5_baseline
#				SSP1_rate = (1 + (SSP1 - SSP1_baseline) / SSP1_baseline),
#				SSP2_rate = (1 + (SSP2 - SSP2_baseline) / SSP2_baseline),
#				SSP3_rate = (1 + (SSP3 - SSP3_baseline) / SSP3_baseline),
#				SSP4_rate = (1 + (SSP4 - SSP4_baseline) / SSP4_baseline),
#				SSP5_rate = (1 + (SSP5 - SSP5_baseline) / SSP5_baseline)
#				SSP1_rate = (1 + (SSP1 - lag(SSP1, 1)) / lag(SSP1, 1)),
#				SSP2_rate = (1 + (SSP2 - lag(SSP2, 1)) / lag(SSP2, 1)),
#				SSP3_rate = (1 + (SSP3 - lag(SSP3, 1)) / lag(SSP3, 1)),
#				SSP4_rate = (1 + (SSP4 - lag(SSP4, 1)) / lag(SSP4, 1)),
#				SSP5_rate = (1 + (SSP5 - lag(SSP5, 1)) / lag(SSP5, 1))
		) %>%
		filter(YEAR >= 2020 & YEAR <= 2100) %>%
		select(YEAR, SEX, AGE, SSP1:SSP5, SSP1_rate:SSP5_rate, SSP1_baseline:SSP5_baseline)

		
write_csv(SSP_rates, paste(path_data, 'Processed', 'SSP_03_rates.csv', sep = delimiter_path))


# The Hauer workflow assumes that the entire country is processed.  To downscale, the SSP is weighted by the local population
# country population ratio.
test <- left_join(totals2, SSP_rates) %>%
		mutate(
#				SSP1 = SSP1 * percentage * 1000000,
#				SSP2 = SSP2 * percentage * 1000000,
#				SSP3 = SSP3 * percentage * 1000000,
#				SSP4 = SSP4 * percentage * 1000000,
#				SSP5 = SSP5 * percentage * 1000000,
#				SSP1 = (1 + (SSP1 - lag(SSP1, 1)) / lag(SSP1, 1)) * poptot * 1000000,
#				SSP2 = (1 + (SSP2 - lag(SSP2, 1)) / lag(SSP2, 1)) * poptot * 1000000,
#				SSP3 = (1 + (SSP3 - lag(SSP3, 1)) / lag(SSP3, 1)) * poptot * 1000000,
#				SSP4 = (1 + (SSP4 - lag(SSP4, 1)) / lag(SSP4, 1)) * poptot * 1000000,
#				SSP5 = (1 + (SSP5 - lag(SSP5, 1)) / lag(SSP5, 1)) * poptot * 1000000,
				SSP1 = SSP1_rate * A,
				SSP2 = SSP2_rate * A,
				SSP3 = SSP3_rate * A,
				SSP4 = SSP4_rate * A,
				SSP5 = SSP5_rate * A,
				GEOID = case_when(
						GEOID == "46113" ~ "46102", # Shannon County (46113)'s name changed to Oglala Lakota (46102)
						GEOID == "51917" ~ "51019", # Bedford City (51917) is merged into Bedford County (51019)
						GEOID == "02270" ~ "02158", # Wade Hampton (02270) is actually (02158)
						TRUE ~ as.character(GEOID)
				)
         ) %>%
		 select(YEAR, SEX, STATE, COUNTY, GEOID, RACE, AGE, SSP1:SSP5)

 write_csv(test, paste(path_data, 'Processed', 'SSP_04_projected.csv', sep = delimiter_path))
 
 
 test2 <- test %>%
		group_by(YEAR, STATE) %>%
		dplyr::summarise(
				SSP1 = sum(SSP1),
				SSP2 = sum(SSP2),
				SSP3 = sum(SSP3),
				SSP4 = sum(SSP4),
				SSP5 = sum(SSP5)
		) %>%
		gather(Scenario, Population, SSP1:SSP5)

write_csv(test2, paste(path_data, 'Processed', 'SSP_05_summarized.csv', sep = delimiter_path))


test3 <- test %>%
		group_by(YEAR, SEX, STATE, COUNTY, GEOID, RACE, AGE) %>%
		dplyr::summarise(
				SSP1 = sum(SSP1),
				SSP2 = sum(SSP2),
				SSP3 = sum(SSP3),
				SSP4 = sum(SSP4),
				SSP5 = sum(SSP5)
		)


write_csv(test3, paste(path_data, 'Processed', 'SSP_asrc.csv', sep = delimiter_path))
#write_csv(test2, paste(path_data, 'Processed', 'SSP_sums.csv', sep = delimiter_path))

#write_csv(test, paste(path_data, 'Processed', 'SSP_raw.csv', sep = delimiter_path))


write_csv(SSPs, paste(path_data, 'Processed', 'SSP.csv', sep = delimiter_path))
