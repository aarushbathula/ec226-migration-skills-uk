*******************************************************
* 01_data_build.do – Build final EC226 dataset
*******************************************************

version 18
clear all
set more off
set varabbrev off

* 0. Project paths ---------------------------------------------------------
* EDIT THIS to point to the root of your EC226 repo
global PROJROOT "/path/to/ec226-migration-skills-uk"

global RAW    "$PROJROOT/data/raw"
global INT    "$PROJROOT/data/interim"
global FINAL  "$PROJROOT/data/final"
global OUT    "$PROJROOT/output"
global TABLES "$OUT/tables"
global FIGS   "$OUT/figures"
global LOGS   "$OUT/logs"

* create folders if they don't exist
foreach d in "$RAW" "$INT" "$FINAL" "$OUT" "$TABLES" "$FIGS" "$LOGS" {
    capture mkdir `"`d'"'
}

* Raw / intermediate filenames
local cwfile    "$INT/country_crosswalk.dta"
local gdpdt     "$RAW/gdp_per_capita_2021.dta"
local census21  "$RAW/2021.dta"
local censusgdp "$INT/census_with_gdp.dta"
local distdt    "$RAW/dist_cepii.dta"
local distdtcw  "$INT/crosswalk_withdist.dta"
local rawtert   "$RAW/API_SE.XPD.TERT.PC.ZS_DS2_en_csv_v2_27784.csv"
local tertdt    "$INT/tert_exp_latest.dta"

************************************************************************
* SECTION 1: Dataset merging and cleaning
************************************************************************

* 1.2 Crosswalk: country_of_birth -> WB code + colonial + home English ---
clear
input float country_of_birth_25a str3 wb_country_code str50 wb_country_name ///
      byte colonies_post_1945 byte home_english
-8.0  ""     ""                   .  .
1.0   "GBR"  "United Kingdom"     .  .
2.0   "IRL"  "Ireland"            0  1
3.0   "FRA"  "France"             0  0
4.0   "DEU"  "Germany"            0  0
5.0   "ITA"  "Italy"              0  0
6.0   "PRT"  "Portugal"           0  0
7.0   ""     ""                   .  .
8.0   "POL"  "Poland"             0  0
9.0   ""     ""                   .  .
10.0  "HRV"  "Croatia"            0  0
11.0  ""     ""                   .  .
12.0  "NGA"  "Nigeria"            1  1
13.0  "ZAF"  "South Africa"       1  1
14.0  ""     ""                   .  .
15.0  "CHN"  "China"              0  0
16.0  "BGD"  "Bangladesh"         1  1
17.0  "IND"  "India"              1  1
18.0  "PAK"  "Pakistan"           1  1
19.0  ""     ""                   .  .
20.0  "CAN"  "Canada"             0  1
21.0  "USA"  "United States"      0  1
22.0  "JAM"  "Jamaica"            1  1
23.0  ""     ""                   .  .
24.0  ""     ""                   .  .
end
save "`cwfile'", replace

* 1.3 Tertiary expenditure: scrape latest value from CSV -------------------
import delimited using "`rawtert'", clear encoding(UTF-8)
rename (v1 v2 v3 v4) (wb_country_name wb_country_code series_name series_code)

