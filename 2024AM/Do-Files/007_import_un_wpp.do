*!v4.1 Israe	l Osorio Rodarte August 2, 2024
*!v4.0 Israel Osorio Rodarte January 31, 2024
*!v3.0 Israel Osorio Rodarte November 29, 2021
/*========================================================================
Project:			Microsimulations Inputs from HIES
Institution:		World Bank

Author:				Israel Osorio-Rodarte (iosoriorodarte@worldbank.org)
Creation Date:		08/02/2024

Last Modification:	Israel Osorio-Rodarte (iosoriorodarte@worldbank.org)
Modification date: 	08/02/2024
========================================================================*/

********************************************************************************
* Import data from World Population Prospects
********************************************************************************

clear
set more off

* UN-WPP URL
	global unpath "https://population.un.org/wpp/Download/Files/1_Indicators%20(Standard)/EXCEL_FILES/2_Population"

* PARAMETERS
	local unpopdatatype "Medium variant"
	local unwpprevision "WPP2024"

* Running steps
	local updateunwpp "yes"	// if yes, re-process popdata.data 
	
********************************************************************************
* Update data from UN WPP
********************************************************************************
if "`updateunwpp'"=="" {
	
	foreach g in m f {
		local counter = 1
		foreach period in historical forecast {
		
			* Historical period
			if "`period'"=="historical" local readsheet "Estimates"
			if "`period'"=="forecast"	local readsheet "`unpopdatatype'"
			

			if "`g'"=="m" 	{
				local readgender "MALE"
				local i = 2
			}
			if "`g'"=="f"	{
				local readgender "FEMALE"
				local i = 3
			}
			
			noi di "Importing WPP from UN website"
			cap import excel using "$unpath/`unwpprevision'_POP_F02_`i'_POPULATION_5-YEAR_AGE_GROUPS_`readgender'.xlsx",   cellrange(A17) firstrow sheet(`readsheet') clear
			if _rc {
				noi di "failed..."
				noi di "Importing WPP from local directory"
				import excel using "$data_in/UN WPP/`unwpprevision'_POP_F02_`i'_POPULATION_5-YEAR_AGE_GROUPS_`readgender'.xlsx",   cellrange(A17) firstrow sheet(`readsheet') clear
			}
						
			rename L  y0004 
			rename M  y0509
			rename N  y1014
			rename O  y1519
			rename P  y2024
			rename Q  y2529
			rename R  y3034
			rename S  y3539
			rename T  y4044
			rename U  y4549
			rename V  y5054
			rename W  y5559
			rename X  y6064
			rename Y  y6569
			rename Z  y7074
			rename AA y7579
			rename AB y8084	
			rename AC y8589
			rename AD y9094
			rename AE y9599
			rename AF y100up
			
			foreach var of varlist y0004 - y100up {
				replace `var'="." if `var'=="..."
			}
			
			destring (y0004 - y100up), replace ignore(Ö)
			
			drop Index Variant Notes 
			
			rename Year year
			rename ISO3Alphacode isocode
			rename Regionsubregioncountryorar countrylong

			if `counter'==1 {
				tempfile file1
				save `file1', replace
			}
			else {
				append using `file1'
			}
			
			local counter = `counter'+1
		}
			
		foreach var of varlist y0004 -  y100up {
			cap replace `var'="." if `var'=="?"
			cap replace `var'="." if `var'=="…"
			destring `var', ignore("Ö") replace
		}

		duplicates drop 
		drop if isocode==""
		reshape long y, i(countrylong isocode year) string

		rename _j cohort
		drop if year==.
		reshape wide y, i(countrylong isocode cohort) j(year)

		replace cohort = "P"+cohort

		order isocode
		sort isocode cohort
		rename isocode country

		foreach var of varlist y1950 - y2100 {
			format `var' %15.0f
		}
		
		save "$path/popdata`g' `unpopdatatype'.dta", replace
	}

	use "$path/popdataf `unpopdatatype'.dta", clear
		forval i= 1950/2100 {
			replace y`i' = y`i'*1000
			rename y`i' popf`i'
			label var popf`i' "Population Female, `i'"
		}
		sort country cohort
		tempfile female
		save `female', replace

	use "$path/popdatam `unpopdatatype'.dta", clear
		forval i= 1950/2100 {
			replace y`i' = y`i'*1000
			rename y`i' popm`i'
			label var popm`i' "Population Male, `i'"
		}
		sort country cohort
		tempfile male
		save `male', replace

	use "`female'", clear
		merge country cohort using `male'
		tab _merge
		drop _merge
		
		* Final corrections
		replace country = "ROM" if country=="ROU"
		replace country = "ZAR" if country=="COD"
		replace country = "TMP" if country=="TLS"
		replace country = "WBG" if country=="PSE"
		

		order Locationcode ISO2Alphacode SDMXcode Type Parentcode country countrylong cohort
		drop Parentcode
		drop Type
		drop SDMXcode
		
		compress
		
		sort country cohort
		
		forval i = 1950/2100 {
			egen double pop`i' = rsum(popf`i' popm`i')
			label var pop`i' "Population, `i'"
		}
		
	save "$data_in/UN WPP/popdata.dta", replace

}

