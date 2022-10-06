#
#	  $Author: michaelw $
#	  Created: September 22, 2022
#		$Date: $
#	$Revision: $
#	 $HeadURL: $
#
# Subject
#	Shell script to load the raw data into the database.
#
# Purpose
#	The raw data comes from a variety of sources and is projected to a variety of coordinate systems.  This script along
#	with SQL statements (in another file) loads and then reprojects the data into a consistent location and format.
#
# Output
#
# Dependencies
#
# Conversions
#
# Notes
#	- Prior to running the script, two environmental variables can be set; PGUSERNAME and PGPASSWORD for the PostgreSQL
#	user name and password respectively.  Setting these will simplify calling multiple load statements.
#	- All final tables will be stored to ????.  Some of the source data is already stored with that projection.  For those
#	cases, the load table name does not have a suffix.  The suffix is only used for other coordinate systems and is the
#	SRID for that system.
#
# Assumptions
#	- Command is run from the location of the source data.
#	- The environment variables PGUSERNAME and PGPASSWORD are set to an active PostgreSQL account.
# 
# References
#
# TODO
#
###############################################################################


# Model Commands

# Load Raster Data
# $ raster2pgsql -q -I -C -t auto -s <SRID> <Raster File> <Table Name> | psql -h localhost -d <Database> -U <Username> -W

# Load Vector Data
# $ shp2pgsql -I -s <SRID> <Shape File> <Table Name> | psql -h localhost -d <Database> -U <Username> -W

# Various Formats
# ogr2ogr -f "PostgreSQL" PG:"host=localhost port=5432 dbname=<Database> user=<Username> password=<Password> \
#  <File Geodatabase> -nln <Table> <Layer> -overwrite -progress -nlt PROMOTE_TO_MULTI -lco GEOMETRY_NAME=geom

# ogr2ogr -f "PostgreSQL" PG:"dbname=my_database user=postgres" "source_data.json" -nln destination_table -append


# Population Data
# CDC 1969-2020
psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "population__cdc_1969_2020__raw";
CREATE TABLE "population__cdc_1969_2020__raw" (
	"STATE" CHARACTER(2) NOT NULL,
	"COUNTY" CHARACTER(3) NOT NULL,
	"YEAR" CHARACTER(4) NOT NULL,
	"AGE" INTEGER NOT NULL,
	"RACE" CHARACTER(1) NOT NULL,
	"SEX" CHARACTER(1) NOT NULL,
	"POPULATION" INTEGER,
	"GEOID" CHARACTER(5) NOT NULL,
	"COUNTYRACE" CHARACTER(7) NOT NULL
);\copy population__cdc_1969_2020__raw FROM 'cdc_1969_2020.csv' CSV HEADER;
EOF


# CDC 1990-2020
psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "population__cdc_1990_2020__raw";
CREATE TABLE "population__cdc_1990_2020__raw" (
	"STATE" CHARACTER(2) NOT NULL,
	"COUNTY" CHARACTER(3) NOT NULL,
	"YEAR" CHARACTER(4) NOT NULL,
	"AGE" INTEGER NOT NULL,
	"RACE" CHARACTER(1) NOT NULL,
	"SEX" CHARACTER(1) NOT NULL,
	"POPULATION" INTEGER,
	"GEOID" CHARACTER(5) NOT NULL,
	"COUNTYRACE" CHARACTER(7) NOT NULL
);\copy population__cdc_1990_2020__raw FROM 'cdc_1990_2020.csv' CSV HEADER;
EOF


# Aggregated Data (base year 2000)
# 1969 to 2020
psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "population__sum_1969_2020__raw";
CREATE TABLE "population__sum_1969_2020__raw" (
	"STATE" CHARACTER(2) NOT NULL,
	"COUNTY" CHARACTER(3) NOT NULL,
	"YEAR" CHARACTER(4) NOT NULL,
	"AGE" INTEGER NOT NULL,
	"RACE" CHARACTER(1) NOT NULL,
	"SEX" CHARACTER(1) NOT NULL,
	"POPULATION" INTEGER,
	"GEOID" CHARACTER(5) NOT NULL,
	"COUNTYRACE" CHARACTER(7) NOT NULL,
	"Var1" CHARACTER(3) NOT NULL
);\copy population__sum_1969_2020__raw FROM 'hauer_sum_1969_2020.csv' CSV HEADER;
EOF


