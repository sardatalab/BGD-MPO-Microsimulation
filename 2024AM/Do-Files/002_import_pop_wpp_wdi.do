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
	local updateunwpp  "yes"		// if yes, re-process popdata.data 
	local processunwpp "yes"
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
if "`processunwpp'"=="yes" {
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
	
	gen popgroup = 103
	replace popgroup = 101 if cohortnum>=1 & cohortnum<=3
	replace popgroup = 102 if cohortnum>=4 & cohortnum<=13
	
	rename popgroup title
	
	collapse (sum) pop1950 - pop2100, by(country title)
	
	keep if inlist(country,"AFG","BGD","BTN","IND","MDV", "NPL","PAK","LKA")
	
	gen var = ""
	replace var = "unpop_0014" if title==101
	replace var = "unpop_1564" if title==102
	replace var = "unpop_65up" if title==103
	
	order country var
	
	preserve
		collapse (sum) pop1950 - pop2100, by(country)
		gen var = "unpop_total"
		gen title = 104
		order country var title
		tempfile poptotal
		save `poptotal'
	restore
	
	append using `poptotal'
	label define lbltitle 104 "UN Population, total", add 
	reshape long pop, i(country var title) j(year)
	keep if year>=2000 & year<=2030
	format pop %20.0f 
	
	* Final formatting
	
	rename pop 		value
	rename var	 	indicator
	rename country 	country
	rename year 	year
	
	gen date = "UN-WPP Rev. 2024"
	
	order country year indicator value date title
	sort  country year indicator
	
	tempfile unpopdata
	save `unpopdata', replace
	
	* Import WDI data
	* wbopendata, indicator(SP.POP.TOTL; SP.POP.1564.TO) long clear
	* save "$data_in/UN WPP/wdi_popdata.dta", replace
	use "$data_in/UN WPP/wdi_popdata.dta", clear
	
	rename countrycode country
	keep if inlist(country,"AFG","BGD","BTN","IND","MDV", "NPL","PAK","LKA")
	keep country year sp_*
	rename sp_* valuewbsp_*
	reshape long value, i(country year) j(indicator) string

	gen date = "`c(current_date)'"
	
	gen title = .
	replace title = 114 if indicator=="wbsp_pop_totl"
	replace title = 112 if indicator=="wbsp_pop_1564_to"
	
	label values title lbltitle
		
	order country year indicator value title date
	sort  country year indicator
	
	append using `unpopdata'
	
	label define lbltitle 101 "Population, 0-14 (UN)" 	102 "Population, 15-64 (UN)" 103 "Population, 65+ (UN)" 104 "Population, total (UN)", add
	label define lbltitle                          		112 "Population, 15-64 (WDI)"                     		114 "Population, total (WDI)" , add
	label values title lbltitle	
	
	save "$data_in/UN WPP/popdata_sar_mpo.dta", replace
}


	*export excel using "$data_in/Macro and elasticities/Working Input Elasticities.xlsx", sheet("input-unpop", replace) firstrow(variables)
	
	
********************************************************************************
* End of Do-File
********************************************************************************







