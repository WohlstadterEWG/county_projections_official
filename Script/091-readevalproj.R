#
#	  $Author: michaelw $
#	  Created: September 22, 2022
#		$Date: $
#	$Revision: $
#	 $HeadURL: $
#
# Subject
#	Generate the Maintext.pdf Document
#
# Purpose
#	This script is derived from the R code written by Mathew E. Hauer (see References).
#
# Output (datasets set for global use but not persistently stored)
#	- Maintext.pdf
#
# Dependencies
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
#
###############################################################################


###------Read the Eval Projections-----
## @knitr readevalproj


# Prequisites:
#	- 002 and 003
source('./Script/002-basedataload.R')   # loading the base data
#source('./Script/003-proj_basedataload.R')   # loading the base data

# Operating System Specific Settings
system <- Sys.info()

if (system['sysname'] == 'Darwin' || system['sysname'] == 'Windows') {
	username <- unname(system['user'])
	if (system['sysname'] == 'Windows') {
		delimiter_path <- '\\'
	} else {
		delimiter_path <- '/'
	}
} else {
	# Assumed to be either Linux or Unix.
	username <- Sys.getenv('LOGNAME')
	delimiter_path <- '/'
}

# Files Accessed
# User Credentials
properties <- read.properties(paste(Sys.getenv('R_USER_HOME'), 'account.properties', sep = delimiter_path), encoding = 'ASCII')


# Configuration
path_base <- here()
configuration <- read.properties(paste(path_base, 'Script', 'configuration.properties', sep = delimiter_path), encoding = 'ASCII')
constants <- read.properties(paste(path_base, 'Script', 'application.properties', sep = delimiter_path), encoding = 'ASCII')



# Configuration (move to file)
path_data <- configuration$path_data


K05_launch <- K05_pop[which(K05_pop$YEAR == launch_year),] %>%
  group_by(STATE, COUNTY, RACE, GEOID, YEAR) %>%
  dplyr::summarise(POPULATION = sum(POPULATION)) %>%
  ungroup()


files <- paste(
		path_data,
		'Projections',
		'Eval',
		list.files(path = paste(path_data, 'Projections', 'Eval', sep = delimiter_path), pattern = '.csv'),
		sep = delimiter_path
)
#files <- paste0("PROJECTIONS/EVAL//", list.files(path = "./PROJECTIONS/EVAL/",pattern = ".csv"))
#temp <- as.list(files)
#temp <- lapply(files, fread, sep=" ")
temp <- lapply(as.list(files), fread)
z <- rbindlist( temp ) %>%
  # dplyr::rename(YEAR = V3,
  #               SEX = V4,
  #               COUNTYRACE = V5,
  #               TYPE = V6,
  #               AGE = V7,
  #               A = V8,
  #               B = V9,
  #               C = V10,
  #               Var1 = V2) %>%
  mutate(STATE= substr(COUNTYRACE, 1,2),
         COUNTY = substr(COUNTYRACE, 3,5),
         GEOID = paste0(STATE, COUNTY),
         A = if_else(A<0, 0, A),
         B = if_else(B<0, 0, B),
         C = if_else(C<0,0, C),
         RACE = substr(COUNTYRACE, 7,7))
z[is.na(z)] <-0
basesum <-  K05_launch[which( K05_launch$YEAR == launch_year),] %>%
  dplyr::select(STATE, COUNTY, RACE, GEOID, POPULATION)

addsum <- z[which(z$TYPE=="ADD" & z$YEAR == (launch_year+FORLEN)),] %>%
  group_by(STATE, COUNTY, RACE, GEOID, TYPE) %>%
  dplyr::summarise(A = sum(A))

addmult <- left_join(addsum, basesum) %>%
  mutate(COMBINED = if_else(A>= POPULATION, "ADD" ,"Mult")) %>%
  dplyr::select(STATE, COUNTY, RACE, GEOID, COMBINED)

addmult[is.na(addmult)] <- "ADD"



combined<- left_join(z, addmult) %>%
  filter(TYPE == COMBINED) %>%
  mutate(TYPE = "ADDMULT") %>%
  dplyr::select(-COMBINED)

z<- rbind(z, combined) %>%
#  dplyr::select(-V1) %>%		# Seems to already be selected out (above)
  mutate(TYPE = case_when(
  TYPE == "ADD" ~ "CCD",
  TYPE == "Mult" ~ "CCR",
  TYPE == "ADDMULT" ~ "CCD/CCR"
))
z$SEX<-as.character(z$SEX) # converting from integer to character to join with K05_launch2
z<-  left_join(as.data.frame(z), as.data.frame(K05_launch2))
z<- left_join(z, countynames)
z[is.na(z)] <-0
base_projunfitted<- filter(z,
           !GEOID %in% c("02900", "04910", "15900", "35910", "36910", "51910", "51911","51911", "51913", "51914", "51915", "51916", "51918"),
           !YEAR == 2020) %>%
  mutate(GEOID = case_when(
    GEOID=="46113"~ "46102",		# County change
    GEOID== "51917" ~ "51019",		# County change
    TRUE ~ as.character(GEOID)))

countynumber <- base_projunfitted %>%
  filter(!TYPE == "BASE") %>%
  group_by(STATE, COUNTY, GEOID, YEAR, TYPE) %>%
  dplyr::summarise(POPULATION = sum(POPULATION, na.rm=T),
                   A = sum(A, na.rm=T),
                   B = sum(B),
                   C = sum(C),
                   num = length(A)) %>%
  mutate(FLAG1 = if_else(is.na((A/POPULATION)-1), 0,abs((A/POPULATION)-1)),
         FLAG2 = if_else(POPULATION>=B & POPULATION<=C,1,0),
         in90percentile = FLAG2/num) %>%
  ungroup() %>%
  filter(YEAR == 2015,
         TYPE == "CCD/CCR") %>%
  dplyr::select(FLAG1, STATE, GEOID) %>%
  NaRV.omit()

base_projunfitted<- filter(base_projunfitted, GEOID %in% countynumber$GEOID)