# 1990 to 2020
psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "population__sum_1990_2020__raw";
CREATE TABLE "population__sum_1990_2020__raw" (
	"STATE" CHARACTER(2) NOT NULL,
	"COUNTY" CHARACTER(3) NOT NULL,
	"GEOID" CHARACTER(5) NOT NULL,
	"YEAR" CHARACTER(4) NOT NULL,
	"POPULATION" INTEGER
);\copy population__sum_1990_2020__raw FROM 'hauer_sum_1990_2020.csv' CSV HEADER;
EOF



# Census SF1 Intermediate Data
# Post gather() 2010
psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "population__census_2010_17_01__raw";
CREATE TABLE "population__census_2010_17_01__raw" (
	"state" CHARACTER(2) NOT NULL,
	"county" CHARACTER(3) NOT NULL,
	"COUNTY_redux" CHARACTER(3) NOT NULL,
	"NAME" CHARACTER VARYING(100) NOT NULL,
	"table" CHARACTER(9) NOT NULL,
	"TOTAL" INTEGER
);\copy population__census_2010_17_01__raw FROM 'sf1_2010_17.csv' CSV HEADER;
EOF



# State level Fertility Rate Calculation
psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "population__k05_2000_2020__01__raw";
CREATE TABLE "population__k05_2000_2020__01__raw" (
	"STATE" CHARACTER(2) NOT NULL,
	"COUNTY" CHARACTER(3) NOT NULL,
	"YEAR" CHARACTER(4) NOT NULL,
	"AGE" CHARACTER(2) NOT NULL,
	"RACE" CHARACTER(1) NOT NULL,
	"SEX" CHARACTER(1) NOT NULL,
	"POPULATION" INTEGER NOT NULL,
	"GEOID" CHARACTER(5) NOT NULL,
	"COUNTYRACE" CHARACTER(7) NOT NULL
);\copy population__k05_2000_2020__01__raw FROM 'k05_pop_2000_2020__01.csv' CSV HEADER;
EOF


psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "population__k05_2000_2020__02__raw";
CREATE TABLE "population__k05_2000_2020__02__raw" (
	"YEAR" CHARACTER(4) NOT NULL,
	"STATE" CHARACTER(2) NOT NULL,
	"RACE" CHARACTER(1) NOT NULL,
	"SEX" CHARACTER(1) NOT NULL,
	"AGE" CHARACTER(2) NOT NULL,
	"POPULATION" INTEGER NOT NULL
);\copy population__k05_2000_2020__02__raw FROM 'k05_pop_2000_2020__02.csv' CSV HEADER;
EOF



# 002 Base Data Load Verifications
psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "population__k05_dots__raw";
CREATE TABLE "population__k05_dots__raw" (
	"STATE" CHARACTER(2) NOT NULL,
	"COUNTY" CHARACTER(3) NOT NULL,
	"YEAR" CHARACTER(4) NOT NULL,
	"AGE" CHARACTER(2) NOT NULL,
	"RACE" CHARACTER(1) NOT NULL,
	"SEX" CHARACTER(1) NOT NULL,
	"POPULATION" INTEGER NOT NULL
);\copy population__k05_dots__raw FROM 'k05_dots.csv' CSV HEADER;
EOF


psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "population__k05_across__raw";
CREATE TABLE "population__k05_across__raw" (
	"STATE" CHARACTER(2) NOT NULL,
	"COUNTY" CHARACTER(3) NOT NULL,
	"YEAR" CHARACTER(4) NOT NULL,
	"AGE" CHARACTER(2) NOT NULL,
	"RACE" CHARACTER(1) NOT NULL,
	"SEX" CHARACTER(1) NOT NULL,
	"POPULATION" INTEGER NOT NULL
);\copy population__k05_across__raw FROM 'k05_across.csv' CSV HEADER;
EOF


psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "population__k05_across_all__raw";
CREATE TABLE "population__k05_across_all__raw" (
	"STATE" CHARACTER(2) NOT NULL,
	"COUNTY" CHARACTER(3) NOT NULL,
	"YEAR" CHARACTER(4) NOT NULL,
	"AGE" CHARACTER(2) NOT NULL,
	"RACE" CHARACTER(1) NOT NULL,
	"SEX" CHARACTER(1) NOT NULL,
	"POPULATION" INTEGER NOT NULL
);\copy population__k05_across_all__raw FROM 'k05_across_all.csv' CSV HEADER;
EOF




# Newborns
psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "population__k05_2000_2020__02__raw";
CREATE TABLE "population__k05_2000_2020__02__raw" (
	"STATE" CHARACTER(2) NOT NULL,
	"RACE" CHARACTER(1) NOT NULL,
	"YEAR" CHARACTER(4) NOT NULL,
	"Newborns" INTEGER NOT NULL
);\copy population__k05_2000_2020__02__raw FROM 'k05_pop_2000_2020__02.csv' CSV HEADER;
EOF


# Childbearing
psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "population__k05_2000_2020__03__raw";
CREATE TABLE "population__k05_2000_2020__03__raw" (
	"STATE" CHARACTER(2) NOT NULL,
	"YEAR" CHARACTER(4) NOT NULL,
	"Women1550" INTEGER NOT NULL,
	"RACE" CHARACTER(1) NOT NULL,
	"Newborns" INTEGER NOT NULL,
	"fertrat" FLOAT NOT NULL
);\copy population__k05_2000_2020__03__raw FROM 'k05_pop_2000_2020__03.csv' CSV HEADER;
EOF



# value	STATE	RACE	SEX

psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "fertility_rate_2000_2020__raw";
CREATE TABLE "fertility_rate_2000_2020__raw" (
	"value" FLOAT NOT NULL,
	"STATE" CHARACTER(2) NOT NULL,
	"RACE" CHARACTER(1) NOT NULL,
	"SEX" CHARACTER(1) NOT NULL
);\copy fertility_rate_2000_2020__raw FROM 'state-level-fert-rates_20002020.csv' CSV HEADER;
EOF



psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "fertility_rate_2020_2100__raw";
CREATE TABLE "fertility_rate_2020_2100__raw" (
	"value" FLOAT NOT NULL,
	"STATE" CHARACTER(2) NOT NULL,
	"RACE" CHARACTER(1) NOT NULL,
	"SEX" CHARACTER(1) NOT NULL
);\copy fertility_rate_2020_2100__raw FROM 'state-level-fert-rates_20202100.csv' CSV HEADER;
EOF


# County Level Projections (CDC)
# 2000 to 2020
psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "population_eval_2000_2020__raw";
CREATE TABLE "population_eval_2000_2020__raw" (
	"var" CHARACTER(3) NOT NULL,
	"year" CHARACTER(4) NOT NULL,
	"gender" CHARACTER(1) NOT NULL,
	"county_race" CHARACTER(7) NOT NULL,
	"type" CHARACTER(4) NOT NULL,
	"age" CHARACTER(2) NOT NULL,
	"a" FLOAT,
	"b" FLOAT,
	"c" FLOAT
);
\copy population_eval_2000_2020__raw FROM 'COUNTY_20002020_17.csv' CSV HEADER;
\copy population_eval_2000_2020__raw FROM 'COUNTY_20002020_29.csv' CSV HEADER;
EOF


# 2020 to 2100 
psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "population_proj_2020_2100__raw";
CREATE TABLE "population_proj_2020_2100__raw" (
	"var" CHARACTER(3) NOT NULL,
	"year" CHARACTER(4) NOT NULL,
	"gender" CHARACTER(1) NOT NULL,
	"county_race" CHARACTER(7) NOT NULL,
	"type" CHARACTER(4) NOT NULL,
	"age" CHARACTER(2) NOT NULL,
	"a" FLOAT,
	"b" FLOAT,
	"c" FLOAT
);
\copy population_proj_2020_2100__raw FROM 'COUNTY_20202100_17.csv' CSV HEADER;
\copy population_proj_2020_2100__raw FROM 'COUNTY_20202100_29.csv' CSV HEADER;
EOF




psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "projection_final__raw";
CREATE TABLE "projection_final__raw" (
	"year" CHARACTER(4) NOT NULL,
	"gender" CHARACTER(1) NOT NULL,
	"state_fips" CHARACTER(2) NOT NULL,
	"county_fips" CHARACTER(3) NOT NULL,
	"geoid" CHARACTER(5) NOT NULL,
	"race" CHARACTER(1) NOT NULL,
	"age_group" CHARACTER(2) NOT NULL,
	"ssp1" FLOAT,
	"ssp2" FLOAT,
	"ssp3" FLOAT,
	"ssp4" FLOAT,
	"ssp5" FLOAT
);
\copy projection_final__raw FROM 'SSP_raw.csv' CSV HEADER NULL 'NA';
EOF



psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "population__ratio__raw";
CREATE TABLE "population__ratio__raw" (
	"Var1" CHARACTER(3) NOT NULL,
	"YEAR" CHARACTER(4) NOT NULL,
	"SEX" CHARACTER(1) NOT NULL,
	"COUNTYRACE" CHARACTER(7) NOT NULL,
	"TYPE" CHARACTER(7) NOT NULL,
	"AGE" CHARACTER(2) NOT NULL,
	"A" FLOAT,
	"B" FLOAT,
	"C" FLOAT,
	"STATE" CHARACTER(2) NOT NULL,
	"COUNTY" CHARACTER(3) NOT NULL,
	"GEOID" CHARACTER(5) NOT NULL,
	"RACE" CHARACTER(1) NOT NULL,
	"POPULATION" FLOAT,
	"NAME" CHARACTER VARYING(100) NOT NULL,
	"state" CHARACTER(2) NOT NULL,
	"poptot" FLOAT,
	"percentage" FLOAT
);
\copy population__ratio__raw FROM 'Population_ratio.csv' CSV HEADER NULL 'NA';
EOF



# SSP
psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "projection_ssp__raw";
CREATE TABLE "projection_ssp__raw" (
	"gender" CHARACTER(1) NOT NULL,
	"age_group" CHARACTER(2) NOT NULL,
	"year" CHARACTER(4) NOT NULL,
	"ssp1" FLOAT,
	"ssp2" FLOAT,
	"ssp3" FLOAT,
	"ssp4" FLOAT,
	"ssp5" FLOAT
);
\copy projection_ssp__raw FROM 'SSP_processed.csv' CSV HEADER NULL 'NA';
EOF



# Projections
psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "projection_asrc__raw";
CREATE TABLE "projection_asrc__raw" (
	"year" CHARACTER(4) NOT NULL,
	"gender" CHARACTER(1) NOT NULL,
	"state_fips" CHARACTER(2) NOT NULL,
	"county_fips" CHARACTER(3) NOT NULL,
	"geoid" CHARACTER(5) NOT NULL,
	"race" CHARACTER(1) NOT NULL,
	"age_group" CHARACTER(2) NOT NULL,
	"ssp1" FLOAT,
	"ssp2" FLOAT,
	"ssp3" FLOAT,
	"ssp4" FLOAT,
	"ssp5" FLOAT
);
\copy projection_asrc__raw FROM 'SSP_asrc.csv' CSV HEADER NULL 'NA';
EOF





# YEAR,SEX,AGE,SSP1,SSP2,SSP3,SSP4,SSP5,SSP1_rate,SSP2_rate,SSP3_rate,SSP4_rate,SSP5_rate,SSP1_baseline,SSP2_baseline,SSP3_baseline,SSP4_baseline,SSP5_baseline
psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "ssp_rate__raw";
CREATE TABLE "ssp_rate__raw" (
	"year" CHARACTER(4) NOT NULL,
	"gender" CHARACTER(1) NOT NULL,
	"age_group" CHARACTER(2) NOT NULL,
	"ssp1" FLOAT,
	"ssp2" FLOAT,
	"ssp3" FLOAT,
	"ssp4" FLOAT,
	"ssp5" FLOAT,
	"ssp1_rate" FLOAT,
	"ssp2_rate" FLOAT,
	"ssp3_rate" FLOAT,
	"ssp4_rate" FLOAT,
	"ssp5_rate" FLOAT,
	"ssp1_baseline" FLOAT,
	"ssp2_baseline" FLOAT,
	"ssp3_baseline" FLOAT,
	"ssp4_baseline" FLOAT,
	"ssp5_baseline" FLOAT
);
\copy ssp_rate__raw FROM 'SSP_03_rates.csv' CSV HEADER NULL 'NA';
EOF

