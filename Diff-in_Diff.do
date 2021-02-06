*Katelin Hudak
*Difference-in-Differences example code
*Stata 16.1

use "SNAP_health.dta"

**************EXPLORE DATA AND CREATE SUMMARY STATISTICS TABLES
***Pre-ARRA 
table1_mc if wtmec6yr != . & arra == 0, by(snap) vars (age contn  %4.1f \ hhsiz contn  %4.1f \ pir contn  %4.1f \sex cat %4.1f \ race cat %4.1f \ hreduc cat %4.1f  \ hrmar bin %4.1f \  fsdch cat %4.1f \wic cat %4.1f \nslp cat %4.1f \sbp cat %4.1f \hei2010 contn  %4.1f \bmipct contn  %4.1f \ovwt bin  %4.1f \ obse bin  %4.1f) percent_n onecol saving ("table1A_pre_arra.xlsx")

***During ARRA
table1_mc if wtmec6yr != . & arra == 1, by(snap) vars (age contn  %4.1f \ hhsiz contn  %4.1f \ pir contn  %4.1f \sex cat %4.1f \ race cat %4.1f \ hreduc cat %4.1f  \ hrmar bin %4.1f \  fsdch cat %4.1f \wic cat %4.1f \nslp cat %4.1f \sbp cat %4.1f \hei2010 contn  %4.1f \bmipct contn  %4.1f \ovwt bin  %4.1f \ obse bin  %4.1f) percent_n onecol saving  ("table1B_arra.xlsx")

*Columns A - D are the columns of interest. (Please note that these tables do not present the weighted statistics.)
*From Table 1A, we see that there are several significant differences between SNAP eligible youth and nearly SNAP eligible youth prior to ARRA. 
*However, it is not the difference in mean values that matters for a difference-in-differences design, rather, it is the TREND in outcomes that matters. If diet and body weight outcomes would change differentially in SNAP-eligible and nearly SNAP-eligible youth, even in the absence of the ARRA, then model estimates will be biased because they capture these unrelated differences. I visually test this assumption of parallel trends by examining youth diet and weight outcomes across ages using NHANES data from five waves prior to the ARRA: 1999-2000 through 2007-2008, through the end of ARRA in 2013-2014.

**************CREATING PARALELL TRENDS GRAPHS
*A) CREATE NECESSARY VARIABLES: Generate new variable that is the mean outcome for a specific age group in a given year

*1) Generate grouping variable
egen s_age = group(wyear snap agegrp)
*64 unique values

*Because ARRA began in April 2009, including January through March 2009 would weaken the design. NHANES has a variable to identify the six-month period in which the exam took place. I use this variable to exclude observations from November 1 to April 30.

*2) Recode s_age ==. if occurred during the time when we are not sure whether or not it was post ARRA (wyear==6{2009-2010} & mnths==1 {Nov 1-April 30})
replace s_age =. if wyear == 6 & mnths == 1
*Check
sort wyear snap agegrp s_age mnths
browse wyear snap agegrp s_age mnths

*3) Create new variable that is blank
foreach var of varlist (hei2010 bmipct ovwt obse) {
	gen `var'_s_age =.
}
*

*4) Diet outcome: Do loop and incorporate a 1) replace and 2) drop command
set more off

forvalues i = 1/64{
	foreach var of varlist (hei2010){
	egen m_`var'_s_age = wtmean(`var') if s_age == `i', weight(wtdrd1)
	replace `var'_s_age = m_`var'_s_age if s_age == `i'
	drop m_`var'_s_age
}
}
*
*Check
browse wyear snap agegrp s_age hei2010_s_age

