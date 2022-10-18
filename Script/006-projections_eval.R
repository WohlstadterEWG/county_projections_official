#
#	  $Author: michaelw $
#	  Created: September 22, 2022
#		$Date: $
#	$Revision: $
#	 $HeadURL: $
#
# Subject
#	Generate the Out-of-Sample Validation Population Projections for the Period 2000 to 2020
#
# Purpose
#	This script is derived from the R code written by Mathew E. Hauer (see References).
#
# Output (datasets set for global use but not persistently stored)
#	- COUNTY_20002020[state]
#
# Dependencies
#	- 000-Libraries.R
#	- 001-fipscodes.R
#	- 002-basedataload.R
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
#
# TODO
#	- Way too much is set as a global environment variable.  Redesign the workflow to be more uncoupled.
#	- The current setup is to share a database connection for the overall script unit of work.  This doesn't work in a
#	parallel environment.  This is somewhat moot since the parallel operations aren't well supported under Windows.  However,
#	this is an issue to resolve if running under macOS or Linux.  The alternative is to initialise and close the database
#	connection inside of the foreach() %dopar% loop.  Currently the local database connection logic is active and the shared
#	database connection logic is commented out.  Note, the number of look iterations is small and the connection cost is
#	low.
#
###############################################################################


set.seed(100)

(start.time <- Sys.time())

source('./Script/000-Libraries.R')      # loading in the libraries