#state	county	NAME	SEX	Race	Age	TOTAL
psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "population__census_2000__raw";
CREATE TABLE "population__census_2000__raw" (
	"state" CHARACTER(2) NOT NULL,
	"county" CHARACTER(3) NOT NULL,
	"NAME" CHARACTER VARYING(50) NOT NULL,
	"SEX" CHARACTER(6) NOT NULL,
	"Race" CHARACTER VARYING(15) NOT NULL,
	"Age" INTEGER NOT NULL,
	"TOTAL" INTEGER
);
\copy population__census_2000__raw FROM 'population_2000_17.csv' CSV HEADER NULL 'NA';
\copy population__census_2000__raw FROM 'population_2000_29.csv' CSV HEADER NULL 'NA';
EOF


psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "population__census_2000_hh__raw";
CREATE TABLE "population__census_2000_hh__raw" (
	"state" CHARACTER(2) NOT NULL,
	"county" CHARACTER(3) NOT NULL,
	"NAME" CHARACTER VARYING(50) NOT NULL,
	"SEX" CHARACTER(6) NOT NULL,
	"Race" CHARACTER VARYING(15) NOT NULL,
	"Age" INTEGER NOT NULL,
	"HHPOP" INTEGER
);
\copy population__census_2000_hh__raw FROM 'population_2000_hh_17.csv' CSV HEADER NULL 'NA';
\copy population__census_2000_hh__raw FROM 'population_2000_hh_29.csv' CSV HEADER NULL 'NA';
EOF



# Census SF1 Processed Data
# Group Quarters 2000 Intermediate
psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "population__census_2000_gq__raw";
CREATE TABLE "population__census_2000_gq__raw" (
	"SEX" CHARACTER(6) NOT NULL,
	"RACE" CHARACTER VARYING(15) NOT NULL,
	"AGEGRP" INTEGER NOT NULL,
	"GQ" INTEGER,
	"YEAR" CHARACTER(4) NOT NULL,
	"STATE" CHARACTER(2) NOT NULL,
	"COUNTY" CHARACTER(3) NOT NULL
);
\copy population__census_2000_gq__raw FROM 'population_2000_gq_17.csv' CSV HEADER NULL 'NA';
\copy population__census_2000_gq__raw FROM 'population_2000_gq_29.csv' CSV HEADER NULL 'NA';
EOF


# Group Quarters 2000 Final
psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "population__census_2000_gq__raw";
CREATE TABLE "population__census_2000_gq__raw" (
	"gender" CHARACTER(10) NOT NULL,
	"race" CHARACTER(15) NOT NULL,
	"age_group" CHARACTER(2) NOT NULL,
	"population" INTEGER NOT NULL,
	"year" CHARACTER(4) NOT NULL,
	"state_fips" CHARACTER(2) NOT NULL,
	"county_fips" CHARACTER(3) NOT NULL
);\copy population__census_2000_gq__raw FROM 'gq_2000.csv' CSV HEADER;
EOF


# Group Quarters 2010 Final
psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "population__census_2010_gq__raw";
CREATE TABLE "population__census_2010_gq__raw" (
	"race" CHARACTER(15) NOT NULL,
	"population" INTEGER NOT NULL,
	"year" CHARACTER(4) NOT NULL,
	"state_fips" CHARACTER(2) NOT NULL,
	"county_fips" CHARACTER(3) NOT NULL,
	"gender" CHARACTER(6) NOT NULL,
	"age_group" CHARACTER(2) NOT NULL
);\copy population__census_2010_gq__raw FROM 'gq_2010.csv' CSV HEADER;
EOF



