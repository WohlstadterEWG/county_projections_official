#
#	  $Author: michaelw $
#	  Created: September 18, 2022
#		$Date: $
#	$Revision: $
#	 $HeadURL: $
#
# Subject
#	Load Libraries for Project
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
#	- Any SQLite command that performs spatial operations will require the SpatiaLite extension.  This extension is loaded
#	per connection with the statement "SELECT LOAD_EXTENSION('mod_spatialite');".
#
# Assumptions
# 
# References
#	- "Population Projections for U.S. Counties by Age, Sex, and Race Controlled to Shared Socioeconomic Pathway" by Mathew
#	E. Hauer
#
# TODO
#	- Review the use of pacman to manage packages. The library hasn't been updated in a while and it is really just sugar.
#	- Research if there is a dbi command to execute multiple SQL statements.
#	- Correct wrap the clusters.  Currently warnings are generated because clusters are initialized here and left hanging.
#	That's not good programming practice.  Any unit of work that uses clusters should start the cluster, perform the work,
#	then close the cluster with parallel::stopCluster.
#
###############################################################################


###------LIBRARY SETUP-----
## @knitr libraries

rm(list = ls()) # Remove Previous Workspace
gc(reset = TRUE) # Garbage Collection


# R Workspace Options
options(scipen = 12) # Scientific Notation
options(digits = 6) # Specify Digits
options(java.parameters = "-Xmx1000m") # Increase Java Heap Size
options(dplyr.summarise.inform = FALSE)


# Functions, Libraries, & Parallel Computing 
## Functions 
# Specify Number of Digits (Forward)
numb_digits_F <- function(x, y) {
	numb_digits_F <- do.call("paste0", list(paste0(rep(0, y - nchar(x)), collapse = ""), x))
	numb_digits_F <- ifelse(nchar(x) < y, numb_digits_F, x)
}

# Remove Double Space 
numb_spaces <- function(x) gsub("[[:space:]]{2,}", " ", x)


# Install and load pacman for easier package loading and installation
if (!require("pacman", character.only = TRUE)){
	install.packages("pacman", dep = TRUE)
	if (!require("pacman", character.only = TRUE))
		stop("Package not found")
}


# Libraries
packages <- c(
	"tidyverse",     # Tidyverse
	'dplyr',
	"data.table",    # Data Management/Manipulation
	"doParallel",    # Parallel Computing
	"foreach",       # Parallel Computing
	"openxlsx",      # Microsoft Excel Files
	"stringi",       #Character/String Editor
	"stringr",       # Character/String Editor
	"zoo",           # Time Series
	"reshape2",      # Data Management/Manipulation
	"scales",        # Number formatting
	"cowplot",       # Plot Grids
	"tmap",          # Cartography
	"tmaptools",     # Cartographic tools
	"tigris",        # US shapefiles
	"censusapi",     # Census Data
	'sf',				# MDW replace sp
	'rgdal',			# MDW replace sp.  Note this library will itself need to be replaced soon.
#	"sp",            # Spatial Objects
	"grid",          # Plot Grids
	"kableExtra",    # Pretty Tables
	"LexisPlotR",    # Lexis Diagrams
	"pdftools",      # Load pdfs
	"R.utils",       # Utilities
	"forecast",      # Forecasting
	"pbmcapply",     # Progress Bar Multicore Apply
#	"parallelsugar", # Parallel apply			(Perhaps no longer available?  Only required for the limpish Windows anyway.)
	"rucm",           # UCM
	"IDPmisc",        # Quality na.rm
	"tidycensus",     # Census Data
	'here',
	'properties',
	'RSQLite'
)

# Install missing packages
# Will only run if at least one package is missing
if(!sum(!p_isinstalled(packages)) == 0) {
	p_install(
		package = packages[!p_isinstalled(packages)], 
		character.only = TRUE
	)
}

# load the packages
p_load(packages, character.only = TRUE)
rm(packages)

# Operating System Specific Settings
system <- Sys.info()

if (system['sysname'] == 'Darwin' || system['sysname'] == 'Windows') {
	username <- unname(system['user'])
	if (system['sysname'] == 'Windows') {
		delimiter_path <- '\\'
		
		# Parallel computing is not directly supported under Windows.
		cores <- 1
	} else {
		delimiter_path <- '/'
		
		cores <- detectCores() - 1
	}
} else {
	# Assumed to be either Linux or Unix.
	username <- Sys.getenv('LOGNAME')
	delimiter_path <- '/'
	
	cores <- detectCores() - 1
}


## Parallel Computing 
# Establish Parallel Computing Cluster
clusters <- makeCluster(cores) # Create Cluster with Specified Number of Cores
registerDoParallel(clusters) # Register Cluster

# Parallel Computing Details
getDoParWorkers() # Determine Number of Utilized Clusters
getDoParName() #  Name of the Currently Registered Parallel Computing Backend
getDoParVersion() #  Version of the Currently Registered Parallel Computing Backend



# Files Accessed
# User Credentials
properties <- read.properties(paste(Sys.getenv('R_USER_HOME'), 'account.properties', sep = delimiter_path), encoding = 'ASCII')


# Configuration
path_base <- here()
configuration <- read.properties(paste(path_base, 'Script', 'configuration.properties', sep = delimiter_path), encoding = 'ASCII')
constants <- read.properties(paste(path_base, 'Script', 'application.properties', sep = delimiter_path), encoding = 'ASCII')



# Configuration (move to file)
path_data <- configuration$path_data

# Census API Key
key_census <- properties$api.key.census



# Processing Settings
workspace_crs <- constants$workspace_crs

# Setting the global arima model
arima_order <- c(
		as.numeric(constants$arima_model_ar_terms),
		as.numeric(constants$arima_model_differencing),
		as.numeric(constants$arima_model_ma_terms)
)
arma <- constants$arma


# Persistent Storage (any SQL database will work)
connection <- dbConnect(
		RSQLite::SQLite(),
		dbname = paste(configuration$path_database, configuration$database_file, sep = delimiter_path),
		synchronous = 'normal'
)

# Performance Tuning (also the synchronous setting in the connect)
# If the database file is stored on a network share (don't) WAL cannot be used.
# Also WAL is better during writes and may not be as useful for this application if reading is the dominant action.
dbExecute(connection, 'PRAGMA journal_mode = WAL;')
dbExecute(connection, 'PRAGMA temp_store = memory;')
dbExecute(connection, 'PRAGMA mmap_size = 30000000000;')

# For Spatial Operations
#dbExecute(connection, "SELECT LOAD_EXTENSION('mod_spatialite');")



# Fails on Windows
#install.packages('devtools')
#library(devtools)
#install_github('pschmied/RSQLite.spatialite')


# Poor design as the asymetric coding conceals code and is fragile.
#dbDisconnect(connection)
