#
#	  $Author: michaelw $
#	  Created: September 18, 2022
#		$Date: $
#	$Revision: $
#	 $HeadURL: $
#
# Subject
#	Download CDC Population Estimates and Prepare for Cohort Survival Model Analysis Evaluation
#
# Purpose
#	This script downloads and prepares the data required to validate the projections.  Using the CDC 1969 - 2000 base data,
#	population data are prepared to be used to generate projections for the years 2000, 2005, 2015, and 2020.  The data
#	is not used directly by this script rather this script is called from other scripts that depend upon the initialized
#	data frames.
#	
#	This script is derived from the R code written by Mathew E. Hauer (see References).
#
# Output (datasets set for global use but not persistently stored)
#	- K05_pop		Population Estimates for each year in the range 1969 to 2000
#	- K05_launch 	Population Estimates for the year 2000
#	- K05_launch2	Population Estimates for the years 2000, 2005, 2010, 2015, and 2020
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
#	- Migrate the shapefile download and creation to another script; perhaps the mapping script.
#
###############################################################################



###------DATA LOAD-----
## @knitr basedataload


# Setting the groupings
GROUPING <- c("STATE", "COUNTY", "YEAR", "AGE", "RACE", "SEX")

# TEST YEAR IS SET TO 2000
test_year = 2000

# LAUNCH YEAR IS THE SAME AS THE TEST YEAR
launch_year = test_year

# THE NUMBER OF AGE GROUPS
SIZE <- 18

# NUMBER OF PROJECTION STEPS 2000 to 2020
STEPS <- 4

# FORECAST LENGTH. SINCE THE PROJECTION INTERVAL IS 5 YEARS IT IS (STEPS * 5)
FORLEN <- (STEPS * 5)

# TODO This is poor style and needs to be updated.
years <- 0
years$YEAR <- seq(launch_year + 5, launch_year + (STEPS * 5), 5)
years$YEAR <- seq(launch_year + 1, launch_year + STEPS, 1)


file <- 'us.1969_2020.19ages.adjusted'
##############################################################
#
# DOWNLOADING THE CDC POPULATION ESTIMATES FOR 1969-2016.
#
# IF RUNNING THIS SCRIPT FOR THE FIRST LINE, Run the download.file line and the gunzip line.
#
#download.file(
#		paste('https://seer.cancer.gov/popdata/yr1969_2020.19ages/', file, '.txt.gz', sep = ''),
##		"https://seer.cancer.gov/popdata/yr1969_2016.19ages/us.1969_2016.19ages.adjusted.txt.gz",
#		paste(
#				path_data,
#				paste(file, 'txt.gz', sep = '.'),
#				sep = delimiter_path
#		)
#)
# UNZIPPING THE DATA FILE
# "DATA/us.1969_2016.19ages.adjusted.txt.gz"
#gunzip(paste(path_data, paste(file, 'txt.gz', sep = '.'), sep = delimiter_path), overwrite = TRUE, remove = TRUE)
#
###################################################################

# READING THE cdc DATA INTO R. THE DATA ARE IN A SINGLE COLUMN FORMAT AND SO THEY MUST BE BROKEN APART.
K05_pop<- read.table(paste(path_data, paste(file, 'txt', sep = '.'), sep = delimiter_path)) 
K05_pop$V1 <- as.character(K05_pop$V1) # SETTING THE ENTIRE SINGLE VARIABLE INTO A CHARACTER
K05_pop$YEAR <- as.numeric(substr(K05_pop$V1, 1, 4)) # SEPARATING THE YEAR AND SETTING IT AS A NUMBER
K05_pop$STATEID <- substr(K05_pop$V1, 5, 6) # SEPARATING THE 2 CHARACTER STATE ABBREVIATION
K05_pop$STATE <- substr(K05_pop$V1, 7, 8) # SEPARATING THE 2-DIGIT STATE CODE
K05_pop$COUNTY <- substr(K05_pop$V1,9, 11) # SEPARATING THE 3-DIGIT COUNTY CODE
K05_pop$REGISTRY <- substr(K05_pop$V1, 12, 12) # REGISTRY IS A THROW AWAY VARIABLE REFERING TO ODD GEOGRAPHIES
K05_pop$RACE <- substr(K05_pop$V1, 14, 14) # SEPARATING OUT THE RACE CODES.
K05_pop$ORIGIN <- substr(K05_pop$V1, 15, 15) # SEPARATING OUT HISPANIC ORIGIN. THIS VARIABLE IS NOT APPLICABLE IN THE 1969-2016 DATA
K05_pop$SEX <- substr(K05_pop$V1, 16, 16) # SEPARATING OUT THE SEX DATA

