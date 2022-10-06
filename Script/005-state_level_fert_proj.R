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
#	- state-level-fert-rates_20002020.csv
#	- state-level-fert-rates_20202100.csv
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
#	"Population Projections for U.S. Counties by Age, Sex, and Race Controlled to Shared Socioeconomic Pathway" by Mathew
#	E. Hauer
#
# TODO
#	- The coding style is somewhat obtuse and much of the data is shared through public variables.  Refactor so that
#
###############################################################################



###################
### DATA PREP
##################
rm(list = ls())

source('./Script/000-Libraries.R')      # loading in the libraries
source('./Script/001-fipscodes.R')      # Getting a Fips List

source('./Script/002-basedataload.R')   # loading the base data


K05_pop <- K05_pop %>%
		group_by(across(all_of(GROUPING))) %>%
		dplyr::summarise(POPULATION = sum(POPULATION)) # summing by the grouping for the total population

K05_pop$GEOID <- paste0(K05_pop$STATE, K05_pop$COUNTY) # setting the GEOID equal to the STATE and COUNTY columns
K05_pop$COUNTYRACE <- paste0(K05_pop$GEOID, "_", K05_pop$RACE) # setting the unique county_race combination

races <- unique(K05_pop$RACE) # creating a looping variable


fertrats_20002020 <- data.frame() # making the empty dataframe to hold the results.
for (this.state in stateid) {
	for (this.race in races) {
		K05t <- K05_pop[which(K05_pop$STATE == this.state & K05_pop$RACE == this.race),] %>%
				group_by(YEAR, STATE, RACE, SEX, AGE) %>%
				dplyr::summarise(POPULATION = sum(POPULATION)) %>%
				ungroup()
		
#		write_csv(K05t, paste(path_data, 'Load', 'k05_pop_2000_2020__01.csv', sep = delimiter_path))
		
		newbornst <- K05t %>%
				filter(AGE == 1) %>% # AGE 1 = newborns.
				group_by(STATE, RACE, YEAR)  %>%
				dplyr::summarise(Newborns = sum(POPULATION))
		
#		write_csv(newbornst, paste(path_data, 'Load', 'k05_pop_2000_2020__02.csv', sep = delimiter_path))
		
		childbearingt <- K05t %>%
				filter(
						AGE %in% c(4, 5, 6, 7, 8, 9, 10), # women ages 15-49
						SEX == "2"
				) %>%
				group_by(STATE, YEAR) %>%
				dplyr::summarise(Women1550 = sum(POPULATION)) %>%
				left_join(., newbornst) %>%
				mutate(fertrat = Newborns / Women1550) %>%
				filter(YEAR <= test_year)
		
#		write_csv(childbearingt, paste(path_data, 'Load', 'k05_pop_2000_2020__03.csv', sep = delimiter_path))

		
		childbearingt$SEX <- "2"
		childbearingt[mapply(is.infinite, childbearingt)] <- NA
		childbearingt[mapply(is.nan, childbearingt)] <- NA
		childbearingt[is.na(childbearingt)] <-0
		num <- seq(1, FORLEN, 5)
		
#		write_csv(childbearingt, paste(path_data, 'Load', 'k05_pop_2000_2020__04.csv', sep = delimiter_path))
		
		
#		predcwr = function(ccr, sex, x, DF) {
#			hyndtran = function(ccr, DF) { log((ccr - a) / (b - ccr)) }
#			b <- max(DF[[as.character(ccr)]][which(DF$RACE == x)]) * 1.01
#			a <- -0.00000001
#			y <- as_data_frame(hyndtran(DF[[as.character(ccr)]][which(DF$STATE == x & DF$SEX == sex & DF$RACE == this.race)]))
#			
#			num <- seq(1, FORLEN, 5)
#			pred <- tryCatch(
#					round(predict(ucm(value ~ 0, data = y, level = TRUE, slope = FALSE)$model, n.ahead = FORLEN)[c(num), ], 5),
#					error = function(e) array(hyndtran(DF$fertrat[which.max(DF$YEAR)]), c(STEPS))
#			)
#			pred2 <- (b - a) * exp(pred) / (1 + exp(pred)) + a
#			
#			return(round(pred2, 6))
#		}
		
		#forecasst <- as_data_frame(forecast(arima(childbearingt$fertrat, order = arima_order), h = FORLEN)$mean[c(num)])
		
		#auto_test <- auto.arima(childbearingt$fertrat)
		#summary(auto_test)
		
		forecasst <- as_tibble(forecast(arima(childbearingt$fertrat, order = arima_order), h = FORLEN)$mean[c(num)])
		
#		fertrats_20002015<-rbind(fertrats_20002015, as_data_frame(predcwr("fertrat", "2", this.race, childbearingt)) %>%
#		fertrats_20002015<-rbind(fertrats_20002015, forecasst %>%
		fertrats_20002020 <- rbind(
				fertrats_20002020,
				forecasst %>% mutate(STATE = this.state, RACE = this.race, SEX = 2)
		)
	}
}


