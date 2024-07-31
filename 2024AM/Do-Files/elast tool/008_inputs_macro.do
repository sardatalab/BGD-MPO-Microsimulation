
/*========================================================================
Project:			Macro-micro Simulations 
Institution:		World Bank - ELCPV

Authors:			Cicero Braga (csilveirabraga@worldbank.org) 
					& Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Creation Date:		08/01/2022

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date:  07/28/2023
========================================================================*/

clear all 

/****************************************************************************
	1 - Population data from WDI 
****************************************************************************/

* Load the data
wbopendata, update all
wbopendata, indicator(SP.POP.TOTL; SP.POP.1564.TO) year(2004:2025) projection clear

* Keep only LAC countries
keep if inlist(countrycode,"ARG","BOL","BRA","CHL","COL","CRI","DOM","ECU","GTM") | inlist(countrycode,"HND","MEX","NIC","PAN","PER","PRY","SLV","URY")
keep indicatorname  countrycode countryname yr*
replace indicatorname = "pop_1564" if indicatorname == "Population ages 15-64, total"
replace indicatorname = "pop_total" if indicatorname== "Population, total"

* Population share for 15-64 y.o.
reshape long yr, i(countrycode indicatorname) j(year)
reshape wide yr, i(countrycode year) j (indicatorname) string
gen share_pop = yrpop_1564/yrpop_total

* Save version control
compress
save "$path\inputs_version_control\inputs_pop_$version", replace


/****************************************************************************
	2 - POVMOD data (Macro and Total population) 
****************************************************************************/

* Load the data
use "$povmod", clear

* Keep only the most recent data
tab date
gen date1=date(date,"MDY")
egen datem= max(date1)
keep if date1 == datem
tab date

* Keep only LAC countries
keep if inlist(countrycode,"ARG","BOL","BRA","CHL","COL","CRI","DOM","ECU","GTM") | inlist(countrycode,"HND","MEX","NIC","PAN","PER","PRY","SLV","URY")

* Keep necessary variables
keep countrycode year pop gdpconstant agriconstant indusconstant servconstant date
order countrycode year gdpconstant agriconstant indusconstant servconstant pop
sort countrycode year

* Save version control
save "$path\inputs_version_control\inputs_mpo_gdp_$version", replace


/****************************************************************************
	3 - Final file
****************************************************************************/

* Merge population data
merge m:m countrycode year using "$path\inputs_version_control\inputs_pop_$version", keepusing(share) nogenerate

* New populations 
gen pop_1564_ = pop*share_pop*1000000
gen pop_total_ = pop * 1000000

* File structure
keep countrycode year date gdpconstant  agriconstant indusconstant servconstant  pop_*
rename gdpconstant v_gdp
rename agriconstant v_gdp_agriculture
rename indusconstant v_gdp_industry
rename servconstant v_gdp_services
rename pop_1564_ v_pop_1564
rename pop_total_ v_pop_total
reshape long v_, i(year countrycode) j(indicator) string
tab date
drop if v_==.
rename countrycode Country
rename year Year
rename indicator Indicator
rename v_ Value

order Country Year Indicator Value

* Saving 
save "$path\input-mpo.dta", replace
export excel using "$path_mpo/$outfile", sheet("input-mpo") sheetreplace firstrow(variables)
export excel using "$path_share/$outfile", sheet("input-mpo") sheetreplace firstrow(variables)