*5) Weight outcomes: Do loop and incorporate a 1) replace and 2) drop command
set more off
forvalues i = 1/64{
	foreach var of varlist (bmipct ovwt obse){
	egen m_`var'_s_age = wtmean(`var') if s_age == `i', weight(wtmec2yr)
	replace `var'_s_age = m_`var'_s_age if s_age == `i'
	drop m_`var'_s_age
}
}
*
*Check
browse wyear snap agegrp s_age bmipct_s_age

*5) Label variables 
labvars hei2010_s_age bmipct_s_age ovwt_s_age obse_s_age  "HEI-2010" "BMI-for-age Percentile" "Probability of Overweight" "Probability of Obesity" 
 
*B) CREATE PARALLEL TREND GRAPHS ACROSS 4 AGE GROUPS

*1: ages 2-3 (Toddlers)
*2: ages 4-5 (Preschool)
*3: ages 6-11 (Children)
*4: ages 12-18 (Adolescents)

local varlist "hei2010_s_age bmipct_s_age ovwt_s_age obse_s_age"

forvalues i = 1/4 {
	local var1 = word("`varlist'", `i')
	forvalues j = 1/4 {
	twoway (connected `var1' wyear if snap == 1 & agegrp == `j', sort lcolor(blue)) (connected `var1' wyear if snap == 0 & agegrp == `j', sort lcolor(gray)lpattern(dash)), xline(5.5, lcolor(black)) graphregion(color(white)) title(`: variable label `var1'': Ages `j') ytitle(`: variable label `var1'') xtitle(Year) xlabel(#8, angle(45))xlabel(, labels valuelabel) legend(label(1 "SNAP-Eligible") label(2 "Higher Income")) saving (`var1'_`j')
}
}
*

*C) COMBINE GRAPHS
#delimit ; 
graph combine "C:\Users\khudak\Dropbox\NHANES\hei2010_s_age_1.gph"
	"C:\Users\khudak\Dropbox\NHANES\hei2010_s_age_2.gph"
	"C:\Users\khudak\Dropbox\NHANES\hei2010_s_age_3.gph"
	"C:\Users\khudak\Dropbox\NHANES\hei2010_s_age_4.gph", graphregion(color(white)) iscale(*.7);
	
#delimit ;
graph combine "C:\Users\khudak\Dropbox\NHANES\bmipct_s_age_1.gph"
	"C:\Users\khudak\Dropbox\NHANES\ovwt_s_age_1.gph"
	"C:\Users\khudak\Dropbox\NHANES\obse_s_age_1.gph"
	"C:\Users\khudak\Dropbox\NHANES\bmipct_s_age_2.gph"
	"C:\Users\khudak\Dropbox\NHANES\ovwt_s_age_2.gph"
	"C:\Users\khudak\Dropbox\NHANES\obse_s_age_2.gph", graphregion(color(white)) iscale(*.7);

#delimit ;
graph combine "C:\Users\khudak\Dropbox\NHANES\bmipct_s_age_3.gph"
	"C:\Users\khudak\Dropbox\NHANES\ovwt_s_age_3.gph"
	"C:\Users\khudak\Dropbox\NHANES\obse_s_age_3.gph"
	"C:\Users\khudak\Dropbox\NHANES\bmipct_s_age_4.gph"
	"C:\Users\khudak\Dropbox\NHANES\ovwt_s_age_4.gph"
	"C:\Users\khudak\Dropbox\NHANES\obse_s_age_4.gph", graphregion(color(white)) iscale(*.7);
	
*The figures indicate that the pre-trends for the outcomes of interest show similar broad trends prior to the ARRA, but the means fluctuate enough from wave to wave that they do not smoothly follow one another. 
*I further explore the parallel trends assumption in a regression framework. 

**************TESTING PARALLEL TRENDS 

*yi = α0 + α1SNAPi + α2WAVEi + α3(SNAPi *WAVEi) + ui

*where:
*yi = child diet or weight outcome
*SNAPi = 1 if the child is in the SNAP-eligible group
*WAVEi = vector of categorical variables for each survey wave prior to the ARRA (1999-2000 through 2007-2008)
*SNAPi *WAVEi = vector of interactions between each wave's categorical variable and SNAP
*ui = error term   

*If the parallel trend assumption holds, a joint test of significance should show that the vector of coefficients for each outcome is not significant

*Pre-ARRA years: use 10 year weight for years 1999-2000 through 2007-2008

svyset sdmvpsu [pw = wtdrd10yr_pt], strata(sdmvstra) singleunit(centered)

forval j=1/4{
	svy, subpop(if agegrp==`j'): reg hei2010 snap i.wyear i.snap#i.wyear
	testparm i.snap#i.wyear
}
*
*Results of the Wald test indicate that the parallel trends assumption may not be met for HEI-2010 in children 6 - 11 years (age group 3) (p = 0.0513) and is not met for adolescents 12 -1 18 years (age group 4) ( p < 0.05).

svyset sdmvpsu [pw = wtmec10yr_pt], strata(sdmvstra) singleunit(centered)

local varlist "bmipct ovwt obse"

*By age group
forvalues i=1/3 {
	local var1=word("`varlist'", `i')
	forval j=1/4{
	svy, subpop(if agegrp==`j'): reg `var1' snap i.wyear i.snap#i.wyear
	testparm i.snap#i.wyear
}
}
*
*Results of the Wald test indicate that the parallel trends assumption is met for weight outcomes in all age groups (p > 0.05).

**************PERFORMING MAIN REGRESSION ANALYSIS AND CREATING TABLE OF RESULTS
* Using a difference-in-differences framework and examining the connection between the ARRA increase in SNAP benefits and child weight

*yi = α0 + α1SNAPi + α2ARRAi + α3(SNAPi *ARRAi) + α4Xi +ui

*where:
*yi = diet or weight outcome of interest
*SNAPi = 1 if in the treatment group
*ARRAi = 1 if in the post-ARRA period
*SNAPi * ARRAi = interaction term between them
*Xi = vector of control variables
*ui = error term

*α3 gives the difference-in-differences estimate of SNAP

*1) Declare survey design for analysis
svyset sdmvpsu [pw = wtmec6yr], strata(sdmvstra) singleunit(centered)

*2) Build regression models and format a table of results 
*It is important to use the dietary weight variable when analyzing HEI. To simplify the regression analyses and code, I show weight outcomes here only.