# Estimates
psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "population__00_k05_launch__raw" CASCADE;
CREATE TABLE "population__00_k05_launch__raw" (
	"state_fips" CHARACTER(2) NOT NULL,
	"county_fips" CHARACTER(3) NOT NULL,
	"geoid" CHARACTER(5) NOT NULL,
	"year" CHARACTER(4) NOT NULL,
	"race" CHARACTER(1) NOT NULL,
	"gender" CHARACTER(1) NOT NULL,
	"population" INTEGER NOT NULL
);
\copy population__00_k05_launch__raw FROM 'Population_00_K05_launch.csv' CSV HEADER;
EOF


psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "population__01_z__raw" CASCADE;
CREATE TABLE "population__01_z__raw" (
	"Var1" CHARACTER(3) NOT NULL,
	"year" CHARACTER(4) NOT NULL,
	"gender" CHARACTER(6) NOT NULL,
	"county_race" CHARACTER(7) NOT NULL,
	"type" CHARACTER(10) NOT NULL,
	"age_group" INTEGER NOT NULL,
	"a" FLOAT,
	"b" FLOAT,
	"c" FLOAT,
	"state_fips" CHARACTER(2) NOT NULL,
	"county_fips" CHARACTER(3) NOT NULL,
	"geoid" CHARACTER(5) NOT NULL,
	"race" CHARACTER(15) NOT NULL
);
\copy population__01_z__raw FROM 'Population_01_z.csv' CSV HEADER;
EOF


psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "population__02_basesum__raw" CASCADE;
CREATE TABLE "population__02_basesum__raw" (
	"state_fips" CHARACTER(2) NOT NULL,
	"county_fips" CHARACTER(3) NOT NULL,
	"geoid" CHARACTER(5) NOT NULL,
	"population" INTEGER,
	"race" CHARACTER(15) NOT NULL
);
\copy population__02_basesum__raw FROM 'Population_02_basesum.csv' CSV HEADER;
EOF


psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "population__03_addsum__raw" CASCADE;
CREATE TABLE "population__03_addsum__raw" (
	"state_fips" CHARACTER(2) NOT NULL,
	"county_fips" CHARACTER(3) NOT NULL,
	"geoid" CHARACTER(5) NOT NULL,
	"race" CHARACTER(15) NOT NULL,
	"type" CHARACTER(7) NOT NULL,
	"a" FLOAT
);
\copy population__03_addsum__raw FROM 'Population_03_addsum.csv' CSV HEADER;
EOF

# STATE,COUNTY,GEOID,RACE,COMBINED
psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "population__04_addmult__raw";
CREATE TABLE "population__04_addmult__raw" (
	"state_fips" CHARACTER(2) NOT NULL,
	"county_fips" CHARACTER(3) NOT NULL,
	"geoid" CHARACTER(5) NOT NULL,
	"race" CHARACTER(15) NOT NULL,
	"combined" CHARACTER(7) NOT NULL
);
\copy population__04_addmult__raw FROM 'Population_04_addmult.csv' CSV HEADER;
EOF


# Var1,YEAR,SEX,COUNTYRACE,TYPE,AGE,A,B,C,STATE,COUNTY,GEOID,RACE
psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "population__05_combined__raw";
CREATE TABLE "population__05_combined__raw" (
	"Var1" CHARACTER(3) NOT NULL,
	"year" CHARACTER(4) NOT NULL,
	"gender" CHARACTER(6) NOT NULL,
	"county_race" CHARACTER(7) NOT NULL,
	"type" CHARACTER(10) NOT NULL,
	"age_group" INTEGER NOT NULL,
	"a" FLOAT,
	"b" FLOAT,
	"c" FLOAT,
	"state_fips" CHARACTER(2) NOT NULL,
	"county_fips" CHARACTER(3) NOT NULL,
	"geoid" CHARACTER(5) NOT NULL,
	"race" CHARACTER(15) NOT NULL
);
\copy population__05_combined__raw FROM 'Population_05_combined.csv' CSV HEADER;
EOF



