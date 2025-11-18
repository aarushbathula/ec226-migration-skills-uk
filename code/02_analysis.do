*******************************************************
* 02_analysis.do – Models, margins, second-stage OLS
*******************************************************

version 18
clear all
set more off
set varabbrev off

* Assumes 01_data_build.do has already run
global PROJROOT "/path/to/ec226-migration-skills-uk"
global FINAL  "$PROJROOT/data/final"
global OUT    "$PROJROOT/output"
global TABLES "$OUT/tables"
global FIGS   "$OUT/figures"

* You need these user-written commands installed:
* ssc install estout, replace
* ssc install outreg2, replace

************************************************************************
* SECTION 1: Descriptive tables on finaldataset
************************************************************************

use "$FINAL/finaldataset.dta", clear

* 1.19 Profession distribution by birth origin ----------------------------
estpost tab hrp_ns_sec_grouped uk_born
esttab using "$TABLES/profession_distribution.tex", replace ///
    cells("b pct") ///
    nomtitle nonumber noobs ///
    title(Profession Distribution by Birth Origin) ///
    label

* 1.20 Education distribution by birth origin -----------------------------
gen highest_qualification_groups = ""
replace highest_qualification_groups = "N/A"              if highest_qualification == -8
replace highest_qualification_groups = "No qualifications" if highest_qualification == 0
replace highest_qualification_groups = "GCSE"             if inrange(highest_qualification,1,2)
replace highest_qualification_groups = "Apprenticeship"   if highest_qualification == 3
replace highest_qualification_groups = "A levels"         if highest_qualification == 4
replace highest_qualification_groups = "Bachelors or above" if highest_qualification == 5
replace highest_qualification_groups = "Others"           if highest_qualification == 6

estpost tab highest_qualification_groups uk_born
esttab using "$TABLES/education_distribution.tex", replace ///
    cells("b pct") ///
    nomtitle nonumber noobs ///
    title(Education Distribution by Birth Origin) ///
    label

* 1.21 Country of origin distribution -------------------------------------
estpost tab country_of_birth_25a
esttab using "$TABLES/country_distribution.tex", replace ///
    cells("b pct") ///
    nomtitle nonumber noobs ///
    title(Distribution of Country of Origin) ///
    label

* 1.22 Home English distribution ------------------------------------------
estpost tab home_english
esttab using "$TABLES/home_eng_distribution.tex", replace ///
    cells("b pct") ///
    nomtitle nonumber noobs ///
    title(Distribution of Home English) ///
    label

* 1.23 Region distribution -------------------------------------------------
estpost tab region_num
esttab using "$TABLES/region_distribution.tex", replace ///
    cells("b pct") ///
    nomtitle nonumber noobs ///
    title(Distribution of Region of Residence) ///
    label


************************************************************************
* SECTION 2: Country effects – Ordered probit + second-stage OLS
************************************************************************

* 2.0 Male-only sample ----------------------------------------------------
use "$FINAL/finaldataset.dta", clear
keep if sex == 2

* 2.1 Ordered skill variable ----------------------------------------------
gen hrp_ns_sec_ordered = 4 - hrp_ns_sec_grouped
label define skill_order 1 "Low" 2 "Medium" 3 "High", replace
label values hrp_ns_sec_ordered skill_order

* 2.2 Base ordered probit --------------------------------------------------
oprobit hrp_ns_sec_ordered ///
      i.country_of_birth_25a ///
      i.highest_qualification ///
      i.region_num ///
      c.resident_age_74m ///
      c.age_sq ///
      c.time_spent_in_uk
estimates store base

* 2.3–2.5 Margins for high/medium/low skill -------------------------------
estimates restore base
margins country_of_birth_25a, predict(outcome(3)) atmeans post
estimates store high
outreg2 using "$TABLES/margins_probit.tex", replace ///
    ctitle("High-Skill Probit") label bdec(3) se

estimates restore base
margins country_of_birth_25a, predict(outcome(2)) atmeans post
estimates store med
outreg2 using "$TABLES/margins_probit.tex", append ///
    ctitle("Medium-Skill Probit") label bdec(3) se