ds wb_country_name wb_country_code series_name series_code, not
local yrvars `r(varlist)'

destring `yrvars', replace force
egen tert_exp_latest = rowlast(`yrvars')

keep wb_country_name wb_country_code tert_exp_latest
bys wb_country_code: keep if _n == 1
save "`tertdt'", replace

* 1.4 Crosswalk + GDP + tertiary expenditure ------------------------------
use "`cwfile'", clear

* (a) merge GDP per capita
merge m:1 wb_country_code using "`gdpdt'"
keep if inlist(_merge,1,3)
drop _merge

* (b) merge tertiary exp.
merge m:1 wb_country_code using "`tertdt'"
keep if inlist(_merge,1,3)
drop _merge

save "`cwmerged'", replace

* 1.5 Distances to UK ------------------------------------------------------
use "`distdt'", clear
keep if iso_d == "GBR"
keep iso_o dist
rename (iso_o dist) (wb_country_code migration_distance)
save "`distdtcw'", replace

* 1.6 Merge in GDP and tertiary again (defensive) -------------------------
use "`cwmerged'", clear
merge m:1 wb_country_code using "`gdpdt'"
keep if inlist(_merge,1,3)
drop _merge

merge m:1 wb_country_code using "`tertdt'"
keep if inlist(_merge,1,3)
drop _merge

save "`cwmerged'", replace

* 1.7 Merge with census and drop missing GDP ------------------------------
use "`census21'", clear
destring country_of_birth_25a, replace
merge m:1 country_of_birth_25a using "`cwmerged'"
keep if !missing(gdp_per_capita_2021)
save "`censusgdp'", replace

* 1.8 Keep relevant variables ---------------------------------------------
keep resident_id_m country_of_birth_25a hrp_ns_sec resident_age_74m ///
     highest_qualification sex year_arrival_uk economic_activity_status_17m ///
     migration_distance gdp_per_capita_2021 colonies_post_1945 region ///
     tert_exp_latest home_english

* 1.9 Time spent in UK (midpoints) ----------------------------------------
gen time_spent_in_uk = .
replace time_spent_in_uk = 2021 - 1950    if year_arrival_uk == 2
replace time_spent_in_uk = 2021 - 1955.5  if year_arrival_uk == 3
replace time_spent_in_uk = 2021 - 1965.5  if year_arrival_uk == 4
replace time_spent_in_uk = 2021 - 1975.5  if year_arrival_uk == 5
replace time_spent_in_uk = 2021 - 1985.5  if year_arrival_uk == 6
replace time_spent_in_uk = 2021 - 1995.5  if year_arrival_uk == 7
replace time_spent_in_uk = 2021 - 2005.5  if year_arrival_uk == 8
replace time_spent_in_uk = 2021 - 2012    if year_arrival_uk == 9
replace time_spent_in_uk = 2021 - 2015    if year_arrival_uk == 10
replace time_spent_in_uk = 2021 - 2018    if year_arrival_uk == 11
replace time_spent_in_uk = 2021 - 2020.5  if year_arrival_uk == 12
replace time_spent_in_uk = resident_age_74m if year_arrival_uk == 1
replace time_spent_in_uk = . if year_arrival_uk == -8

* 1.10 UK-born vs foreign-born --------------------------------------------
gen uk_born = .
replace uk_born = 1 if year_arrival_uk == 1
replace uk_born = 0 if inlist(year_arrival_uk,2,3,4,5,6,7,8,9,10,11,12)
label define uk_born_lbl 1 "UK-born" 0 "Foreign-born"
label values uk_born uk_born_lbl

* 1.11 Brexit cohorts ------------------------------------------------------
gen brexit_cohort = .
replace brexit_cohort = 0 if inlist(year_arrival_uk,2,3,4,5,6,7,8,9,10)
replace brexit_cohort = 1 if inlist(year_arrival_uk,11,12)
label define brexit_lbl 0 "Pre-Brexit" 1 "Post-Brexit"
label values brexit_cohort brexit_lbl

replace brexit_cohort = 0 if uk_born == 1

* 1.12 Age / employment filters -------------------------------------------
keep if resident_age_74m >= 25 & resident_age_74m <= 65
keep if inlist(economic_activity_status_17m,1,2,3,4,5,6,8,9,10)

* 1.13 Skill groups from NS-SEC -------------------------------------------
drop if hrp_ns_sec < 1 | hrp_ns_sec > 13

gen hrp_ns_sec_grouped = .
replace hrp_ns_sec_grouped = 1 if inrange(hrp_ns_sec,1,3)
replace hrp_ns_sec_grouped = 2 if inrange(hrp_ns_sec,4,7)
replace hrp_ns_sec_grouped = 3 if inrange(hrp_ns_sec,8,13)

label define hrp_ns_group_lbl 1 "High-Skill" 2 "Medium-Skill" 3 "Low-Skill"
label values hrp_ns_sec_grouped hrp_ns_group_lbl

* 1.14 Drop intermediate arrival/activity vars ----------------------------
drop year_arrival_uk economic_activity_status_17m hrp_ns_sec

* 1.15 Region numeric ------------------------------------------------------
encode region, gen(region_num)
drop if region_num == 10   // drop "outside UK" etc if needed

* 1.16 ln(GDP per capita) --------------------------------------------------
gen lgdp_per_capita_2021 = ln(gdp_per_capita_2021)

* 1.17 Labels --------------------------------------------------------------
label define cob_short ///
    1   "United Kingdom" ///
    2   "Ireland" ///
    3   "France" ///
    4   "Germany" ///
    5   "Italy" ///
    6   "Portugal" ///
    8   "Poland" ///
   10   "Croatia" ///
   12   "Nigeria" ///
   13   "South Africa" ///
   15   "China" ///
   16   "Bangladesh" ///
   17   "India" ///
   18   "Pakistan" ///
   20   "Canada" ///
   21   "United States" ///
   22   "Jamaica", replace
label values country_of_birth_25a cob_short

label variable highest_qualification "Highest qualification"
label define hiqual_short ///
    1 "Level 1 & entry level" ///
    2 "Level 2" ///
    3 "Apprenticeship" ///
    4 "Level 3" ///
    5 "Level 4" ///
    6 "Other (vocational/other)", replace
label values highest_qualification hiqual_short

label variable resident_age_74m "Age (years)"
gen double age_sq = resident_age_74m^2
label variable age_sq "Age squared (years²)"

label variable time_spent_in_uk "Time spent in UK (years)"

label variable colonies_post_1945 "Colonial status as of 1945"
label define colonies_post_1945_lbl 0 "Not a colony as of 1945" 1 "Colony as of 1945", replace
label values colonies_post_1945 colonies_post_1945_lbl

label variable gdp_per_capita_2021 "GDP per capita, 2021 (US$)"
label variable lgdp_per_capita_2021 "Log GDP per capita, 2021 (US$)"

label variable uk_born "Birth cohort: UK-born vs Foreign-born"
label define uk_born_lbl 0 "Foreign-born" 1 "UK-born", replace
label values uk_born uk_born_lbl

label variable brexit_cohort "Brexit cohort (0=Pre, 1=Post)"
label define brexit_lbl 0 "Pre-Brexit" 1 "Post-Brexit", replace
label values brexit_cohort brexit_lbl

label variable hrp_ns_sec_grouped "Grouped NS-SEC skill category"
label define hrp_ns_group_lbl 1 "High-Skill" 2 "Medium-Skill" 3 "Low-Skill", replace
label values hrp_ns_sec_grouped hrp_ns_group_lbl

label variable migration_distance "Migration distance to UK, 2019 (1000 km)"
label variable home_english "Home Language English"
label variable tert_exp_latest "Tertiary Education Expenditure"

* 1.18 Save final dataset --------------------------------------------------
save "$FINAL/finaldataset.dta", replace

*******************************************************
* End 01_data_build.do
*******************************************************
