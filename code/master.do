*******************************************************
* master.do – Run full EC226 pipeline
*******************************************************

version 18
clear all
set more off

* EDIT root once here
global PROJROOT "/path/to/ec226-migration-skills-uk"

do "$PROJROOT/code/01_data_build.do"
do "$PROJROOT/code/02_analysis.do"

*******************************************************
* End master.do
*******************************************************