# Var1,YEAR,SEX,COUNTYRACE,TYPE,AGE,A,B,C,STATE,COUNTY,GEOID,RACE
psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "population__06_z2__raw";
CREATE TABLE "population__06_z2__raw" (
	"Var1" CHARACTER(3) NOT NULL,
	"year" CHARACTER(4) NOT NULL,
	"gender" CHARACTER(6) NOT NULL,
	"county_race" CHARACTER(7) NOT NULL,
	"type" CHARACTER(10) NOT NULL,
	"age_group" INTEGER NOT NULL,
	"a" FLOAT,
	"b" FLOAT,
	"c" FLOAT,
	"state_fips" CHARACTER(2) NOT NULL,
	"county_fips" CHARACTER(3) NOT NULL,
	"geoid" CHARACTER(5) NOT NULL,
	"race" CHARACTER(15) NOT NULL
);
\copy population__06_z2__raw FROM 'Population_06_z2.csv' CSV HEADER;
EOF




# Final Projection
# Var1,YEAR,SEX,COUNTYRACE,TYPE,AGE,A,B,C,STATE,COUNTY,GEOID,RACE,POPULATION,NAME,state,poptot,percentage
psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "projection__11_totals2__raw";
CREATE TABLE "projection__11_totals2__raw" (
	"var1" CHARACTER(3) NOT NULL,
	"year" CHARACTER(4) NOT NULL,
	"gender" CHARACTER(6) NOT NULL,
	"county_race" CHARACTER(7) NOT NULL,
	"type" CHARACTER(10) NOT NULL,
	"age_group" INTEGER NOT NULL,
	"a" FLOAT,
	"b" FLOAT,
	"c" FLOAT,
	"state_fips" CHARACTER(2) NOT NULL,
	"count_fips" CHARACTER(3) NOT NULL,
	"geoid" CHARACTER(5) NOT NULL,
	"race" CHARACTER(15) NOT NULL,
	"population" FLOAT,
	"name" CHARACTER VARYING(100) NOT NULL,
	"state" CHARACTER(2) NOT NULL,
	"poptot" FLOAT,
	"percentage" FLOAT
);\copy projection__11_totals2__raw FROM 'Population_11_totals2.csv' CSV HEADER;
EOF




# SSP
# SEX,AGE,YEAR,SSP1,SSP2,SSP3,SSP4,SSP5
psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "ssp__01_prepared__raw";
CREATE TABLE "ssp__01_prepared__raw" (
	"gender" CHARACTER(1) NOT NULL,
	"age_group" CHARACTER(2) NOT NULL,
	"year" CHARACTER(4) NOT NULL,
	"ssp1" FLOAT,
	"ssp2" FLOAT,
	"ssp3" FLOAT,
	"ssp4" FLOAT,
	"ssp5" FLOAT
);
\copy ssp__01_prepared__raw FROM 'SSP_01_prepared.csv' CSV HEADER NULL 'NA';
EOF







psql -h localhost -d csm -U $PGUSERNAME -w <<EOF
DROP TABLE IF EXISTS "population__z3__raw";
CREATE TABLE "population__z3__raw" (
	"Var1" CHARACTER(3) NOT NULL,
	"YEAR" CHARACTER(4) NOT NULL,
	"SEX" CHARACTER(6) NOT NULL,
	"COUNTYRACE" CHARACTER(7) NOT NULL,
	"TYPE" CHARACTER(10) NOT NULL,
	"AGE" INTEGER NOT NULL,
	"A" FLOAT,
	"B" FLOAT,
	"C" FLOAT,
	"STATE" CHARACTER(2) NOT NULL,
	"COUNTY" CHARACTER(3) NOT NULL,
	"GEOID" CHARACTER(5) NOT NULL,
	"RACE" CHARACTER(15) NOT NULL,
	"NAME" CHARACTER VARYING(100) NOT NULL,
	"state" CHARACTER(2) NOT NULL
);\copy population__z3__raw FROM 'Population_z3.csv' CSV HEADER;
EOF