estimates restore base
margins country_of_birth_25a, predict(outcome(1)) atmeans post
estimates store low
outreg2 using "$TABLES/margins_probit.tex", append ///
    ctitle("Low-Skill Probit") label bdec(3) se

* 2.6–2.7 Predict probabilities and collapse to country means -------------
estimates restore base
predict p_low_probit,  outcome(1)
predict p_med_probit,  outcome(2)
predict p_high_probit, outcome(3)

collapse (mean) p_high_probit p_med_probit p_low_probit ///
                lgdp_per_capita_2021 migration_distance tert_exp_latest ///
                colonies_post_1945 home_english, ///
        by(country_of_birth_25a)

* 2.9 Labels for collapsed variables --------------------------------------
label variable p_high_probit "Mean predicted probability of high-skill employment"
label variable p_med_probit  "Mean predicted probability of medium-skill employment"
label variable p_low_probit  "Mean predicted probability of low-skill employment"

label variable migration_distance    "Migration distance to UK, 2019 (1000 km)"
label variable home_english          "Home Language English"
label variable lgdp_per_capita_2021  "Log GDP per capita, 2021 (US$)"

* 2.10–2.12 Second-stage OLS models ---------------------------------------
local basevars  lgdp_per_capita_2021 migration_distance
local tertvars  `basevars' tert_exp_latest
local colvars   `basevars' colonies_post_1945
local homevars  `basevars' home_english

* [1] High-skill (base)
regress p_high_probit `basevars', robust
linktest
estat ovtest
estat vif
outreg2 using "$TABLES/secondstagebase_probit.tex", replace ///
    ctitle("High-Base") label bdec(3) se keep(`basevars')

* [2] Medium-skill (base)
regress p_med_probit `basevars', robust
linktest
estat ovtest
estat vif
outreg2 using "$TABLES/secondstagebase_probit.tex", append ///
    ctitle("Medium-Base") label bdec(3) se keep(`basevars')

* [3] Low-skill (base)
regress p_low_probit `basevars', robust
linktest
estat ovtest
estat vif
outreg2 using "$TABLES/secondstagebase_probit.tex", append ///
    ctitle("Low-Base") label bdec(3) se keep(`basevars')

* [4–6] Tertiary models
regress p_high_probit `tertvars', robust
linktest
estat ovtest
estat vif
outreg2 using "$TABLES/secondstagetert_probit.tex", replace ///
    ctitle("High-Tertiary") label bdec(3) se keep(`tertvars')

regress p_med_probit `tertvars', robust
linktest
estat ovtest
estat vif
outreg2 using "$TABLES/secondstagetert_probit.tex", append ///
    ctitle("Medium-Tertiary") label bdec(3) se keep(`tertvars')

regress p_low_probit `tertvars', robust
linktest
estat ovtest
estat vif
outreg2 using "$TABLES/secondstagetert_probit.tex", append ///
    ctitle("Low-Tertiary") label bdec(3) se keep(`tertvars')

* [7–9] Colonial models
regress p_high_probit `colvars', robust
linktest
estat ovtest
estat vif
outreg2 using "$TABLES/secondstagecol_probit.tex", replace ///
    ctitle("High-Colonial") label bdec(3) se keep(`colvars')

regress p_med_probit `colvars', robust
linktest
estat ovtest
estat vif
outreg2 using "$TABLES/secondstagecol_probit.tex", append ///
    ctitle("Medium-Colonial") label bdec(3) se keep(`colvars')

regress p_low_probit `colvars', robust
linktest
estat ovtest
estat vif
outreg2 using "$TABLES/secondstagecol_probit.tex", append ///
    ctitle("Low-Colonial") label bdec(3) se keep(`colvars')

* [10–12] Home-language models
regress p_high_probit `homevars', robust
linktest
estat ovtest
estat vif
outreg2 using "$TABLES/secondstagehome_probit.tex", replace ///
    ctitle("High-Home") label bdec(3) se keep(`homevars')

regress p_med_probit `homevars', robust
linktest
estat ovtest
estat vif
outreg2 using "$TABLES/secondstagehome_probit.tex", append ///
    ctitle("Medium-Home") label bdec(3) se keep(`homevars')

regress p_low_probit `homevars', robust
linktest
estat ovtest
estat vif
outreg2 using "$TABLES/secondstagehome_probit.tex", append ///
    ctitle("Low-Home") label bdec(3) se keep(`homevars')

* 2.13 Scatter plots (probit probabilities vs GDP / distance) -------------
set scheme s1mono

label values country_of_birth_25a cob_short

* High vs log GDP
twoway ///
    (scatter p_high_probit lgdp_per_capita_2021, ///
        mlabel(country_of_birth_25a) mlabposition(12) ///
        msymbol(circle_hollow) msize(medium)) ///
    (lfit p_high_probit lgdp_per_capita_2021, ///
        lpattern(solid) lwidth(medium)), ///
    title("Predicted High-Skill vs Log GDP per Capita") ///
    subtitle("Country-level, 2021") ///
    xtitle("Log GDP per Capita (US$)") ///
    ytitle("Predicted Probability (High)") ///
    xlabel(, grid) ylabel(, grid) legend(off) ///
    graphregion(color(white)) plotregion(margin(zero))
graph export "$FIGS/p_high_vs_gdp.png", width(1000) height(600) replace

* Medium vs log GDP
twoway ///
    (scatter p_med_probit lgdp_per_capita_2021, ///
        mlabel(country_of_birth_25a) mlabposition(12) ///
        msymbol(circle_hollow) msize(medium)) ///
    (lfit p_med_probit lgdp_per_capita_2021, ///
        lpattern(solid) lwidth(medium)), ///
    title("Predicted Medium-Skill vs Log GDP per Capita") ///
    subtitle("Country-level, 2021") ///
    xtitle("Log GDP per Capita (US$)") ///
    ytitle("Predicted Probability (Medium)") ///
    xlabel(, grid) ylabel(, grid) legend(off) ///
    graphregion(color(white)) plotregion(margin(zero))
graph export "$FIGS/p_med_vs_gdp.png", width(1000) height(600) replace

* Low vs log GDP
twoway ///
    (scatter p_low_probit lgdp_per_capita_2021, ///
        mlabel(country_of_birth_25a) mlabposition(12) ///
        msymbol(circle_hollow) msize(medium)) ///
    (lfit p_low_probit lgdp_per_capita_2021, ///
        lpattern(solid) lwidth(medium)), ///
    title("Predicted Low-Skill vs Log GDP per Capita") ///
    subtitle("Country-level, 2021") ///
    xtitle("Log GDP per Capita (US$)") ///
    ytitle("Predicted Probability (Low)") ///
    xlabel(, grid) ylabel(, grid) legend(off) ///
    graphregion(color(white)) plotregion(margin(zero))
graph export "$FIGS/p_low_vs_gdp.png", width(1000) height(600) replace

* High vs distance
twoway ///
    (scatter p_high_probit migration_distance, ///
        mlabel(country_of_birth_25a) mlabposition(12) ///
        msymbol(circle_hollow) msize(medium)) ///
    (lfit p_high_probit migration_distance, ///
        lpattern(solid) lwidth(medium)), ///
    title("Predicted High-Skill vs Migration Distance") ///
    subtitle("Country-level, 2021") ///
    xtitle("Migration Distance (km)") ///
    ytitle("Predicted Probability (High)") ///
    xlabel(, grid) ylabel(, grid) legend(off) ///
    graphregion(color(white)) plotregion(margin(zero))
graph export "$FIGS/p_high_vs_dist.png", width(1000) height(600) replace

* Medium vs distance
twoway ///
    (scatter p_med_probit migration_distance, ///
        mlabel(country_of_birth_25a) mlabposition(12) ///
        msymbol(circle_hollow) msize(medium)) ///
    (lfit p_med_probit migration_distance, ///
        lpattern(solid) lwidth(medium)), ///
    title("Predicted Medium-Skill vs Migration Distance") ///
    subtitle("Country-level, 2021") ///
    xtitle("Migration Distance (km)") ///
    ytitle("Predicted Probability (Medium)") ///
    xlabel(, grid) ylabel(, grid) legend(off) ///
    graphregion(color(white)) plotregion(margin(zero))
graph export "$FIGS/p_med_vs_dist.png", width(1000) height(600) replace

* Low vs distance
twoway ///
    (scatter p_low_probit migration_distance, ///
        mlabel(country_of_birth_25a) mlabposition(12) ///
        msymbol(circle_hollow) msize(medium)) ///
    (lfit p_low_probit migration_distance, ///
        lpattern(solid) lwidth(medium)), ///
    title("Predicted Low-Skill vs Migration Distance") ///
    subtitle("Country-level, 2021") ///
    xtitle("Migration Distance (km)") ///
    ytitle("Predicted Probability (Low)") ///
    xlabel(, grid) ylabel(, grid) legend(off) ///
    graphregion(color(white)) plotregion(margin(zero))
graph export "$FIGS/p_low_vs_dist.png", width(1000) height(600) replace


************************************************************************
* SECTION 3: Multinomial logit + second-stage OLS (logit probabilities)
************************************************************************

use "$FINAL/finaldataset.dta", clear
keep if sex == 2

mlogit hrp_ns_sec_grouped ///
       i.country_of_birth_25a ///
       i.region_num ///
       i.highest_qualification ///
       c.resident_age_74m ///
       c.age_sq ///
       c.time_spent_in_uk, ///
       baseoutcome(3) rrr

outreg2 using "$TABLES/multinomial.tex", replace ///
    ctitle("Multinomial Logit") label

estimates store mnl_base

margins country_of_birth_25a, predict(outcome(1)) atmeans post
estimates store mnl_high
outreg2 using "$TABLES/margins_logit.tex", replace ///
    ctitle("High-Skill Logit") label bdec(3) se

estimates restore mnl_base
margins country_of_birth_25a, predict(outcome(2)) atmeans post
estimates store mnl_med
outreg2 using "$TABLES/margins_logit.tex", append ///
    ctitle("Medium-Skill Logit") label bdec(3) se

estimates restore mnl_base
margins country_of_birth_25a, predict(outcome(3)) atmeans post
estimates store mnl_low
outreg2 using "$TABLES/margins_logit.tex", append ///
    ctitle("Low-Skill Logit") label bdec(3) se

* Predict individual probabilities and collapse ---------------------------
estimates restore mnl_base
predict p_high_logit,   outcome(1)
predict p_medium_logit, outcome(2)
predict p_low_logit,    outcome(3)

local collapse_vars ///
    p_high_logit p_medium_logit p_low_logit ///
    lgdp_per_capita_2021 migration_distance home_english

collapse (mean) `collapse_vars', by(country_of_birth_25a)

local basevars  lgdp_per_capita_2021 migration_distance
local homevars  `basevars' home_english

label variable p_high_logit   "Mean predicted probability of high-skill employment"
label variable p_medium_logit "Mean predicted probability of medium-skill employment"
label variable p_low_logit    "Mean predicted probability of low-skill employment"

* Second-stage OLS (logit) ------------------------------------------------
regress p_high_logit `basevars', robust
estat ovtest
estat vif
outreg2 using "$TABLES/secondstagebase_logit.tex", replace ///
    ctitle("High-Base") label bdec(3) se keep(`basevars')

regress p_medium_logit `basevars', robust
estat ovtest
estat vif
outreg2 using "$TABLES/secondstagebase_logit.tex", append ///
    ctitle("Medium-Base") label bdec(3) se keep(`basevars')

regress p_low_logit `basevars', robust
estat ovtest
estat vif
outreg2 using "$TABLES/secondstagebase_logit.tex", append ///
    ctitle("Low-Base") label bdec(3) se keep(`basevars')

regress p_high_logit `homevars', robust
estat ovtest
estat vif
outreg2 using "$TABLES/secondstagehome_logit.tex", replace ///
    ctitle("High-Home") label bdec(3) se keep(`homevars')

regress p_medium_logit `homevars', robust
estat ovtest
estat vif
outreg2 using "$TABLES/secondstagehome_logit.tex", append ///
    ctitle("Medium-Home") label bdec(3) se keep(`homevars')

regress p_low_logit `homevars', robust
estat ovtest
estat vif
outreg2 using "$TABLES/secondstagehome_logit.tex", append ///
    ctitle("Low-Home") label bdec(3) se keep(`homevars')


************************************************************************
* SECTION 4: Pre/Post-Brexit ordered probit margins
************************************************************************

use "$FINAL/finaldataset.dta", clear
keep if sex == 2

replace brexit_cohort = 0 if uk_born == 1

gen hrp_ns_sec_ordered = 4 - hrp_ns_sec_grouped
label define skill_ord 1 "Low" 2 "Medium" 3 "High", replace
label values hrp_ns_sec_ordered skill_ord

* Pre-Brexit
oprobit hrp_ns_sec_ordered ///
    i.country_of_birth_25a ///
    i.region_num ///
    i.highest_qualification ///
    c.resident_age_74m ///
    c.age_sq ///
    c.time_spent_in_uk if brexit_cohort == 0
estimates store pre

* Post-Brexit
oprobit hrp_ns_sec_ordered ///
    i.country_of_birth_25a ///
    i.highest_qualification ///
    i.region_num ///
    c.resident_age_74m ///
    c.age_sq ///
    c.time_spent_in_uk if brexit_cohort == 1 | uk_born == 1
estimates store post

* Pre margins
estimates restore pre
margins country_of_birth_25a, predict(outcome(3)) atmeans post
outreg2 using "$TABLES/prebrexit_margins.tex", replace ///
    ctitle("High-Skill Pre") label bdec(3) se

estimates restore pre
margins country_of_birth_25a, predict(outcome(2)) atmeans post
outreg2 using "$TABLES/prebrexit_margins.tex", append ///
    ctitle("Medium-Skill Pre") label bdec(3) se

estimates restore pre
margins country_of_birth_25a, predict(outcome(1)) atmeans post
outreg2 using "$TABLES/prebrexit_margins.tex", append ///
    ctitle("Low-Skill Pre") label bdec(3) se

* Post margins
estimates restore post
margins country_of_birth_25a, predict(outcome(3)) atmeans post
outreg2 using "$TABLES/postbrexit_margins.tex", replace ///
    ctitle("High-Skill Post") label bdec(3) se

estimates restore post
margins country_of_birth_25a, predict(outcome(2)) atmeans post
outreg2 using "$TABLES/postbrexit_margins.tex", append ///
    ctitle("Medium-Skill Post") label bdec(3) se

estimates restore post
margins country_of_birth_25a, predict(outcome(1)) atmeans post
outreg2 using "$TABLES/postbrexit_margins.tex", append ///
    ctitle("Low-Skill Post") label bdec(3) se


************************************************************************
* SECTION 5: Ordered probit for women
************************************************************************

use "$FINAL/finaldataset.dta", clear
keep if sex == 1

gen hrp_ns_sec_ordered = 4 - hrp_ns_sec_grouped
label define skill_order 1 "Low" 2 "Medium" 3 "High", replace
label values hrp_ns_sec_ordered skill_order

oprobit hrp_ns_sec_ordered ///
    i.country_of_birth_25a ///
    i.highest_qualification ///
    i.region_num ///
    c.resident_age_74m ///
    c.age_sq ///
    c.time_spent_in_uk
estimates store base_w

estimates restore base_w
margins country_of_birth_25a, predict(outcome(3)) atmeans post
outreg2 using "$TABLES/margins_women.tex", replace ///
    ctitle("High-Skill (women)") label bdec(3) se

estimates restore base_w
margins country_of_birth_25a, predict(outcome(2)) atmeans post
outreg2 using "$TABLES/margins_women.tex", append ///
    ctitle("Medium-Skill (women)") label bdec(3) se

estimates restore base_w
margins country_of_birth_25a, predict(outcome(1)) atmeans post
outreg2 using "$TABLES/margins_women.tex", append ///
    ctitle("Low-Skill (women)") label bdec(3) se

*******************************************************
* End 02_analysis.do
*******************************************************
