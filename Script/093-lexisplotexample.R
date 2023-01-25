#
#	  $Author: michaelw $
#	   Forked: September 22, 2022
#		$Date: $
#	$Revision: $
#	 $HeadURL: $
#
# Subject
#	Generate f Figure for the Maintext.pdf Document
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


####-------Lexis Diagram Example-------
## @knitr lexisplot


for (package in c(
		'LexisPlotR',
		'cowplot'
)
		) {
	if (!require(package, character.only = TRUE)) {
		print(package)
		install.packages(package, repos = 'http://cran.wustl.edu')
		if (!require(package, character.only = TRUE)) {
			stop(paste('could not install', package, collapse = ' '))
		}
	}
}

#library(LexisPlotR)
#library(cowplot)
#figtop<- lexis.grid2(year.start = 2010, year.end = 2020, age.start = 0, age.end = 5, d = 5) + 
figtop<- lexis_grid(year_start = 2010, year_end = 2020, age_start = 0, age_end = 5, delta = 5) +
  annotate("text", x = as.Date("2014-07-01"), y =3.9, label = "120",fontface =2) +
  annotate("text", x = as.Date("2010-11-01"), y = 0.3, label = "100",fontface =2) +
  # annotate("text", x = as.Date("2012-06-01"), y = 3, label = "120/100 = 1.25", angle = 45,fontface =2) +
  annotate("text", x = as.Date("2015-11-01"), y = 0.3, label = "90",fontface =2) +
  annotate("text", x = as.Date("2019-07-01"), y = 3.9, label = "108", fontface = 'italic') +
  annotate("text", x = as.Date("2017-06-01"), y = 3, label = "(120/100) * 90", angle = 45) +
  labs(title = "Cohort Change Ratios (CCRs)")

#figbot<- lexis.grid2(year.start = 2010, year.end = 2020, age.start = 0, age.end = 5, d = 5) + 
figbot<- lexis_grid(year_start = 2010, year_end = 2020, age_start = 0, age_end = 5, delta = 5) +
  annotate("text", x = as.Date("2014-07-01"), y =3.9, label = "120",fontface =2) +
  annotate("text", x = as.Date("2010-11-01"), y = 0.3, label = "100",fontface =2) +
  # annotate("text", x = as.Date("2012-06-01"), y = 3, label = "120-100 = +25", angle = 45,fontface =2) +
  annotate("text", x = as.Date("2015-11-01"), y = 0.3, label = "90",fontface =2) +
  annotate("text", x = as.Date("2019-07-01"), y = 3.9, label = "110", fontface = 'italic') +
  annotate("text", x = as.Date("2017-06-01"), y = 3, label = "(120-100) + 90", angle = 45) +
  labs(title = "Cohort Change Differences (CCDs)")

plot_grid(figtop, figbot, ncol = 1, labels = "auto")