set more off

local varlist "bmipct ovwt obse"

****Unconditional (1)
forvalues i = 1/3 {
local var1 = word("`varlist'", `i')
	forvalues j = 1/4 {
	svy, subpop(if agegrp == `j'): reg `var1' snap arra arsnap
	outreg2 using `var1'_build`j'.doc, title(`: variable label `var1'': `j') dec (2)
	sleep 500
}
}
*
****Individual level controls (2)
forvalues i = 1/3 {
local var1 = word("`varlist'", `i')
	forvalues j = 1/4 {
	svy, subpop(if agegrp == `j'): reg `var1' snap arra arsnap age age2 i.sex i.race 
	outreg2 using `var1'_build`j'.doc, e(N_sub, wvar) title(`: variable label `var1'': `j') dec (2)
	sleep 500
}
}
*
****Household level controls (3)
forvalues i = 1/3 {
local var1 = word("`varlist'", `i')
	forvalues j = 1/4 {
	svy, subpop(if agegrp == `j'): reg `var1' snap arra arsnap age age2 i.sex i.race i.hreduc i.hrmar hhsiz pir 
	outreg2 using `var1'_build`j'.doc, e(N_sub, wvar) title(`: variable label `var1'': `j') dec (2)
	sleep 500
}
}
*
***Food security (4)
forvalues i = 1/3 {
local var1 = word("`varlist'", `i')
	forvalues j = 1/4 {
	svy, subpop(if agegrp == `j'): reg `var1' snap arra arsnap age age2 i.sex i.race i.hreduc i.hrmar hhsiz pir i.fsdch
	outreg2 using `var1'_build`j'.doc, e(N_sub, wvar) title(`: variable label `var1'': `j') dec (2)
	sleep 500
}
}
*

***Fully adjusted model, adding in participation in other programs (WIC, NSLP and SBP) (5)
forvalues i = 1/3 {
local var1 = word("`varlist'", `i')
	forvalues j = 1/4 {
	svy, subpop(if agegrp == `j'): reg `var1' snap arra arsnap age age2 i.sex i.race i.hreduc i.hrmar hhsiz pir i.fsdch i.wic i.nslp i.sbp
	outreg2 using `var1'_build`j'.doc, e(N_sub, wvar) title(`: variable label `var1'': `j') dec (2)
	sleep 500
}
}
*
**************Better look at final models
*Remember:
*1: ages 2-3 (Toddlers)
*2: ages 4-5 (Preschool)
*3: ages 6-11 (Children)
*4: ages 12-18 (Adolescents)

local varlist "bmipct ovwt obse"

***Fully adjusted model, adding in participation in other programs (WIC, NSLP and SBP) (5)
forvalues i = 1/3 {
local var1 = word("`varlist'", `i')
	forvalues j = 1/4 {
	svy, subpop(if agegrp == `j'): reg `var1' snap arra arsnap age age2 i.sex i.race i.hreduc i.hrmar hhsiz pir i.fsdch i.wic i.nslp i.sbp
	outreg2 using final`j'.doc, e(N_sub, wvar) title (Child weight: `j') ctitle(`: variable label `var1'') dec (2)	
	sleep 500
}
}
*
*Results indicate that the ARRA increase in SNAP benefits is associated with a marginally lower BMI percentile (b = - 12.07, p = 0.095) and a lower probability of being overweight (b = -0.21, p < 0.05) in toddlers ages 2 -3 years. The increase in benefits is also associated with a lower probabilty of being obese in adolescents (b = 0.13, p < 0.05).

svyset sdmvpsu [pw = wtdrd6yr], strata(sdmvstra) singleunit(centered)

**********HEI 2010
***Fully adjusted model, adding in participation in other programs (WIC, NSLP and SBP) (5)
forvalues j = 1/4 {
	svy, subpop(if agegrp == `j'): reg hei2010 snap arra arsnap age i.sex i.race i.weekend i.hreduc i.hrmar hhsiz pir i.fsdch i.wic i.nslp i.sbp
	outreg2 using final_hei.doc, ctitle (`j') title(HEI - 2010) dec (2)	
	sleep 500
}
*
*Results indicate that the ARRA increase in SNAP benefits is associated with a lower HEI - 2010 score (b= - 5.41, p < 0.05). However, because the parallel trends assumption may not be met for this age group, we must view this estimate cautiously.

*For the full set of results, including multiple sensitivity checks (e.g., logistic regression for binary variables, use of alternate comparison groups, results when excluding WIC-participating children), as well as a discussion of findings and limitations, please see "Do additional SNAP benefits matter for child weight?: Evidence from the 2009 benefit increase" in Economics and Human Biology (2021) 41: 100966. 

*For results of analyses focuing on dietary outcomes, including HEI - 2010, please see "An Increase in SNAP Benefits Did Not Impact Food Security or Diet Quality in Youth" in the Journal of the Academy of Nutrition and Dietetics (2020).