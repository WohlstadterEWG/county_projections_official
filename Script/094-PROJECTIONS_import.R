#
#	  $Author: michaelw $
#	  Created: September 22, 2022
#		$Date: $
#	$Revision: $
#	 $HeadURL: $
#
# Subject
#	Generate Final SSP Weighted Projections for the Maintext.pdf Document
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


###------FIPSCODES-----
## @knitr projections



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
# Configuration
path_base <- here()
configuration <- read.properties(paste(path_base, 'Script', 'configuration.properties', sep = delimiter_path), encoding = 'ASCII')



# Configuration (move to file)
path_data <- configuration$path_data



#SSPs<- read_csv("DATA-PROCESSED/SSP_asrc.csv")
SSPs <- read.csv(paste(path_data, 'Processed', 'SSP_asrc.csv', sep = delimiter_path))
  # mutate(GEOID = case_when(
  #   GEOID=="46113"~ "46102", # Shannon County (46113)'s name changed to Oglala Lakota (46102)
  #   GEOID== "51917" ~ "51019", # Bedford City (51917) is merged into Bedford County (51019)
  #   GEOID == "02270" ~ "02158", # Wade Hampton (02270) is actually (02158)
  #   TRUE ~ as.character(GEOID)
  # ))
        

# zzz<- SSPs[which(SSPs$GEOID=="51917"),]