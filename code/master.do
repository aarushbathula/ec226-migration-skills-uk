*******************************************************
* master.do – Run full EC226 pipeline
*******************************************************

version 18
clear all
set more off
set varabbrev off

* Resolve the project root from the current working directory.
capture confirm file "code/master.do"
if _rc == 0 {
    global PROJROOT "`c(pwd)'"
}
else {
    capture confirm file "master.do"
    if _rc == 0 {
        cd ..
        global PROJROOT "`c(pwd)'"
    }
    else {
        di as error "Run master.do from the repo root or from the code/ folder."
        exit 601
    }
}

global RAW    "$PROJROOT/data/raw"
global INT    "$PROJROOT/data/interim"
global FINAL  "$PROJROOT/data/final"
global OUT    "$PROJROOT/output"
global TABLES "$OUT/tables"
global FIGS   "$OUT/figures"
global LOGS   "$OUT/logs"

foreach d in "$RAW" "$INT" "$FINAL" "$OUT" "$TABLES" "$FIGS" "$LOGS" {
    capture mkdir `"`d'"'
}

capture log close _all
log using "$LOGS/master.log", replace text name(ec226_master)

do "$PROJROOT/code/01_data_build.do"
do "$PROJROOT/code/02_analysis.do"

capture log close ec226_master

*******************************************************
* End master.do
*******************************************************
