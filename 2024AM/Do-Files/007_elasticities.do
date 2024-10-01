*!v2.0 iosoriorodarte@worldbank
/*========================================================================
Project:			Macro-micro Simulations
Institution:		World Bank 

Author:				Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Creation Date:		02/25/2022

Last Modification:	Israel Osorio Rodarte (iosoriorodarte@worldbank.org)
Modification date: 	08/29/2024
========================================================================*/

drop _all
local interpolations ""

etime, start
**************************************************************************
* 	0 - SETTING
**************************************************************************

foreach ns in 3 6 {


* Set up postfile for results
clear
frame reset
tempname regressions
tempfile aux
postfile `regressions' str3(country) str10(period) str11(year) str20(model) str80(elasticity) value using `aux', replace

*************************************************************************
* 	1 - DATA FILE AND VARIABLES
*************************************************************************

* Append micro sources
	use "$data_in/Macro and elasticities/input_elasticities_hies.dta", clear
	gen source = "HIES"
	append using "$data_in/Macro and elasticities/input_elasticities_lfs.dta"
	replace source = "LFS" if source == ""
	
* Remove duplicates
	*duplicates tag country year indicator, gen(duplicates)
	*drop if duplicates == 1 & source == "LFS"
	*duplicates report country year indicator
	*drop duplicates source

* Drop unused variables
	drop title date

* Drop unused indicators
	#delimit ;
	gen byte delete = .;
	foreach ind in 
		mfpop_totl 		mfgdppckn 
		hspop_0014 		hspop_15up 		hspop_65up hspop_total
		lfpop_0014 		lfpop_15up 		lfpop_65up lfpop_total
		lflstatus2_15up lflstatus3_15up 
		hslstatus2_15up hslstatus3_15up {;
		
		replace delete = 1 if indicator=="`ind'";
	
	};
	drop if delete==1;
	drop delete;
	#delimit cr
	
* Fix macro names, from text to A codes
	replace nsectors = 100 		  if indicator=="mfnygdpmktpkn"
	replace indicator = "mfnv_A0" if indicator=="mfnygdpmktpkn"	// Whole Economy

	* Order of mnemonics is important and determined in macro model
	if `ns'==6 {
	local i = 1
	foreach mnemonic in agrtotl indcons	indrest srvtrns	srvfina srvrest	{
		replace nsectors  = `ns'		if indicator=="mfnv`mnemonic'kn"
		replace indicator = "mfnv_a`i'" if indicator=="mfnv`mnemonic'kn"
		local i = `i'+1
	}
	}
	
	* Order of mnemonics is important and determined in macro model
	if `ns'==3 {
	local i = 1
	foreach mnemonic in agrtotl indtotl	srvtotl	{
		replace nsectors  = `ns' 			if indicator=="mfnv`mnemonic'kn"
		replace indicator = "mfnv_a`i'" if indicator=="mfnv`mnemonic'kn"
		local i = `i'+1
	}
	}
	
	* Keep aggregation
	keep if nsectors==`ns'|nsectors==100
	drop nsectors
	
	* Whole economy lstatus and lstatus12
	replace indicator = "hslstatus1_A0"  if indicator=="hslstatus1_15up"
	replace indicator = "hslstatus12_A0" if indicator=="hslstatus12_15up" 
	replace indicator = "lflstatus1_A0"  if indicator=="lflstatus1_15up"
	replace indicator = "lflstatus12_A0" if indicator=="lflstatus12_15up"
	
	* Whole economy, total income ip
	replace indicator = "lfip_A0" 		 if indicator=="lfip_total"
	replace indicator = "hsip_A0" 		 if indicator=="hsip_total"

* Fix indicator name
	gen A = substr(indicator,length(indicator)-1,2)
	replace indicator = substr(indicator,1,length(indicator)-3)
	
	gen m = substr(indicator,1,2)
	replace indicator = substr(indicator,3,length(indicator))
	
	gen S = substr(indicator,length(indicator)-2,3)
		replace S = "_S0" if S!="_s0" & S!="_s1"
		replace S = substr(S,2,2)
	replace indicator = substr(indicator,1,length(indicator)-3) if S=="s0"|S=="s1"
	

* Reorder of variables for calculating elasticities
* Macro data, as variable
	preserve
		keep if m=="mf"
		drop m
		rename value valuemfnv
		drop indicator
		drop S
		duplicates tag country year A value, gen(tag)
		drop if tag == 1 & source == "LFS"
		drop tag source
		isid country year A
		tempfile mfnv
		save `mfnv', replace
	restore

* Whole economy GDP, as variable
	preserve
		keep if m=="mf" & A=="A0" & S=="S0"
		keep country year value
		rename value valuegdp
		duplicates drop
		isid country year
		tempfile gdp
		save `gdp'
	restore
	
* Simple Linear Interpolation
* This method would allow us to quickly fill the gaps and check the consistency
* of the code. We should evaluate under which circumstances should be used.
if "`interpolations'"=="yes" {
	
	reshape wide value, i(country indicator A m S) j(year)
	reshape long value, i(country indicator A m S) j(year)

	drop if m=="mf"
	
	merge m:1 country year A using `mfnv'
	drop _merge
	
	levelsof country, local(allcountries)
	levelsof m, local(allsources) 
	levelsof A, local(allA)
	levelsof S, local(allS)	
	levelsof i, local(allIs)
	
	foreach country of local allcountries {
	foreach sr of local allsources  {
	foreach a of local allA {
	foreach s of local allS {
	foreach i of local allIs {	

		
		bys country m indicator A S: egen _minyear  = min(year) if value!=.
		bys country m indicator A S: egen _lastyear = max(year) if value!=.
		
		bys country m indicator A S: egen minyear  = mean(_minyear)
		bys country m indicator A S: egen lastyear = mean(_lastyear)
				
		bys country m indicator A S: ipolate value valuemfnv, gen(__value)
			replace value = __value if value==. & __value!=. & year>=minyear & year<=lastyear
			drop __value
			
			drop _minyear _lastyear minyear lastyear

	}
	}
	}
	}
	}
	
	drop valuemfnv
	drop if value==.

}			
	sort m country indicator A S year
	drop if m=="mf"
	
* Calculate total number of workers by sector
	preserve
		collapse (sum) value if indicator=="lstatus1" & (S!="S0") & (A!="A0"), by(country year indicator m S)
		gen A = "A0"
		tempfile workersbysector
		save `workersbysector', replace
	restore
	
* Calculate, total number of workers by skill level
	preserve
		collapse (sum) value if indicator=="lstatus1" & (S!="S0") & (A!="A0"), by(country year indicator m A)
		gen S = "S0"
		tempfile workersbyskill
		save `workersbyskill', replace
	restore

* Append workers by sector and skill
	append using `workersbysector'
	append using `workersbyskill'
			
* Calculate productivities and append as indicator
	preserve
		* First keep lstatus1, keep a and s items, and merge macro as variable
		keep if indicator=="lstatus1"
		drop if A=="A0" | S=="S0"
		isid country year A m S
		merge m:1 country year A using `mfnv'
		
		keep if _merge==3
		drop _merge
		
		gen double _valueprod = value/valuemfnv
		drop value valuemfnv
		rename _valueprod value
		replace indicator = "prod"
		tempfile productivity
		save `productivity', replace
	restore
		
	append using `productivity'
	
	order m country indicator A S year
	sort  m country indicator A S year

* Calculate unskilled rate in the whole economy, as variable
	preserve
		* All Unskilled Workers
		collapse (sum) value if indicator=="lstatus1" & A!="A0" & S=="s0", by(m country year indicator S)
		rename value valuelstatus1_A0_s0
		drop S
		tempfile S0
		save `S0'
	restore

	preserve
		* All Workers
		collapse (sum) value if indicator=="lstatus1" & A!="A0" , by(m country year indicator)
		rename value valuelstatus1_A0_S0
		
		* Merge with Unskilled Workers
		merge 1:1 country year indicator m using `S0'
		drop _merge
		gen double valuerate_A0_s0 = valuelstatus1_A0_s0 / valuelstatus1_A0_S0
		drop valuelstatus1*
		drop indicator
		sort m country year
		
		tempfile S0rate
		save `S0rate'
	restore
	
	merge m:1 m country year using `S0rate'
	drop _merge
		
* Add macro data, as variable
		merge m:1 country year A using `mfnv'
		keep if _merge==3
		drop _merge

		merge m:1 country year using `gdp'
		keep if _merge==3
		drop _merge	
		
* XTSET	Database
	order m country indicator A S year
	sort  m country indicator A S year
	isid m country indicator A S year
	egen id = group(m country indicator A S)
	sort id year
	by id: gen t = _n
	xtset id t
	order id t
	
* Creating natural logs for some variables
	foreach var of varlist value valuemfnv valuegdp {
		gen double ln`var' = ln(`var')
	}

* Calculate growth rates
	foreach var of varlist value valuemfnv {
		gen gr`var' = 100*(`var'/ l1.`var' - 1) 
	}

* Calculate growth-on-growth elasticities
	gen double valueelas = grvalue/grvaluemfnv
	
* Calcualte iteration variables log_gdp * unskilled rate
	gen double iteration = valuerate_A0_s0 * valuemfnv 
	
	
* Save file
	save "$data_in/preelasticities`ns'.dta", replace
	tempfile preelasticities
	save `preelasticities', replace
	
	
*************************************************************************
* 	2 - ELASTICITIES
*************************************************************************

* Read file
	use `preelasticities', clear
	frame put _all, into(baseelast)
	
* Create all locals	
	levelsof country, local(allcountries)
	levelsof m, local(allsources) 
	levelsof A, local(allA)
	levelsof S, local(allS)
	
* Loop for computing a) average growth-on-growth elasticities
* and b) regression-based elasticities
* Period p were defined in a global macro in elasticiy master do-file
forvalues p = 1/3 {
foreach country of local allcountries {
foreach sr of local allsources  {
foreach a of local allA {
foreach s of local allS {
foreach i in lstatus1 lstatus12 prod {	

	* If no period has been defined, then exit the loop
	cap local min`p' = ${`sr'min_year`p'}
	if _rc continue
	
	local last   = ${`sr'last_year}
	
	* Use only the observations needed
	frame change baseelast
	cap frame drop workelast
	
	*noi di `" use if year>=`min`p'' & year<=`last' & country=="`country'" & m=="`sr'" & A=="`a'" & S=="`s'" & indicator=="`i'" using `preelasticities', clear "'
	*		  use if year>=`min`p'' & year<=`last' & country=="`country'" & m=="`sr'" & A=="`a'" & S=="`s'" & indicator=="`i'" using `preelasticities', clear 
	
	noi di ""
	noi di `" frame put _all if year>=`min`p'' & year<=`last' & country=="`country'" & m=="`sr'" & A=="`a'" & S=="`s'" & indicator=="`i'", into(workelast) "'
	frame put _all if year>=`min`p'' & year<=`last' & country=="`country'" & m=="`sr'" & A=="`a'" & S=="`s'" & indicator=="`i'", into(workelast)
	frame change workelast
	
	* If database is empty, then go to next iteration
	qui count
	if r(N)==0 continue
	
*********************************************************************
* 2.1 - Indicators
*********************************************************************

	noi di as text " - country: `country'. Source: `sr'. Period: `min`p'' - `last'. A: `a'. S: `s'. I:`i'"

	if "`i'"=="lstatus1"  local suffix "ls1"
	if "`i'"=="lstatus12" local suffix "ls12"
	if "`i'"=="prod" 	  local suffix "prod"

*********************************************************************
* 2.1.1 - Simple averages
*********************************************************************	

* GDP-Activity and Sectoral GDP-Sectoral Workers 
*************************************************
* Sectoral Productivity-Sectoral Income 
*************************************************
		
	*noi di as text " - Simple averages"
	
	qui sum valueelas 
	if r(N)>0 {
		*noi di "valueelas simple average processed"
		noi di ""
		loc avg_`sr'elas_`suffix'_`s'_`a' = r(mean)
		post `regressions' ("`country'") ("_period`p'") ("`min`p'' - `last'") ("avg") ("`sr'`suffix'_`s'_`a'") (`avg_`sr'elas_`suffix'_`s'_`a'')
	}
	
*********************************************************************
* 2.1.2 - Averages without outliers (1%-99%)
*********************************************************************
*********************************************************************
* 2.1.3 - Averages with imputed outliers (1%-99% using median)
*********************************************************************

	* Outliers
	qui clonevar valueelas_1_99 = valueelas
	qui sum      valueelas, d
	qui replace  valueelas_1_99 = . if (valueelas_1_99 <= r(p1) | valueelas_1_99 >= r(p99))
	
	qui clonevar valueelas_1_99_imp = valueelas_1_99
	qui replace  valueelas_1_99_imp = r(p50) 		if (valueelas_1_99 <= r(p1) | valueelas_1_99 >= r(p99))
	

	* GDP-Activity
	*****************
	* Sectoral GDP-Sectoral Workers 
	**********************************
	* Sectoral Productivity-Sectoral Income 
	******************************************

	foreach tt in _1_99 _1_99_imp {
	
		qui sum valueelas`tt'
		if r(N)>0 {
			* noi di "valueelas`tt' average processed"
			noi di ""
			loc avg_`sr'elas_`suffix'_`s'_`a'`tt' = r(mean)
			post `regressions' ("`country'") ("_period`p'") ("`min`p'' - `last'") ("avg`tt'") ("`sr'`suffix'_`s'_`a'") (`avg_`sr'elas_`suffix'_`s'_`a'`tt'')
		}
	}	

*********************************************************************
* 2.1.4 - Mean regression
*********************************************************************
*********************************************************************
* 2.1.5 - Median regression
*********************************************************************	
foreach regression in mean median {

	if "`regression'"=="mean" {
		local regcommand "reg"
		local rpreffix ""
	}
	if "`regression'"=="median" {
		local regcommand "bsqreg"
		local rpreffix "med_"
	}
	
	* GDP-Activity
	*****************
	* Sectoral GDP-Sectoral Workers 
	**********************************
	* Sectoral Productivity-Sectoral Income 
	******************************************
	
		* noi di `" `regcommand' lnvalue lnvaluemfnv "'
		cap `regcommand' lnvalue lnvaluemfnv
		if _rc {
			noi di "   - insufficient observations for `country' `regcommand' _period`p' `sr' `a' `s'"
		}
		else {
			*noi di ""
			loc `sr'reg_`suffix'_`s'_`a' = _b[lnvaluemfnv]
			post `regressions' ("`country'") ("_period`p'") ("`min`p'' - `last'") ("`rpreffix'reg") ("`sr'`suffix'_`s'_`a'") (``sr'reg_`suffix'_`s'_`a'')	
		}

}


*********************************************************************
* 2.1.6 - Mean regression + Total GDP
*********************************************************************
*********************************************************************
* 2.1.7 - Mean regression + Total GDP * Informality rate
*********************************************************************

* Exclude regressions if _n<=3
qui count
if r(N)<=3 continue 

foreach it in 1 2 {
foreach regression in mean median {

	if "`regression'"=="mean" {
		local regcommand "reg"
		local rpreffix ""
	}
	if "`regression'"=="median" {
		local regcommand "bsqreg"
		local rpreffix "med_"
	}
	
	if `it'==1 {
		local regressors "lnvaluegdp valueiteration"
		local suffix2 "_gdp"
	}
	if `it'==2 {
		local regressors "lnvaluegdp valueiteration"
		local suffix2 "_iter"
	}
	
	* GDP-Activity
	*****************	
	* Sectoral GDP-Sectoral Workers 
	**********************************
	* Sectoral Productivity-Sectoral Income 
	******************************************
	
		*noi di `" `regcommand' lnvalue lnvaluemfnv lnvaluegdp "'
		cap `regcommand' lnvalue lnvaluemfnv lnvaluegdp
		if _rc {
			noi di "   - insufficient observations for `country' `regcommand' _period`p' `sr' `a' `s'"
		}
		else {
			*noi di ""
			loc `sr'reg_`suffix'_`s'_`a'`suffix2' = _b[lnvaluemfnv]
			post `regressions' ("`country'") ("_period`p'") ("`min`p'' - `last'") ("`rpreffix'reg`suffix2'") ("`sr'`suffix'_`s'_`a'") (``sr'reg_`suffix'_`s'_`a'`suffix2'')	
		}
	
}
}


noi di " -- Calculations for this loop have been completed" 

}
}
}
} // Closes loop for sr
} // Closes loop for countries
} // Closes loop for periods

postclose `regressions'
use `aux', clear
compress

replace period = "Long" if period == "_period1"
replace period = "Middle" if period == "_period2"
replace period = "Short" if period == "_period3"

gen nsectors = `ns'

sort country period year model elasticity
isid country period year model elasticity

if "`interpolations'"=="yes" {
	save "$data_in/Macro and elasticities/Elasticities_interpolations`ns'.dta", replace
	save "$data_in/Macro and elasticities/inputs_version_control/Elasticities_interpolations`ns'_`c(current_date)'.dta", replace
}
if "`interpolations'"=="" {
	save "$data_in/Macro and elasticities/Elasticities`ns'.dta", replace
	save "$data_in/Macro and elasticities/inputs_version_control/Elasticities`ns'_`c(current_date)'.dta", replace
}
etime
* End of do-file

}

use "$data_in/Macro and elasticities/Elasticities3.dta"
append using "$data_in/Macro and elasticities/Elasticities6.dta"
save "$data_in/Macro and elasticities/Elasticities.dta", replace

*
*use "Elasticities_interpolations.dta", clear
*rename value value_i
*merge 1:1 country period year model elasticity using "Elasticities.dta"