if (!dbExistsTable(connection, 'population__forecast__evaluation')) {
	source('./Script/001-fipscodes.R')      # Getting a Fips List
	source('./Script/002-basedataload.R')   # loading the base data
	
	project <- function(key) {
		tryCatch(
				{
					###   Prediction of the CCR/CCD function.
					# The relevant change function is employed when constructing the series passed in.
					prediction <- function(bracket, gender, key, data) {
						series <- as_tibble(
								data[[as.character(bracket)]][
										which(
												data$geoid == substr(key, 1, 5)
												& data$race == substr(key, 7, 7)
												& data$gender == gender
										)
								]
						)
						indices <- seq(1, forecast_length, 5)		# Index of forecast year to sample
						
						change <- tryCatch(
								forecast(arima(series$value, order = arima_order), h = forecast_length)$mean[c(indices)],
								error = function(e) array(0, c(projection_step_count))
						)
						
						return(change)
					}
					
					
					###################
					### DATA PREP
					##################
					### Filtering the Census data based on the county/race combination
					population_county <- estimates[
									which(
											estimates$geoid == substr(key, 1, 5)
											& estimates$race == substr(key, 7, 7)
									),
							] %>%
							group_by(year, geoid, race, gender, age_bracket) %>%
							dplyr::summarise(population = sum(population)) %>%
							ungroup()
							
					### Calculating the cohort-change differences (CCDs)
					# Actually preparing the CCD base data.
					CCDs <- population_county %>%
							mutate(
									age_bracket = paste0("X", age_bracket),
							)
					
					CCDs$population[is.null(CCDs$population)] <- 0
					
					CCDs <- spread(CCDs, age_bracket, population)
					
					
					# Page 3, formula 4
					CCDs <- CCDs %>%
							arrange(geoid, gender, year) %>%
							mutate(
									ccr1 = X02 - lag(X01, 5),
									ccr2 = X03 - lag(X02, 5),
									ccr3 = X04 - lag(X03, 5),
									ccr4 = X05 - lag(X04, 5),
									ccr5 = X06 - lag(X05, 5),
									ccr6 = X07 - lag(X06, 5),
									ccr7 = X08 - lag(X07, 5),
									ccr8 = X09 - lag(X08, 5),
									ccr9 = X10 - lag(X09, 5),
									ccr10 = X11 - lag(X10, 5),
									ccr11 = X12 - lag(X11, 5),
									ccr12 = X13 - lag(X12, 5),
									ccr13 = X14 - lag(X13, 5),
									ccr14 = X15 - lag(X14, 5),
									ccr15 = X16 - lag(X15, 5),
									ccr16 = X17 - lag(X16, 5),
									ccr17 = X18 - (lag(X17, 5) + lag(X18, 5))
							) %>%
							filter(
									as.integer(year) >= min(as.integer(year) + 5, na.rm = TRUE)
									& as.integer(year) <= as.integer(constants$analysis_year_start_evaluation)
							)
					
					### Calculating the CCRs
					# Actually preparing the CCR base data.
					CCRs <- population_county %>%
							mutate(
									age_bracket = paste0("X", age_bracket)
							)
			
					CCRs$population[is.null(CCRs$population)] <- 0
					
					CCRs <- spread(CCRs, age_bracket, population)
					
					# Page 3, formula 2
					CCRs <- CCRs %>%
							arrange(geoid, gender, year) %>%
							mutate(
									ccr1 = X02 / lag(X01, 5),
									ccr2 = X03 / lag(X02, 5),
									ccr3 = X04 / lag(X03, 5),
									ccr4 = X05 / lag(X04, 5),
									ccr5 = X06 / lag(X05, 5),
									ccr6 = X07 / lag(X06, 5),
									ccr7 = X08 / lag(X07, 5),
									ccr8 = X09 / lag(X08, 5),
									ccr9 = X10 / lag(X09, 5),
									ccr10 = X11 / lag(X10, 5),
									ccr11 = X12 / lag(X11, 5),
									ccr12 = X13 / lag(X12, 5),
									ccr13 = X14 / lag(X13, 5),
									ccr14 = X15 / lag(X14, 5),
									ccr15 = X16 / lag(X15, 5),
									ccr16 = X17 / lag(X16, 5),
									ccr17 = X18 / (lag(X17, 5) + lag(X18, 5))
							) %>%
							filter(
									as.integer(year) >= min(as.integer(year) + 5, na.rm = TRUE)
											& as.integer(year) <= as.integer(constants$analysis_year_start_evaluation)
							)
					
					CCDs[mapply(is.infinite, CCDs)] <- NA
					CCDs[mapply(is.nan, CCDs)] <- NA
					CCDs[is.na(CCDs)] <- 0
					
					CCRs[mapply(is.infinite, CCRs)] <- NA
					CCRs[mapply(is.nan, CCRs)] <- NA
					CCRs[is.na(CCRs)] <- 0
					
					
					##################################################
					### Start of the Additive projections
					##################################################
					
					###  Calculating the UCM's of the CCD's for each age/sex group. The confidence interval is set to 80% (1.28 * SD)
					# The variable "age_bracket_count" can actually be derived by length(unique(population_county$age_bracket)).
					for (i in 1:(age_bracket_count - 1)) {
						prediction_female <- cbind(prediction(paste0("ccr", i), "2", key, CCDs), 0, 0)
						prediction_male <- cbind(prediction(paste0("ccr", i), "1", key, CCDs), 0, 0)
						
						error_female <- sd(CCDs[[as.character(paste0("ccr", i))]][which(CCDs$gender == "2")]) * 1.28
						error_male <- sd(CCDs[[as.character(paste0("ccr", i))]][which(CCDs$gender == "1")]) * 1.28
						
						prediction_female[, 2] <- prediction_female[, 1] - ifelse(is.na(error_female), 0, error_female)
						prediction_female[, 3] <- prediction_female[, 1] + ifelse(is.na(error_female), 0, error_female)
						prediction_male[, 2] <- prediction_male[, 1] - ifelse(is.na(error_male), 0, error_male)
						prediction_male[, 3] <- prediction_male[, 1] + ifelse(is.na(error_male), 0, error_male)
						
						assign(paste0("BA", i, "f"), prediction_female[1:projection_step_count, 1:3])
						assign(paste0("BA", i, "m"), prediction_male[1:projection_step_count, 1:3])
						
						rm(prediction_female, prediction_male, error_female, error_male)
					}
					
					### "Stacking" the CCDs into a single vector with a high/medium/low
					for (i in 1:projection_step_count) {
						name_male <- paste0("lx", i, "m")
						name_female <- paste0("lx", i, "f")
						assign(
								name_male,
								rbind(
										BA1m[i,],
										BA2m[i,],
										BA3m[i,],
										BA4m[i,],
										BA5m[i,],
										BA6m[i,],
										BA7m[i,],
										BA8m[i,],
										BA9m[i,],
										BA10m[i,],
										BA11m[i,],
										BA12m[i,],
										BA13m[i,],
										BA14m[i,],
										BA15m[i,],
										BA16m[i,],
										BA17m[i,]
								)
						)
						assign(
								name_female,
								rbind(
										BA1f[i,],
										BA2f[i,],
										BA3f[i,],
										BA4f[i,],
										BA5f[i,],
										BA6f[i,],
										BA7f[i,],
										BA8f[i,],
										BA9f[i,],
										BA10f[i,],
										BA11f[i,],
										BA12f[i,],
										BA13f[i,],
										BA14f[i,],
										BA15f[i,],
										BA16f[i,],
										BA17f[i,]
								)
						)
					}
					
					###   Placing the CCD's into the subdiagonal of a leslie matrix.
					# Actually, just building the age specific survival delta matrix.
					for (i in 1:projection_step_count) {
						change_female <- get(paste0("lx", i, "f"))
						weird_female <- array(0, c(age_bracket_count, age_bracket_count, ncol(change_female)))
						
						change_male <- get(paste0("lx", i, "m"))
						weird_male <- array(0, c(age_bracket_count, age_bracket_count, ncol(change_male)))
						for (j in 1:ncol(change_female)) {
							weird_female[,, j] <- rbind(0, cbind(diag(change_female[, j]), 0))
							weird_male[,, j] <- rbind(0, cbind(diag(change_male[, j]), 0))
							
							assign(paste0("S", i, "f"), weird_female)
							assign(paste0("S", i, "m"), weird_male)
						}
						
						rm(change_female, change_male, weird_female, weird_male)
					}
					
					### Formatting the base POPULATION data as equal to the total POPULATION minus the group quarters.
					population_female <- array(0, c(age_bracket_count))
					for (i in 1:age_bracket_count) {
						population_female[i] <- ifelse(
								length(population_county$population[
												which(
														population_county$gender == "2"
																& population_county$year == constants$analysis_year_start_evaluation
																& as.integer(population_county$age_bracket) == i
												)
										]) == 0,
								0,
								population_county$population[
										which(
												population_county$gender == "2"
														& population_county$year == constants$analysis_year_start_evaluation
														& as.integer(population_county$age_bracket) == i
										)
								]
						)
					}
					
					group_quarters_female <- ifelse(
							length(population_group_quarters$group_quarters[
											which(
													population_group_quarters$gender == "2"
															& population_group_quarters$geoid == substr(key, 1, 5)
															& population_group_quarters$race == substr(key, 7, 7)
											)
									]) > 0,
							population_group_quarters$group_quarters[
									which(
											population_group_quarters$gender == "2"
													& population_group_quarters$geoid == substr(key, 1, 5)
													& population_group_quarters$race == substr(key, 7, 7)
									)
							],
							0
					)
					
					population_female <- population_female - group_quarters_female
					
					
					population_male <- array(0, c(age_bracket_count))
					for(i in 1:age_bracket_count) {
						population_male[i] <- ifelse(
								length(population_county$population[
												which(
														population_county$gender == "1"
																& population_county$year == constants$analysis_year_start_evaluation
																& as.integer(population_county$age_bracket) == i
												)
										]) == 0,
								0,
								population_county$population[
										which(
												population_county$gender == "1"
														& population_county$year == constants$analysis_year_start_evaluation
														& as.integer(population_county$age_bracket) == i
										)
								]
						)
					}
					
					group_quarters_male <- ifelse(
							length(population_group_quarters$group_quarters[
											which(
													population_group_quarters$gender == "1"
													& population_group_quarters$geoid == substr(key, 1, 5)
													& population_group_quarters$race == substr(key, 7, 7)
											)
									]) > 0,
							population_group_quarters$group_quarters[
									which(
											population_group_quarters$gender == "1"
											& population_group_quarters$geoid == substr(key, 1, 5)
											& population_group_quarters$race == substr(key, 7, 7)
									)
							],
							0
					)
					
					population_male <- population_male - group_quarters_male
					
					
					### Assemble the Leslie Matrix
					leslie_matrix_0_female <- array(0, c(age_bracket_count, age_bracket_count, ncol(lx1f)))
					leslie_matrix_0_male <- array(0, c(age_bracket_count, age_bracket_count, ncol(lx1f)))
					for (i in 1:ncol(lx1f)) {
						leslie_matrix_0_female[,, i] <- rbind(0, cbind(diag(population_female), 0))[1:18, 1:18]
						leslie_matrix_0_female[18, 18, i] = population_female[18]
						leslie_matrix_0_male[,, i] <- rbind(0, cbind(diag(population_male), 0))[1:18, 1:18]
						leslie_matrix_0_male[18, 18, i] = population_male[18]
					}
					
					### Calculating the forecasted CWR's from the UCMs. Confidence interval is set at 80% (1.28*SD)
					fertility_rate <- filter(fertility, state_fips == substr(key, 1, 2), race == substr(key, 7, 8)) %>%
							dplyr::select(rate) %>%
							rename(value = rate)
					
					birthrate <- array(0, c(projection_step_count, ncol(lx1f)))
					# Since the fertility rates are averaged, there isn't one for every projection step.  Review the workflow.
					birthrate[, 1] <- fertility_rate$value	# [1:projection_step_count] 
					
					
					### PROJECTION ITSELF ###
					
					# Actually projecting with the additive model
					for (i in 1:projection_step_count) {
						difference_female <- get(paste0("S", i, "f"))
						difference_male <- get(paste0("S", i, "m"))
						
						total_male <- total_female <- array(
								0,
								c(age_bracket_count, ncol(lx1f)),
								dimnames = list(paste0(rep('a', 18), 1:18))
						)
						
						prior_female <- get(paste("leslie_matrix", i - 1, "female", sep = '_'))
						prior_male <- get(paste("leslie_matrix", i - 1, "male", sep = '_'))
						for (j in 1:ncol(lx1f)) {
							# Base population
							total_female[, j] <- rowSums(difference_female[,, j] + prior_female[,, j])
							total_male[, j] <- rowSums(difference_male[,, j] + prior_male[,, j])
							
							# Add births
							total_female[1, j] <- (birthrate[i, j] * sum(total_female[4:10, j])) * 0.487
							total_male[1, j] <- (birthrate[i, j] * sum(total_female[4:10, j])) * 0.512
							
							# 
							prior_female[,, j] <- rbind(0, cbind(diag(total_female[, j]), 0))[1:18, 1:18]
							prior_male[,, j] <- rbind(0, cbind(diag(total_male[, j]), 0))[1:18, 1:18]
							prior_female[18, 18, j] <- total_female[18, j]
							prior_male[18, 18, j] <- total_male[18, j]
							
							assign(paste("leslie_matrix", i, "female", sep = '_'), prior_female)
							assign(paste("leslie_matrix", i, "male", sep = '_'), prior_male)
							assign(paste("projection", i, "female", sep = '_'), total_female)
							assign(paste("projection", i, "male", sep = '_'), total_male)
						}
						
						rm(difference_female, difference_male, total_female, total_male, prior_female, prior_male)
					}
					
					### Collecting the additive projections together.
					projection_male <- NULL
					projection_female <- NULL
					for (i in 1:projection_step_count) {
						total_male <- as.data.frame.table(get(paste("projection", i, "male", sep = '_'))
								+ group_quarters_male)
						total_male$year <- as.character(as.integer(year_baseline) + (i * 5))
						total_male$gender <- "1"
						
						total_female <- as.data.frame.table(get(paste("projection", i, "female", sep = '_'))
								+ group_quarters_female)
						total_female$year <- as.character(as.integer(year_baseline) + (i * 5))
						total_female$gender <- "2"
						
						projection_female <- rbind(projection_female, total_female)
						projection_male <- rbind(projection_male, total_male)
						
						rm(total_female, total_male)
					}
					
					### Declaring several variables
					projection_additive <- rbind(projection_male, projection_female) %>%
							dplyr::rename(variable = Var1, scenario = Var2, frequency = Freq)
					
					projection_additive$key <- key
					projection_additive$type <- "ADD"
					
					
					######################################
					### PROJECTING THE CCRs
					
					### Calculating the CCR UCMs for each individual age group
					for (i in 1:(age_bracket_count - 1)) {
						prediction_female <- cbind(prediction(paste0("ccr", i), "2", key, CCRs), 0, 0)
						prediction_male <- cbind(prediction(paste0("ccr", i), "1", key, CCRs), 0, 0)
						
						error_female <- sd(CCRs[[as.character(paste0("ccr", i))]][which(CCRs$gender == "2")]) * 1.28
						error_male <- sd(CCRs[[as.character(paste0("ccr", i))]][which(CCRs$gender == "1")]) * 1.28
						
						prediction_female[, 2] <- prediction_female[, 1] - ifelse(is.na(error_female), 0, error_female)
						prediction_female[, 3] <- prediction_female[, 1] + ifelse(is.na(error_female), 0, error_female)
						prediction_male[, 2] <- prediction_male[, 1] - ifelse(is.na(error_male), 0, error_male)
						prediction_male[, 3] <- prediction_male[, 1] + ifelse(is.na(error_male), 0, error_male)
						
						assign(paste0("BA", i, "f"), prediction_female[1:projection_step_count, 1:3])
						assign(paste0("BA", i, "m"), prediction_male[1:projection_step_count, 1:3])
						
						rm(prediction_female, prediction_male, error_female, error_male)
					}
					
					### Stacking the forecasted CCRs into single vectors.
					for (i in 1:projection_step_count) {
						name_male <- paste0("lx", i, "m")
						name_female <- paste0("lx", i, "f")
						assign(
								name_male,
								rbind(
										BA1m[i,],
										BA2m[i,],
										BA3m[i,],
										BA4m[i,],
										BA5m[i,],
										BA6m[i,],
										BA7m[i,],
										BA8m[i,],
										BA9m[i,],
										BA10m[i,],
										BA11m[i,],
										BA12m[i,],
										BA13m[i,],
										BA14m[i,],
										BA15m[i,],
										BA16m[i,],
										BA17m[i,]
								)
						)
						assign(
								name_female,
								rbind(
										BA1f[i,],
										BA2f[i,],
										BA3f[i,],
										BA4f[i,],
										BA5f[i,],
										BA6f[i,],
										BA7f[i,],
										BA8f[i,],
										BA9f[i,],
										BA10f[i,],
										BA11f[i,],
										BA12f[i,],
										BA13f[i,],
										BA14f[i,],
										BA15f[i,],
										BA16f[i,],
										BA17f[i,]
								)
						)
						
						rm(name_female, name_male)
					}
					
					### Setting the sub-diagonal of a leslie matrix as equal to the projected CCRs
					for (i in 1:projection_step_count) {
						total_female <- get(paste0("lx", i, "f"))
						total_male <- get(paste0("lx", i, "m"))
						
						weird_female <- array(0, c(age_bracket_count, age_bracket_count, ncol(total_female)))
						weird_male <- array(0, c(age_bracket_count, age_bracket_count, ncol(total_male)))
						for(j in 1:ncol(total_female)) {
							weird_female[,, j] <- rbind(0, cbind(diag(total_female[, j]), 0))
							weird_female[18, 18, j] = total_female[17, j]
							weird_male[,, j] <- rbind(0, cbind(diag(total_male[, j]), 0))
							weird_male[18, 18, j] = total_male[17, j]
							
							assign(paste0("S", i, "f"), weird_female)
							assign(paste0("S", i, "m"), weird_male)
						}
						
						rm(total_female, total_male, weird_female, weird_male)
					}
					
					### Formatting the base POPULATION data.
					leslie_matrix_0_female <- array(0, c(age_bracket_count, 1, ncol(lx1f)))
					leslie_matrix_0_male <- array(0, c(age_bracket_count, 1, ncol(lx1f)))
					for (i in 1:ncol(lx1f)) {
						leslie_matrix_0_female[,, i] <- cbind(population_female)
						leslie_matrix_0_male[,, i] <- cbind(population_male)
					}
					
					### PROJECTING THE CCRs
					for (i in 1:projection_step_count) {
						ratio_female <- get(paste0("S", i, "f"))
						ratio_male <- get(paste0("S", i, "m"))
						
						total_male <- total_female <- array(
								0,
								c(age_bracket_count, 1, ncol(lx1f)),
								dimnames = list(paste0(rep('a', 18), 1:18))
						)
						
						prior_female <- get(paste("leslie_matrix", i - 1, "female", sep = '_'))
						prior_male <- get(paste("leslie_matrix", i - 1, "male", sep = '_'))
						for(j in 1:ncol(lx1f)) {
							total_female[,, j] <- ratio_female[,, j] %*% prior_female[,, j]
							total_male[,, j] <- ratio_male[,, j] %*% prior_male[,, j]
							total_female[1,, j] <- (birthrate[i, j] * sum(total_female[4:10,, j])) * 0.487
							total_male[1,, j] <- (birthrate[i, j] * sum(total_female[4:10,, j])) * 0.512
							
							assign(paste("leslie_matrix", i, "female", sep = '_'), total_female)
							assign(paste("leslie_matrix", i, "male", sep = '_'), total_male)
							assign(paste("projection", i, "female", sep = '_'), total_female)
							assign(paste("projection", i, "male", sep = '_'), total_male)
						}
						
						rm(ratio_female, ratio_male, prior_female, prior_male, total_female, total_male)
					}
					
					### Collecting the projection results
					projection_male <- NULL
					projection_female <- NULL
					for (i in 1:projection_step_count) {
						total_female <- as.data.frame.table(
								get(paste("projection", i, "female", sep = '_'))
										+ group_quarters_female)
						total_female$year <- as.character(as.integer(year_baseline) + (i * 5))
						total_female$gender <- "2"
						total_male <- as.data.frame.table(
								get(paste("projection", i, "male", sep = '_'))
										+ group_quarters_male)
						total_male$year <- as.character(as.integer(year_baseline) + (i * 5))
						total_male$gender <- "1"
						
						projection_female <- rbind(projection_female, total_female)
						projection_male <- rbind(projection_male, total_male)
						
						rm(total_female, total_male)
					}
					
					projection_multiplicative <- rbind(projection_male, projection_female) %>%
							dplyr::select(-Var2) %>%
							dplyr::rename(variable = Var1, scenario = Var3, frequency = Freq)
					
					projection_multiplicative$key <- key
					projection_multiplicative$type <- "Mult"
					
					# Collecting all projections together
					population_projection <- rbind(projection_additive, projection_multiplicative)
					
					return(population_projection)
				},
				error = function(e) { cat(key, " ERROR :", conditionMessage(e), "\n") }
		)
	}

	
	
	### Begin Processing
	# EWG Region
	estimates <- estimates	%>%
			filter(geoid %in% c('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510'))
	
	# Baseline is initialized in 002.  Refactor to be more explicit.
	estimates_baseline <- estimates[which(estimates$year == year_baseline),]
	state_list <- unique(substr(estimates_baseline$geoid, 1, 2))
	
	
	sql <- '
SELECT "p"."year", "p"."state_fips", "p"."county_fips", "p"."race", "p"."gender", "p"."age_bracket",
	"p"."population"
FROM "population__group_quarters" AS "p"
WHERE "p"."year" = :year;
'
	
	select <- dbSendQuery(connection, sql)
	
	dbBind(select, list(year = '2000'))
	population_group_quarters <- dbFetch(select)
	dbClearResult(select)
	
	population_group_quarters <- population_group_quarters %>%
			mutate(
					geoid = paste0(state_fips, county_fips),
					gender = case_when(
							gender == 'MALE' ~ '1',
							gender == 'FEMALE' ~ '2'
					),
					race = case_when(
							race == "BLACK, NH" ~ "2",
							race == "OTHER" ~ "3",
							race == "WHITE, NH" ~ "1",
							race == "HISPANIC" ~ "3",
							race == "OTHER, NH" ~ "3"
					)
			) %>%
			group_by(across(all_of(group_list))) %>%
			dplyr::summarise(group_quarters = sum(population, na.rm = TRUE))
	
	sql <- '
SELECT "f"."year", "f"."state_fips", "f"."race", "f"."gender", "f"."rate"
FROM "fertility" AS "f"
WHERE "f"."year" = :year;
'
	
	select <- dbSendQuery(connection, sql)
	
	dbBind(select, list(year = constants$analysis_year_end_evaluation))
	fertility <- dbFetch(select)
	dbClearResult(select)
	
	
	
	estimates$key <- paste(estimates$geoid, estimates$race, sep = '_')
	estimates$state_fips <- substr(estimates$geoid, 1, 2)
	
	# At the risk of engaging in an antipattern, this DROP won't ever be required in the currently implementation.  However,
	# there is a planned enhancement that will allow the refresh of the data via a flag (or configuration setting).  That
	# flag will allow entry into the conditional that executes the subsequent statement even in the presence of that table.
	dbExecute(connection, 'DROP TABLE IF EXISTS "population__forecast__evaluation";')
	
	sql <- '
CREATE TABLE "population__forecast__evaluation" (
	"id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	"year" CHARACTER(4) NOT NULL,
	"geoid" CHARACTER(5) NOT NULL,
	"race" CHARACTER(1) NOT NULL,
	"gender" CHARACTER(1) NOT NULL,
	"age_bracket" CHARACTER(2) NOT NULL,
	"type" CHARACTER(10) NOT NULL,
	"projection_a" FLOAT,
	"projection_b" FLOAT,
	"projection_c" FLOAT,
	CONSTRAINT "AlternateKey_Age" UNIQUE ("year", "geoid", "race", "gender", "age_bracket", "type")
);
'
	
	dbExecute(connection, sql)
	
	
	dbDisconnect(connection)
	
	packages <- c("data.table", "doParallel", "foreach", "tidyverse", "rucm", "forecast", "RSQLite")
	foreach(i = 1:length(state_fips), .combine = rbind, .errorhandling = "stop", .packages = packages) %dopar% {
		connection <- dbConnect(
				RSQLite::SQLite(),
				dbname = paste(configuration$path_database, configuration$database_file, sep = delimiter_path),
				synchronous = 'normal'
		)
		
		dbExecute(connection, 'PRAGMA journal_mode = WAL;')
		dbExecute(connection, 'PRAGMA temp_store = memory;')
		dbExecute(connection, 'PRAGMA mmap_size = 30000000000;')
		
		sql <- '
INSERT INTO "population__forecast__evaluation" (
	"year", "geoid", "race", "gender", "age_bracket", "type",
	"projection_a", "projection_b", "projection_c" 
)
VALUES (
	:year, :geoid, :race, :gender, :age_bracket, :type,
	:projection_a, :projection_b, :projection_c
);
'
		
		insert <- dbSendStatement(connection, sql)
		keys <- unlist(list(unique(estimates$key[which(estimates$state_fips == state_fips[i])])))
		
		projection <- rbindlist(lapply(keys, project))
		
		projection <- projection %>%
			mutate(
					geoid = substr(key, 1, 5),
					race = substr(key, 7, 7),
					age_bracket = sprintf('%02d', as.numeric(substr(variable, 2, 3)))
			) %>%
			group_by(year, geoid, race, gender, age_bracket) %>%
			spread(scenario, frequency)
		
		dbBind(
				insert,
				params = list(
						year = projection$year,
						geoid = projection$geoid,
						race = projection$race,
						gender = projection$gender,
						age_bracket = projection$age_bracket,
						type = projection$type,
						projection_a = projection$A,
						projection_b = projection$B,
						projection_c = projection$C
				)
		)
		
		dbClearResult(insert)
		
		dbDisconnect(connection)
	}
} else {
	dbDisconnect(connection)
}