#source('./SCRIPTS/003-proj_basedataload.R')
source('./Script/003-proj_basedataload.R')
K05_pop <- K05_pop %>%
		#group_by(.dots = GROUPING) %>%
		group_by(across(all_of(GROUPING))) %>%
		dplyr::summarise(POPULATION = sum(POPULATION))


K05_pop$GEOID <- paste0(K05_pop$STATE, K05_pop$COUNTY)
K05_pop$COUNTYRACE <- paste0(K05_pop$GEOID, "_", K05_pop$RACE)

races <- unique(K05_pop$RACE)

#fertrats_20152100<- data.frame()
fertrats_20202100<- data.frame()
for (this.state in stateid) {
	for (this.race in races) {
		K05t <- K05_pop[which(K05_pop$STATE == this.state & K05_pop$RACE == this.race),] %>%
				group_by(YEAR, STATE, RACE, SEX, AGE) %>%
				dplyr::summarise(POPULATION = sum(POPULATION)) %>%
				ungroup()
		
		newbornst <- K05t %>%
				filter(AGE == 1) %>% # AGE 1 = newborns.
				group_by(STATE, RACE, YEAR) %>%
				dplyr::summarise(Newborns = sum(POPULATION))
		
		childbearingt <- K05t %>%
				filter(
						AGE %in% c(4, 5, 6, 7, 8, 9, 10), # women ages 15-49
						SEX == "2"
		) %>%
		group_by(STATE, YEAR) %>%
		dplyr::summarise(Women1550 = sum(POPULATION)) %>%
		left_join(., newbornst) %>%
		mutate(fertrat = Newborns/Women1550) %>%
		filter(YEAR <= test_year)
		
		childbearingt$SEX <- "2"
		childbearingt[mapply(is.infinite, childbearingt)] <- NA
		childbearingt[mapply(is.nan, childbearingt)] <- NA
		childbearingt[is.na(childbearingt)] <-0
		
		num <- seq(1, FORLEN, 5)
		
#		predcwr = function(ccr, sex, x, DF) {
#			hyndtran = function(ccr, DF) { log((ccr - a) / (b - ccr)) }
#			
#			b <- max(DF[[as.character(ccr)]][which(DF$RACE == x)]) * 1.01
#			a <- -0.00000001
#			y <-as_data_frame(hyndtran(DF[[as.character(ccr)]][which(DF$STATE == x & DF$SEX == sex & DF$RACE == this.race)]))
#			
#			num <- seq(1, FORLEN, 5)
#			pred<- tryCatch(
#					round(predict(ucm(value ~ 0, data = y, level = TRUE, slope = FALSE)$model, n.ahead = FORLEN)[c(num),], 5),
#					error = function(e) array(hyndtran(DF$fertrat[which.max(DF$YEAR)]), c(STEPS))
#			)
#			
#			pred2 <- (b - a) * exp(pred) / (1 + exp(pred)) + a
#			
#			return(round(pred2, 6))#
#			
#		}
    	
		forecasst <- as_tibble(forecast(arima(childbearingt$fertrat, order = arima_order), h = FORLEN)$mean[c(num)])
		
		#forecasst <- as_data_frame(forecast(arima(childbearingt$fertrat, order = arima_order), h = FORLEN)$mean[c(num)])
		# fertrats_20152100 <- rbind(fertrats_20152100,as_data_frame(predcwr("fertrat", "2", this.race, childbearingt))) %>%
		#fertrats_20152100 <- rbind(fertrats_20152100, forecasst %>%
		fertrats_20202100 <- rbind(
				fertrats_20202100,
				forecasst %>%
						mutate(
								STATE = this.state,
								RACE = this.race,
								SEX = 2
						)
		)
		
	}
}

#write_csv(fertrats_20002015, "DATA-PROCESSED/state-level-fert-rates_20002015.csv")
#write_csv(fertrats_20152100, "DATA-PROCESSED/state-level-fert-rates_20152100.csv")

write_csv(fertrats_20002020, paste(path_data, 'Processed', 'state-level-fert-rates_20002020.csv', sep = delimiter_path))
write_csv(fertrats_20202100, paste(path_data, 'Processed', 'state-level-fert-rates_20202100.csv', sep = delimiter_path))
