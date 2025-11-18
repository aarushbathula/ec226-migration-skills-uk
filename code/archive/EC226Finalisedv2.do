

*–––– step 0: setting project root directory, you just have to replace it with your directory and ensure the directory contains World Bank GDPpc Data, World Bank Tertiary Expenditure data (with interpolation) and 2021 UK Census Data
global PROJROOT "/Users/marcuschoi/Desktop/warwick/year 2/Econ/Econometrics/Project/Working FIles" 


* no need to change any of the below
local cwfile     "$PROJROOT/country_crosswalk.dta"
local rawgdp     "$PROJROOT/API_NY.GDP.PCAP.CD_DS2_en_csv_v2_19346.csv"
local gdpdt      "$PROJROOT/gdp_per_capita_2021.dta"
local cwmerged   "$PROJROOT/country_crosswalk_merged.dta"
local census21   "$PROJROOT/2021.dta"
local censusgdp  "$PROJROOT/census_with_gdp.dta"
local distdt	 "$PROJROOT/dist_cepii.dta"
local distdtcw	 "$PROJROOT/crosswalk_withdist.dta"
local rawtert	 "$PROJROOT/API_SE.XPD.TERT.PC.ZS_DS2_en_csv_v2_27784.csv"
local tertdt	 "$PROJROOT/tert_exp_latest.dta"

//––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
// SECTION 1: Dataset merging and cleaning
//––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

*–––– step 1.1: clearing workspace and set up environment
clear all


*–––– step 1.2: creating crosswalk (mapping country of birth to World Bank country codes) and adding indicator of colonial status as of 2nd September 1945 as well as home country english dummy
input float country_of_birth_25a str3 wb_country_code str50 wb_country_name byte colonies_post_1945  byte home_english
-8.0  ""     ""                   .		.
1.0   "GBR"  "United Kingdom"     .		.
2.0   "IRL"  "Ireland"            0		1
3.0   "FRA"  "France"             0		0
4.0   "DEU"  "Germany"            0		0
5.0   "ITA"  "Italy"              0		0
6.0   "PRT"  "Portugal"           0		0
7.0   ""     ""                   .		.
8.0   "POL"  "Poland"             0		0
9.0   ""     ""                   .		.
10.0  "HRV"  "Croatia"            0		0
11.0  ""     ""                   .		.
12.0  "NGA"  "Nigeria"            1		1
13.0  "ZAF"  "South Africa"       1		1
14.0  ""     ""                   .		.
15.0  "CHN"  "China"              0		0
16.0  "BGD"  "Bangladesh"         1		1
17.0  "IND"  "India"              1		1
18.0  "PAK"  "Pakistan"           1		1
19.0  ""     ""                   .		.
20.0  "CAN"  "Canada"             0		1
21.0  "USA"  "United States"      0		1
22.0  "JAM"  "Jamaica"            1		1
23.0  ""     ""                   .		.
24.0  ""     ""                   .		.
end
save "`cwfile'", replace


*–––– step 1.3: importing and cleaning tertiary education expenditure (built-in egen function to manually scrape through data to find latest figure in CSV)
import delimited using "`rawtert'", clear encoding(UTF-8)
rename (v1 v2 v3 v4) (wb_country_name wb_country_code series_name series_code )
ds wb_country_name wb_country_code series_name series_code, not
local yrvars `r(varlist)'

destring `yrvars', replace force