# SEPARATING OUT AGE CATEGORIES. THE CDC DATA CONSISTS OF 19 AGE GROUPS WHERE "00" IS CODED AS 0 YEAR OLDS AND "01" IS CODED AS 1-4 YEAR OLDS.
# I RECODE 00 TO 01 TO CREATE A 0-4 YEAR OLD AGE GROUP.
K05_pop$AGE <- as.numeric(if_else(substr(K05_pop$V1, 17, 18) == "00", "01", substr(K05_pop$V1, 17, 18)))

K05_pop$POPULATION <- as.numeric(substr(K05_pop$V1, 19, 30)) # SEPARATING THE ACTUAL POPULATION ESTIMATES.

# THE DATA NEED TO BE AGGREGATED TO THE LEVEL OF ANALYSIS BASED ON THE GROUPING FROM ABOVE. THIS IS TO SUM THE 0 AND 1-4 AGE GROUPS
# INTO THE 0-4 AGE GROUP
K05_pop <- K05_pop %>%
		group_by(across(all_of(GROUPING))) %>%
		dplyr::summarise(POPULATION = sum(POPULATION))

K05_pop$GEOID <- paste0(K05_pop$STATE, K05_pop$COUNTY) # SETTING THE 5-DIGIT FIPS CODE
K05_pop$COUNTYRACE <- paste0(K05_pop$GEOID, "_", K05_pop$RACE) # CREATING A UNIQUE VARIABLE THAT IS 0000_1 FOR EACH COUNTY-RACE COMBINATION



# SEPARATING OUT THE LAUNCH POPULATION AND SUMMING TO THE COUNTY TOTAL.
K05_launch <- K05_pop[which(K05_pop$YEAR == launch_year),] %>%
		group_by(STATE, COUNTY, GEOID, YEAR) %>%
		dplyr::summarise(POPULATION = sum(POPULATION)) %>%
		ungroup()

# CREATING OUTPUTS FOR EACH EVALUATION POPULATION: 2000, 2005, 2010, 2015, and 2020.
K05_launch2 <- K05_pop[which(K05_pop$YEAR %in% c(launch_year, launch_year + 5, launch_year + 10, launch_year + 15, launch_year + 20)),]
K05_launch2$COUNTYRACE <- paste0(K05_launch2$GEOID, "_", K05_launch2$RACE)
K05_launch2$Var1 = paste0("a", K05_launch2$AGE) # CREATING A NEW VARIABLE BASED ON THE AGE GROUP.



# DOWNLOADING A COUNTY-SHAPEFILE, CONVERTING THE MAP PROJECTION, AND THEN ELIMINATING THE OUTERLYING US TERRITORIES (GUAM, PUERTO RICO, ETC.)
counties <- counties(cb = TRUE)
counties <- st_transform(counties, CRS(workspace_crs)) %>%
		subset(GEOID %in% c('17119', '17133', '17163', '29071', '29099', '29183', '29189', '29510'))


#subset(!(STATEFP %in% c("60", "64","66", "68", "69", "70", "74","72", "78")))
# DOWNLOAD A US STATES SHAPEFILE
states <- states(cb = TRUE)
states <- st_transform(states, CRS(workspace_crs)) %>%
		subset(GEOID %in% c('17', '29'))
