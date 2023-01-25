/*
 *	  $Author: michaelw $
 *	  Created: January 25, 2023
 *	$Revision: $
 *	 $HeadURL: $
 *
 * Subject
 *	Forecast Checks
 * 
 * Purpose
 *	Statements to visually validate the Fertility Rates.
 *
 * 
 * Dependencies
 * 	-
 *
 * Conversions
 *
 * Notes
 *
 * Assumptions
 * 	-
 * 
 * References
 * 
 * TODO
 * 
 */


SELECT DISTINCT "year", "state_fips", "gender", "race", "rate"
FROM "fertility"
WHERE "state_fips" IN ('17','29')
ORDER BY "year", "state_fips", "gender", "race";