egen tert_exp_latest = rowlast(`yrvars')   
keep wb_country_name wb_country_code tert_exp_latest
bysort wb_country_code: keep if _n == 1

save "`tertdt'", replace


*–––– step 1.4: merging crosswalk with GDP data and tertiary expenditure data
use "`cwfile'", clear
* (a) Merge GDP per capita
merge m:1 wb_country_code using "`gdpdt'"
keep if inlist(_merge,1,3)    // keep CW-only & matched
drop _merge                   // drop before the next merge

* (b) Merge tertiary expenditure
merge m:1 wb_country_code using "`tertdt'"
keep if inlist(_merge,1,3)
drop _merge

save "`cwmerged'", replace


*–––– step 1.5: importing distances 
use "`distdt'", clear
keep if iso_d == "GBR"
keep iso_o dist 
rename (iso_o dist) (wb_country_code migration_distance)
save "`distdtcw'", replace


*–––– step 1.6: merging crosswalk, gdp
use "`cwmerged'", clear
merge m:1 wb_country_code using "`gdpdt'"    
keep if inlist(_merge,1,3)                    
drop _merge                                  
merge m:1 wb_country_code using "`tertdt'"    
keep if inlist(_merge,1,3)                    
drop _merge                                  
save "`cwmerged'", replace

*–––– step 1.7: merging with census data and dropping observations with missing GDPpc
use "`census21'", clear
destring country_of_birth_25a, replace
merge m:1 country_of_birth_25a using "`cwmerged'"
keep if !missing(gdp_per_capita_2021)
save "`censusgdp'", replace


*–––– step 1.8: grouping only relevant variables
keep resident_id_m country_of_birth_25a hrp_ns_sec resident_age_74m highest_qualification sex year_arrival_uk economic_activity_status_17m migration_distance gdp_per_capita_2021 colonies_post_1945 region tert_exp_latest home_english


*–––– step 1.9: deriving time_spent_in_uk manually (assume midpoints)
gen time_spent_in_uk = .
replace time_spent_in_uk = 2021 - 1950 if year_arrival_uk == 2    // Before 1951
replace time_spent_in_uk = 2021 - 1955.5 if year_arrival_uk == 3  // 1951 to 1960
replace time_spent_in_uk = 2021 - 1965.5 if year_arrival_uk == 4  // 1961 to 1970
replace time_spent_in_uk = 2021 - 1975.5 if year_arrival_uk == 5  // 1971 to 1980
replace time_spent_in_uk = 2021 - 1985.5 if year_arrival_uk == 6  // 1981 to 1990
replace time_spent_in_uk = 2021 - 1995.5 if year_arrival_uk == 7  // 1991 to 2000
replace time_spent_in_uk = 2021 - 2005.5 if year_arrival_uk == 8  // 2001 to 2010
replace time_spent_in_uk = 2021 - 2012 if year_arrival_uk == 9    // 2011 to 2013
replace time_spent_in_uk = 2021 - 2015 if year_arrival_uk == 10   // 2014 to 2016
replace time_spent_in_uk = 2021 - 2018 if year_arrival_uk == 11   // 2017 to 2019
replace time_spent_in_uk = 2021 - 2020.5 if year_arrival_uk == 12 // 2020 to 2021
replace time_spent_in_uk = resident_age_74m if year_arrival_uk == 1
replace time_spent_in_uk = . if year_arrival_uk == -8


*–––– step 1.10: creating UK-born and foreign-born cohorts
gen uk_born = .
replace uk_born = 1 if year_arrival_uk == 1  // UK-born
replace uk_born = 0 if inlist(year_arrival_uk, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)  // Foreign-born
label define uk_born_lbl 1 "UK-born" 0 "Foreign-born"
label values uk_born uk_born_lbl


*–––– step 1.11: creating pre-Brexit and post-Brexit cohorts
gen brexit_cohort = .
replace brexit_cohort = 0 if inlist(year_arrival_uk, 2, 3, 4, 5, 6, 7, 8, 9, 10)  // Pre-Brexit (before 2016, including 2014-2016)
replace brexit_cohort = 1 if inlist(year_arrival_uk, 11, 12)                     // Post-Brexit (2017 onward)
label define brexit_lbl 0 "Pre-Brexit" 1 "Post-Brexit"
label values brexit_cohort brexit_lbl

replace brexit_cohort = 0 if uk_born==1   // treat all Brits as "Pre-Brexit" so they appear in both exercises


*–––– step 1.12: applying baseline filters (all individuals are between the ages of 25-65 and employed)
keep if resident_age_74m >= 25 & resident_age_74m <= 65
keep if inlist(economic_activity_status_17m, 1, 2, 3, 4, 5, 6, 8, 9, 10)


*–––– step 1.13: classifying skilled and non-skilled workers and drop invalid NS-SEC values (keeps only employed individuals, codes 1 to 13)
drop if hrp_ns_sec < 1 | hrp_ns_sec > 13

gen hrp_ns_sec_grouped = .
replace hrp_ns_sec_grouped = 1 if inrange(hrp_ns_sec, 1, 3)   // High-skilled
replace hrp_ns_sec_grouped = 2 if inrange(hrp_ns_sec, 4, 7)   // Medium-skilled
replace hrp_ns_sec_grouped = 3 if inrange(hrp_ns_sec, 8, 13)  // Low-skilled

label define hrp_ns_group_lbl 1 "High-Skill" 2 "Medium-Skill" 3 "Low-Skill"
label values hrp_ns_sec_grouped hrp_ns_group_lbl


*–––– step 1.14: dropping all intermediate variables until this point
drop year_arrival_uk economic_activity_status_17m hrp_ns_sec


*–––– step 1.15: destring and reformat the region 
encode region, gen(region_num)
drop if region_num == 10


*–––– step 1.16: generating log gdp_per_capita_2021	
gen lgdp_per_capita_2021 = ln(gdp_per_capita_2021)


*–––– step 1.17: cleaning variable labels

label define cob_short ///
    1   "United Kingdom"   ///
    2   "Ireland"          ///
    3   "France"           ///
    4   "Germany"          ///
    5   "Italy"            ///
    6   "Portugal"         ///
    8   "Poland"           ///
   10   "Croatia"          ///
   12   "Nigeria"          ///
   13   "South Africa"     ///
   15   "China"            ///
   16   "Bangladesh"       ///
   17   "India"            ///
   18   "Pakistan"         ///
   20   "Canada"           ///
   21   "United States"    ///
   22   "Jamaica", replace
label values country_of_birth_25a cob_short

label variable highest_qualification "Highest qualification"
label define hiqual_short ///
    1 "Level 1 & entry level"    ///
    2 "Level 2"                  ///
    3 "Apprenticeship"           ///
    4 "Level 3"                  ///
    5 "Level 4"                  ///
    6 "Other (vocational/other)", replace
label values highest_qualification hiqual_short

label variable resident_age_74m "Age (years)"
gen double age_sq = resident_age_74m^2
label variable age_sq "Age squared (years²)"

label variable time_spent_in_uk "Time spent in UK (years)"

label variable colonies_post_1945 "Colonial status as of 1945"
label define colonies_post_1945_lbl ///
    0 "Not a colony as of 1945"         ///
    1 "Colony as of 1945", replace
label values colonies_post_1945 colonies_post_1945_lbl

label variable gdp_per_capita_2021 "GDP per capita, 2021 (US$)"
label variable lgdp_per_capita_2021 "Log GDP per capita, 2021 (US$)"

label variable uk_born "Birth cohort: UK-born vs Foreign-born"
label define uk_born_lbl ///
    0 "Foreign-born" ///
    1 "UK-born", replace
label values uk_born uk_born_lbl

label variable brexit_cohort "Brexit cohort (0=Pre, 1=Post)"
label define brexit_lbl ///
    0 "Pre-Brexit"   ///
    1 "Post-Brexit", replace
label values brexit_cohort brexit_lbl

label variable hrp_ns_sec_grouped "Grouped NS-SEC skill category"
label define hrp_ns_group_lbl ///
    1 "High-Skill"   ///
    2 "Medium-Skill" ///
    3 "Low-Skill", replace
label values hrp_ns_sec_grouped hrp_ns_group_lbl

label variable migration_distance "Migration distance to UK, 2019 (1000 km)"
label variable home_english "Home Language English"
label variable tert_exp_latest "Tertiary Education Expenditure"


*–––– step 1.18: saving final dataset
save "${PROJROOT}/finaldataset.dta", replace

*–––– step 1.19: generating summary statistics for hrp_ns_sec_grouped
estpost tab hrp_ns_sec_grouped uk_born
esttab using profession_distribution.tex, replace ///
    cells("b pct") ///
    nomtitle nonumber noobs ///
    title(Profession Distribution by Birth Origin) ///
    label
	
*–––– step 1.20: generating summary statistics for highest_qualification
gen highest_qualification_groups = ""
replace highest_qualification_groups = "N/A" if highest_qualification == -8 // does not apply
replace highest_qualification_groups = "No qualifications" if highest_qualification == 0
replace highest_qualification_groups = "GCSE" if highest_qualification >=1 & highest_qualification <= 2 
replace highest_qualification_groups = "Apprenticeship" if highest_qualification == 3
replace highest_qualification_groups = "A levels" if highest_qualification == 4 
replace highest_qualification_groups = "Bachelors or above" if highest_qualification == 5
replace highest_qualification_groups = "Others" if highest_qualification == 6 

estpost tab highest_qualification_groups uk_born
esttab using education_distribution.tex, replace ///
    cells("b pct") ///
    nomtitle nonumber noobs ///
    title(Education Distribution by Birth Origin) ///
    label

*–––– step 1.21: generating summary statistics for country_of_birth_25a
	estpost tab country_of_birth_25a 
esttab using country_distribution.tex, replace ///
    cells("b pct") ///
    nomtitle nonumber noobs ///
    title(Distribution Country of Origin) ///
    label

*–––– step 1.22: generating summary statistics for home_english
	estpost tab home_english 
esttab using home_eng_distribution.tex, replace ///
    cells("b pct") ///
    nomtitle nonumber noobs ///
    title(Distribution of home_english) ///
    label	
	
*–––– step 1.23: generating summary statistics for region_num

	estpost tab region_num
esttab using region_distribution.tex, replace ///
    cells("b pct") ///
    nomtitle nonumber noobs ///
    title(Distribution of Region of Residence) ///
    label


//––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
// SECTION 2: Country effects: Ordered-Probit 
//––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

*–––– step 2.0: re-initialising dataset and applying section-specific filter (male only)
use "${PROJROOT}/finaldataset.dta", clear 
keep if sex == 2


*–––– step 2.1: re-organising categories for ordered-probit
gen hrp_ns_sec_ordered = 4 - hrp_ns_sec_grouped
label define skill_order 1 "Low" 2 "Medium" 3 "High", replace
label values hrp_ns_sec_ordered skill_order


*–––– step 2.2: running and storing base model
oprobit hrp_ns_sec_ordered ///
      i.country_of_birth_25a ///
      i.highest_qualification ///
	  i.region_num				///
      c.resident_age_74m		///
	  c.age_sq ///
      c.time_spent_in_uk
estimates store base


*–––– step 2.3: computing margins for high-skill occupations
estimates restore base
margins country_of_birth_25a, predict(outcome(3)) atmeans post
estimates store high
outreg2 using margins.tex, replace ctitle("High-Skill Probit") ///
 label bdec(3) se


*–––– step 2.4: computing margins for medium-skill occupations
estimates restore base
margins country_of_birth_25a, predict(outcome(2)) atmeans post
estimates store med
outreg2 using margins.tex, append ctitle("Medium-Skill Probit") ///
 label bdec(3) se


*–––– step 2.5: computing margins for low-skill occupations
estimates restore base
margins country_of_birth_25a, predict(outcome(1)) atmeans post
estimates store low
outreg2 using margins.tex, append ctitle("Low-Skill Probit") ///
 label bdec(3) se


*–––– step 2.6: restoring estimates and predicting probabilities
estimates restore base

predict p_low_probit  , outcome(1)
predict p_med_probit  , outcome(2)
predict p_high_probit , outcome(3)

*–––– step 2.7: collapsing to country means
collapse (mean) p_high_probit p_med_probit p_low_probit ///
                lgdp_per_capita_2021 migration_distance tert_exp_latest ///
                colonies_post_1945 home_english, ///
        by(country_of_birth_25a)


*–––– step 2.9: assigning labels to generated probabilities
label variable p_high_probit  "Mean predicted probability of high‐skill employment"
label variable p_med_probit   "Mean predicted probability of medium‐skill employment"
label variable p_low_probit   "Mean predicted probability of low‐skill employment"

label variable migration_distance "Migration distance to UK, 2019 (1000 km)"
label variable home_english "Home Language English"
label variable lgdp_per_capita_2021 "Log GDP per capita, 2021 (US$)"


*–––– step 2.10: constructing second-stage variable groups
local basevars	 lgdp_per_capita_2021 migration_distance
local tertvars   `basevars' tert_exp_latest
local colvars    `basevars' colonies_post_1945
local homevars	 `basevars' home_english

*–––– step 2.11: constructing basis model (most important variables based on consensus literature)
 
*–––– [1] High–skill (base model)
regress p_high_probit `basevars', robust
linktest
estat   ovtest
estat   vif
outreg2 using secondstagebase.tex, replace ///
    ctitle("High-Base") ///
    label bdec(3) se ///
    keep(`basevars')

*–––– [2] Medium–skill (base model)
regress p_med_probit `basevars', robust
linktest
estat   ovtest
estat   vif
outreg2 using secondstagebase.tex, append ///
    ctitle("Medium-Base") ///
    label bdec(3) se ///
    keep(`basevars')
	
*–––– [3] Low–skill (base model)
regress p_low_probit `basevars', robust
linktest
estat   ovtest
estat   vif
outreg2 using secondstagebase.tex, append ///
    ctitle("Low-Base") ///
    label bdec(3) se ///
    keep(`basevars')
 
*–––– step 2.12: adding further regressors (limited mentions in variables based on consensus literature)

*–––– [4] High–skill (tertiary education model)
regress p_high_probit `tertvars', robust
linktest
estat   ovtest
estat   vif
outreg2 using secondstagetert.tex, replace ///
    ctitle("High-Tertiary") ///
    label bdec(3) se ///
    keep(`tertvars')

*–––– [5] Medium–skill (tertiary education model)
regress p_med_probit   `tertvars', robust
linktest
estat   ovtest
estat   vif
outreg2 using secondstagetert.tex, append ///
    ctitle("Medium-Tertiary") ///
    label bdec(3) se ///
    keep(`tertvars')
	
*–––– [6] Low–skill (tertiary education model)
regress p_low_probit   `tertvars', robust
linktest
estat   ovtest
estat   vif
outreg2 using secondstagetert.tex, append ///
    ctitle("Low-Tertiary") ///
    label bdec(3) se ///
    keep(`tertvars')

* very marginal effects, barely significant and does not contribute much to the F-score/R^2-value

*–––– [7] High–skill (colonial status model)
regress p_high_probit `colvars', robust
linktest
estat   ovtest
estat   vif
outreg2 using secondstagecol.tex, replace ///
    ctitle("High-Colonial") ///
    label bdec(3) se ///
    keep(`colvars')

*–––– [8] Medium–skill (colonial status model)
regress p_med_probit   `colvars', robust
linktest
estat   ovtest
estat   vif
outreg2 using secondstagecol.tex, append ///
    ctitle("Medium-Colonial") ///
    label bdec(3) se ///
    keep(`colvars')
	
*–––– [9] Low–skill (colonial status model)
regress p_low_probit   `colvars', robust
linktest
estat   ovtest
estat   vif
outreg2 using secondstagecol.tex, append ///
    ctitle("Low-Colonial") ///
    label bdec(3) se ///
    keep(`colvars')

* moderate multicollinearity according to vif test (add more reason after final run)

*–––– [10] High–skill (home status model)
regress p_high_probit `homevars', robust
linktest
estat   ovtest
estat   vif
outreg2 using secondstagehome.tex, replace ///
    ctitle("High-Home") ///
    label bdec(3) se ///
    keep(`homevars')

*–––– [11] Medium–skill (home status model)
regress p_med_probit   `homevars', robust
linktest
estat   ovtest
estat   vif
outreg2 using secondstagehome.tex, append ///
    ctitle("Medium-Home") ///
    label bdec(3) se ///
    keep(`homevars')
	
*–––– [12] Low–skill (home status model)
regress p_low_probit   `homevars', robust
linktest
estat   ovtest
estat   vif
outreg2 using secondstagehome.tex, append ///
    ctitle("Low-Home") ///
    label bdec(3) se ///
    keep(`homevars')

* arrive at conclusion that they are almost significant at 10%; these predictions (and coefficients) are in line with the predictions of existing literature in the field.


*–––– step 2.13: creating scatterplots to attempt to visualise relationships
set scheme s1mono, permanently
label values country_of_birth_25a cob_short

*–––– [1] High–skill (against GDPpc)
twoway ///
    (scatter p_high_probit lgdp_per_capita_2021, ///
        mlabel(country_of_birth_25a) mlabposition(12) ///
        msymbol(circle_hollow) msize(medium)) ///
    (lfit    p_high_probit lgdp_per_capita_2021, ///
        lpattern(solid)    lwidth(medium)), ///
    title("Predicted Probability of High Outcome vs. Log GDP per Capita") ///
    subtitle("Country‐level, 2021") ///
    xtitle("Log GDP per Capita (US$)") ///
    ytitle("Predicted Probability (High)") ///
    xlabel(, grid) ylabel(, grid) ///
    legend(off) ///
    graphregion(color(white)) ///
    plotregion(margin(zero))
	
graph export "p_high_vs_gdp.png", width(1000) height(600) replace

	
	
*–––– [2] Medium–skill (against GDPpc)
twoway ///
    (scatter p_med_probit lgdp_per_capita_2021, ///
        mlabel(country_of_birth_25a) mlabposition(12) ///
        msymbol(circle_hollow) msize(medium)) ///
    (lfit    p_med_probit lgdp_per_capita_2021, ///
        lpattern(solid)    lwidth(medium)), ///
    title("Predicted Probability of Medium Outcome vs. Log GDP per Capita") ///
    subtitle("Country‐level, 2021") ///
    xtitle("Log GDP per Capita (US$)") ///
    ytitle("Predicted Probability (Medium)") ///
    xlabel(, grid) ylabel(, grid) ///
    legend(off) ///
    graphregion(color(white)) ///
    plotregion(margin(zero))
	
graph export "p_med_vs_gdp.png", width(1000) height(600) replace


*–––– [3] Low–skill (against GDPpc)
twoway ///
    (scatter p_low_probit lgdp_per_capita_2021, ///
        mlabel(country_of_birth_25a) mlabposition(12) ///
        msymbol(circle_hollow) msize(medium)) ///
    (lfit    p_low_probit lgdp_per_capita_2021, ///
        lpattern(solid)    lwidth(medium)), ///
    title("Predicted Probability of Low Outcome vs. Log GDP per Capita") ///
    subtitle("Country‐level, 2021") ///
    xtitle("Log GDP per Capita (US$)") ///
    ytitle("Predicted Probability (Low)") ///
    xlabel(, grid) ylabel(, grid) ///
    legend(off) ///
    graphregion(color(white)) ///
    plotregion(margin(zero))
	
graph export "p_low_vs_gdp.png", width(1000) height(600) replace

	
*–––– [4] High–skill (against migration distance)
twoway ///
    (scatter p_high_probit migration_distance, ///
        mlabel(country_of_birth_25a) mlabposition(12) ///
        msymbol(circle_hollow) msize(medium)) ///
    (lfit    p_high_probit migration_distance, ///
        lpattern(solid)    lwidth(medium)), ///
    title("Predicted Probability of High Outcome vs. Migration Distance") ///
    subtitle("Country‐level, 2021") ///
    xtitle("Migration Distance (km)") ///
    ytitle("Predicted Probability (High)") ///
    xlabel(, grid) ylabel(, grid) ///
    legend(off) ///
    graphregion(color(white)) ///
    plotregion(margin(zero))
	
	
graph export "p_high_vs_dist.png", width(1000) height(600) replace
	
	
*–––– [5] Medium–skill (against migration distance)
twoway ///
    (scatter p_med_probit migration_distance, ///
        mlabel(country_of_birth_25a) mlabposition(12) ///
        msymbol(circle_hollow) msize(medium)) ///
    (lfit    p_med_probit migration_distance, ///
        lpattern(solid)    lwidth(medium)), ///
    title("Predicted Probability of Med Outcome vs. Migration Distance") ///
    subtitle("Country‐level, 2021") ///
    xtitle("Migration Distance (km)") ///
    ytitle("Predicted Probability (Medium)") ///
    xlabel(, grid) ylabel(, grid) ///
    legend(off) ///
    graphregion(color(white)) ///
    plotregion(margin(zero))
	
	
graph export "p_med_vs_dist.png", width(1000) height(600) replace


*–––– [6] Low–skill (against migration distance)
twoway ///
    (scatter p_low_probit migration_distance, ///
        mlabel(country_of_birth_25a) mlabposition(12) ///
        msymbol(circle_hollow) msize(medium)) ///
    (lfit    p_low_probit migration_distance, ///
        lpattern(solid)    lwidth(medium)), ///
    title("Predicted Probability of Low Outcome vs. Migration Distance") ///
    subtitle("Country‐level, 2021") ///
    xtitle("Migration Distance (km)") ///
    ytitle("Predicted Probability (Low)") ///
    xlabel(, grid) ylabel(, grid) ///
    legend(off) ///
    graphregion(color(white)) ///
    plotregion(margin(zero))
	
	
graph export "p_low_vs_dist.png", width(1000) height(600) replace


//––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
// SECTION 3: Country effects – Multinomial Logit + second‐stage OLS
//––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

*–––– 3.0: Reload data & filter to male sample
use "${PROJROOT}/finaldataset.dta", clear  
keep if sex == 2  


*–––– 3.1: Estimate Multinomial Logit (High-Skill base)  
mlogit hrp_ns_sec_grouped                                           ///
       i.country_of_birth_25a                                       ///
	   i.region_num													///
       i.highest_qualification                                      ///
       c.resident_age_74m						                     ///
	   c.age_sq														///
       c.time_spent_in_uk,                                          ///
       baseoutcome(3) rrr  
outreg2 using multinomial.tex, replace ///
    ctitle("Multinomial Logit") label  

	
*–––– 3.2: Compute margins for each skill level  
estimates store mnl_base  

margins country_of_birth_25a, predict(outcome(1)) atmeans post  
estimates store mnl_high  
outreg2 using marginslogit.tex, replace ///
    ctitle("High-Skill Logit") ///
	    label bdec(3) se 

estimates restore mnl_base  
margins country_of_birth_25a, predict(outcome(2)) atmeans post  
estimates store mnl_med  
outreg2 using marginslogit.tex, append ///
    ctitle("Medium-Skill Logit") ///
	    label bdec(3) se 

estimates restore mnl_base  
margins country_of_birth_25a, predict(outcome(3)) atmeans post  
estimates store mnl_low  
outreg2 using marginslogit.tex, append ///
    ctitle("Low-Skill Logit") ///
	label bdec(3) se 

	
*–––– 3.3: Predict individual probabilities  
estimates restore mnl_base  
predict p_high_logit,   outcome(1)  
predict p_medium_logit, outcome(2)  
predict p_low_logit,    outcome(3)  


*–––– 3.4: Collapse to country‐level means for OLS  
local collapse_vars ///  
    p_high_logit p_medium_logit p_low_logit ///  
    lgdp_per_capita_2021 migration_distance home_english ///  

collapse (mean) `collapse_vars', by(country_of_birth_25a)  


*–––– 3.5: Set up regressor lists  
local basevars  lgdp_per_capita_2021 migration_distance
local homevars  `basevars' home_english


*–––– step 3.6: assigning labels to generated probabilities
label variable p_high_logit  "Mean predicted probability of high‐skill employment"
label variable p_medium_logit   "Mean predicted probability of medium‐skill employment"
label variable p_low_logit   "Mean predicted probability of low‐skill employment"

label variable migration_distance "Migration distance to UK, 2019 (1000 km)"
label variable home_english "Home Language English"
label variable lgdp_per_capita_2021 "Log GDP per capita, 2021 (US$)"


*–––– step 3.7: running second-stage OLS regressions for mean probabilities

*–– [1] OLS: High-Skill Logit Means (base model)  
regress p_high_logit `basevars', robust   
estat   ovtest  
estat   vif  
outreg2 using secondstagebase_logit.tex, replace ///
    ctitle("High-Base") ///
    label bdec(3) se  ///
    keep(`basevars')  

*–– [2] OLS: Medium-Skill Logit Means (base model)  
regress p_medium_logit `basevars', robust  
estat   ovtest  
estat   vif  
outreg2 using secondstagebase_logit.tex, append ///
    ctitle("Medium-Base") ///
    label bdec(3) se  ///
    keep(`basevars')  

*–– [3] OLS: Low-Skill Logit Means (base model)  
regress p_low_logit `basevars', robust  
estat   ovtest  
estat   vif  
outreg2 using secondstagebase_logit.tex, append ///
    ctitle("Low-Base") ///
    label bdec(3) se  ///
    keep(`basevars')  

*–– [4] OLS: High-Skill Logit Means (home english model)  
regress p_high_logit `homevars', robust  
estat   ovtest  
estat   vif  
outreg2 using secondstagehome_logit.tex, replace ///
    ctitle("High-Home") ///
    label bdec(3) se  ///
    keep(`homevars')  

*–– [5] OLS: Medium-Skill Logit Means (home english model)  
regress p_medium_logit `homevars', robust  
estat   ovtest  
estat   vif  
outreg2 using secondstagehome_logit.tex, append ///
    ctitle("Medium-Home") ///
    label bdec(3) se  ///
    keep(`homevars')  

*–– [6] OLS: Low-Skill Logit Means (home english model)  
regress p_low_logit `homevars', robust  
estat   ovtest  
estat   vif  
outreg2 using secondstagehome_logit.tex, append ///
    ctitle("Low-Home") ///
    label bdec(3) se  ///
    keep(`homevars')  

* clearly, home english does not fit very well given the low F-scores, relative to our base model so we are unable to draw significant inferences from the three variable regression. As seen in the probit as well, the model is simply stronger with just 2 regressors. 

//––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
// SECTION 4: Pre/Post-Brexit Skill Probabilities
//––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

* In this section, we attempt to construct the margins from the probit for both cohorts Pre and Post Brexit to analyse how the variable effects have changed.

*–––– 4.0 Reload & filter to male sample  
use "${PROJROOT}/finaldataset.dta", clear  
keep if sex==2  


*–––– 4.1 Treat UK-born as pre-Brexit cohort  
replace brexit_cohort = 0 if uk_born==1  


*–––– 4.2 Define ordered skill variable  
gen hrp_ns_sec_ordered = 4 - hrp_ns_sec_grouped  
label define skill_ord 1 "Low" 2 "Medium" 3 "High", replace  
label values hrp_ns_sec_ordered skill_ord  


*–––– 4.3: Estimate Pre-Brexit ordered probit (excl. UK-born in post only)  
oprobit hrp_ns_sec_ordered ///  
    i.country_of_birth_25a ///
	i.region_num			///
    i.highest_qualification ///  
    c.resident_age_74m ///  
	c.age_sq			///
    c.time_spent_in_uk if brexit_cohort==0  
estimates store pre  


*–––– 4.4: Estimate Post-Brexit ordered probit (include UK-born as baseline)  
oprobit hrp_ns_sec_ordered ///  
    i.country_of_birth_25a ///  
    i.highest_qualification /// 
	i.region_num			///
    c.resident_age_74m /// 
	c.age_sq			///
    c.time_spent_in_uk if brexit_cohort==1 | uk_born==1  
estimates store post  

*–––– 4.5: Estimating margins

estimates restore pre
margins country_of_birth_25a, predict(outcome(3)) atmeans post
outreg2 using prebrexit_margins.tex, replace ctitle("High-Skill Pre") label bdec(3) se

estimates restore pre
margins country_of_birth_25a, predict(outcome(2)) atmeans post
outreg2 using prebrexit_margins.tex, append ctitle("Medium-Skill Pre") label bdec(3) se

estimates restore pre
margins country_of_birth_25a, predict(outcome(1)) atmeans post
outreg2 using prebrexit_margins.tex, append ctitle("Low-Skill Pre") label bdec(3) se
 
estimates restore post
margins country_of_birth_25a, predict(outcome(3)) atmeans post
outreg2 using postbrexit_margins.tex, replace ctitle("High-Skill Post") label bdec(3) se

estimates restore post
margins country_of_birth_25a, predict(outcome(2)) atmeans post
outreg2 using postbrexit_margins.tex, append ctitle("Medium-Skill Post") label bdec(3) se

estimates restore post
margins country_of_birth_25a, predict(outcome(1)) atmeans post
outreg2 using postbrexit_margins.tex, append ctitle("Low-Skill Post") label bdec(3) se


//––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
// SECTION 5: Country effects – Ordered‐Probit for Women (no colonies)
//––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

*–– 5.0 Reload & filter to female sample  
use "${PROJROOT}/finaldataset.dta", clear  
keep if sex==1  

*–– 5.1 Define ordered skill variable  
gen hrp_ns_sec_ordered = 4 - hrp_ns_sec_grouped  
label define skill_order 1 "Low" 2 "Medium" 3 "High", replace  
label values hrp_ns_sec_ordered skill_order  

*–– 5.2 Estimate & store base ordered‐probit  
oprobit hrp_ns_sec_ordered ///  
    i.country_of_birth_25a ///  
    i.highest_qualification ///  
	i.region_num		///
    c.resident_age_74m ///  
	c.age_sq ///
    c.time_spent_in_uk  
estimates store base_w  

*–– 5.3 Compute margins and export for women  
estimates restore base_w  
margins country_of_birth_25a, predict(outcome(3)) atmeans post  
estimates store high_w  
outreg2 using margins_women.tex, replace ///
    ctitle("High‐Skill (women)") label    

estimates restore base_w  
margins country_of_birth_25a, predict(outcome(2)) atmeans post  
estimates store med_w  
outreg2 using margins_women.tex, append ///
    ctitle("Medium‐Skill (women)") label    

estimates restore base_w  
margins country_of_birth_25a, predict(outcome(1)) atmeans post  
estimates store low_w  
outreg2 using margins_women.tex, append ///
    ctitle("Low‐Skill (women)") label    