********************************************************************************
* Collects Population Data
********************************************************************************

	use country cohort pop* using "$data_in/UN WPP/popdata.dta", clear
	
	gen cohortnum = .
	forval i = 1/21 {
		
		local m = (`i'-1)*5
		local n = (`i'-1)*5 + 4
		
		noi di "`i' `m' `n'"
		
		if `i'>=1  & `i'<=2  {
			replace cohortnum = `i' if cohort=="P0`m'0`n'"
			label define lblcohortnum `i' "Pop `m' - `n'", add
		}
		if `i'>=3  & `i'<=20 {
			replace cohortnum = `i' if cohort=="P`m'`n'"
			label define lblcohortnum `i' "Pop `m' - `n'", add
		}
		if `i'==21  {
			replace cohortnum = `i' if cohort=="P`m'up"
			label define lblcohortnum `i' "P`m'up", add
		}
	}
	
	label values cohortnum lblcohortnum
	
	gen popgroup = 3
	replace popgroup = 1 if cohortnum>=1 & cohortnum<=3
	replace popgroup = 2 if cohortnum>=4 & cohortnum<=13
	
	label define lblpopgroup 1 "UN Population 0-14" 2 "UN Population 15-64" 3 "UN Population 65+", add
	label values popgroup lblpopgroup
	
	collapse (sum) pop1950 - pop2100, by(country popgroup)
	
	keep if inlist(country,"BGD","LKA","MDV")
	
	gen var = ""
	replace var = "unpop_0014" if popgroup==1
	replace var = "unpop_1564" if popgroup==2
	replace var = "unpop_65up" if popgroup==3
	
	order country var
	
	preserve
		collapse (sum) pop1950 - pop2100, by(country)
		gen var = "unpop_total"
		gen popgroup = 4
		order country var popgroup
		tempfile poptotal
		save `poptotal'
	restore
	
	append using `poptotal'
	label define lblpopgroup 4 "UN Population, total", add 
	rename popgroup pg
	reshape long pop, i(country var pg) j(year)
	keep if year>=2010 & year<=2030
	format pop %20.0f 
	
	* Final formatting
	
	rename pop Value
	rename pg  Indicator
	rename var variable
	order country year variable Indicator Value	
	sort  country year variable 
	save "$data_in/UN WPP/popdata_sar_mpo.dta", replace
	

	
	export excel using "$data_in/Macro and elasticities/Working Input Elasticities.xlsx", sheet("input-unpop", replace) firstrow(variables)
	
	
********************************************************************************
* End of Do-File
********************************************************************************







