
/*========================================================================
Project:			Macro-micro Simulations
Institution:		World Bank - ELCPV

Author:				Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Creation Date:		02/25/2022

Last Modification:	Rodrigo Surraco (rsurracowilliman@worldbank.org)
Modification date:  07/27/2023 (export to Excel)
========================================================================*/

drop _all

**************************************************************************
* 	0 - SETTING
**************************************************************************

* Set up postfile for results
tempname regressions
tempfile aux
postfile `regressions' str3(Country) str10(Period) str11(Year) str20(Model) str80(Elasticity) Value using `aux', replace

local n : word count $countries

*************************************************************************
* 	1 - DATA FILE AND VARIABLES
*************************************************************************

use $input_sedlac, clear
gen source = "SEDLAC"
append using $input_lablac
replace source = "LABLAC" if source == ""
duplicates tag Country Year Indicator, gen(duplicates)
drop if duplicates == 1 & source == "LABLAC"
duplicates report Country Year Indicator
drop duplicates source

replace Indicator = subinstr(Indicator," ","_",.)
replace Indicator = subinstr(Indicator,".","",.)
replace Indicator = subinstr(Indicator,"agriculture","agri",.)
replace Indicator = subinstr(Indicator,"industry","ind",.)
replace Indicator = subinstr(Indicator,"services","serv",.)

reshape wide Value, i(Country Year) j(Indicator) string

ren Value* *
ren *, lower
drop if active == . | gdp == . | country == "NIC"
drop avg_formal_income avg_income avg_informal_income inactive_population total_population unemployed_population working_population

* Total of workers by sector
for any agri ind serv: egen workers_X = rowtotal(formal_workers_X informal_workers_X)

* Total of workers by informality
for any formal informal : egen workers_X = rowtotal(X_workers_agri X_workers_ind X_workers_serv)

* Total of workers
egen workers = rowtotal(workers_formal workers_informal)

* Informality rate
gen informality = workers_informal / workers

* Productivities
for any agri ind serv : gen prod_X = X / workers_X 

* Creating logs of employment and gdp
foreach v of varlist active_population-workers_serv prod_agri-prod_serv {
	gen log_`v' = log(`v')
}

* Growth rates
foreach v of varlist active_population-workers_serv prod_agri-prod_serv {
	gen growth_`v' = (`v'/ `v'[_n-1] - 1) if country[_n] == country[_n-1]
}

* Annual elasticities employment
for any agri ind serv : gen elas_gdp_for_X = growth_formal_workers_X / growth_X
for any agri ind serv : gen elas_gdp_inf_X = growth_informal_workers_X / growth_X
gen elas_gdp_emp = growth_active_population / growth_gdp

* Annual elasticities income
for any agri ind serv : gen elas_prod_for_X = growth_avg_formal_income_X / growth_prod_X
for any agri ind serv : gen elas_prod_inf_X = growth_avg_informal_income_X / growth_prod_X

* Iteration variables log_gdp * informality rate
gen iteration = log_gdp * informality

* Missing variables
for any elas_gdp_emp_1_99 elas_gdp_emp_1_99_imp: gen X = .
local sectors "agri ind serv"
foreach s of local sectors {
	qui gen elas_gdp_for_`s'_1_99 = .
	qui gen elas_gdp_inf_`s'_1_99 = .
	qui gen elas_prod_for_`s'_1_99 = .
	qui gen elas_prod_inf_`s'_1_99 = .
	
	qui gen elas_gdp_for_`s'_1_99_imp = .
	qui gen elas_gdp_inf_`s'_1_99_imp = .
	qui gen elas_prod_for_`s'_1_99_imp = .
	qui gen elas_prod_inf_`s'_1_99_imp = .
}

*************************************************************************
* 	2 - ELASTICITIES
*************************************************************************

forvalues i = 1/`n' {
	local country 	: word `i' of $countries
    local min 		: word `i' of $min_year
	local last 		: word `i' of $last_year
	local min2		: word `i' of $min_year2
	local min3		: word `i' of $min_year3
	
	
	di in red "`country'"
	
	*********************************************************************
	* 2.1 - Minimum year to last year available
	*********************************************************************
	
	di in red "Period `min' - `last'"
	
	*********************************************************************
	* 2.1.1 - Simple averages
	*********************************************************************
	
	* GDP-Activity
	*****************
	qui sum elas_gdp_emp if year >= `min' & year <= `last' & country == "`country'"
	loc av_elas_gdp_emp = r(mean)
	post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("avg") ("gdp_activity") (`av_elas_gdp_emp')
	
	* Sectoral GDP-Sectoral Workers 
	**********************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui sum elas_gdp_for_`sector' if year >= `min' & year <= `last' & country == "`country'"
		loc avg_elas_gdp_for_`sector' = r(mean)
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("avg") ("gdp_for_`sector'") (`avg_elas_gdp_for_`sector'')
		
		** Informal
		qui sum elas_gdp_inf_`sector' if year >= `min' & year <= `last' & country == "`country'"
		loc avg_elas_gdp_inf_`sector' = r(mean)
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("avg") ("gdp_inf_`sector'") (`avg_elas_gdp_inf_`sector'')
		
	}
	
	* Sectoral Productivity-Sectoral Income 
	******************************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui sum elas_prod_for_`sector' if year >= `min' & year <= `last' & country == "`country'"
		loc avg_elas_prod_for_`sector' = r(mean)
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("avg") ("prod_for_`sector'") (`avg_elas_prod_for_`sector'')
		
		** Informal
		qui sum elas_prod_inf_`sector' if year >= `min' & year <= `last' & country == "`country'"
		loc avg_elas_prod_inf_`sector' = r(mean)
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("avg") ("prod_inf_`sector'") (`avg_elas_prod_inf_`sector'')
		
	}
	
	
	*********************************************************************
	* 2.1.2 - Averages without outliers (1%-99%)
	*********************************************************************
	
	* GDP-Activity
	*****************
	qui sum elas_gdp_emp if year >= `min' & year <= `last' & country == "`country'", d
	qui replace elas_gdp_emp_1_99 = elas_gdp_emp if year >= `min' & year <= `last' & country == "`country'" & elas_gdp_emp > r(p1) & elas_gdp_emp < r(p99)
	qui sum elas_gdp_emp_1_99 if year >= `min' & year <= `last' & country == "`country'"
	loc av_elas_gdp_emp_1_99 = r(mean)
	post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("avg_1_99") ("gdp_activity") (`av_elas_gdp_emp_1_99')
	
	* Sectoral GDP-Sectoral Workers 
	**********************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui sum elas_gdp_for_`sector' if year >= `min' & year <= `last' & country == "`country'", d
		qui replace elas_gdp_for_`sector'_1_99 = elas_gdp_for_`sector' if year >= `min' & year <= `last' & country == "`country'" &elas_gdp_for_`sector' > r(p1) & elas_gdp_for_`sector' < r(p99)
		qui sum elas_gdp_for_`sector'_1_99 if year >= `min' & year <= `last' & country == "`country'"
		loc avg_elas_gdp_for_`sector'_1_99 = r(mean)
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("avg_1_99") ("gdp_for_`sector'") (`avg_elas_gdp_for_`sector'_1_99')
		
		** Informal
		qui sum elas_gdp_inf_`sector' if year >= `min' & year <= `last' & country == "`country'", d
		qui replace elas_gdp_inf_`sector'_1_99 = elas_gdp_inf_`sector' if year >= `min' & year <= `last' & country == "`country'" & elas_gdp_inf_`sector' > r(p1) & elas_gdp_inf_`sector' < r(p99)
		qui sum elas_gdp_inf_`sector'_1_99 if year >= `min' & year <= `last' & country == "`country'"
		loc avg_elas_gdp_inf_`sector'_1_99 = r(mean)
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("avg_1_99") ("gdp_inf_`sector'") (`avg_elas_gdp_inf_`sector'_1_99')
		
	}
	
	* Sectoral Productivity-Sectoral Income 
	******************************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui sum elas_prod_for_`sector' if year >= `min' & year <= `last' & country == "`country'", d
		qui replace elas_prod_for_`sector'_1_99 = elas_prod_for_`sector' if year >= `min' & year <= `last' & country == "`country'" & elas_prod_for_`sector' > r(p1) & elas_prod_for_`sector' < r(p99)
		qui sum elas_prod_for_`sector'_1_99 if year >= `min' & year <= `last' & country == "`country'"
		loc avg_elas_prod_for_`sector'_1_99 = r(mean)
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("avg_1_99") ("prod_for_`sector'") (`avg_elas_prod_for_`sector'_1_99')
		
		** Informal
		qui sum elas_prod_inf_`sector' if year >= `min' & year <= `last' & country == "`country'", d
		qui replace elas_prod_inf_`sector'_1_99 = elas_prod_inf_`sector' if year >= `min' & year <= `last' & country == "`country'" & elas_prod_inf_`sector' > r(p1) & elas_prod_inf_`sector' < r(p99)
		qui sum elas_prod_inf_`sector'_1_99 if year >= `min' & year <= `last' & country == "`country'"
		loc avg_elas_prod_inf_`sector'_1_99 = r(mean)
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("avg_1_99") ("prod_inf_`sector'") (`avg_elas_prod_inf_`sector'_1_99')
		
	}
	
	
	*********************************************************************
	* 2.1.3 - Averages with imputed outliers (1%-99% using mean)
	*********************************************************************
		
	* GDP-Activity
	*****************
	qui sum elas_gdp_emp_1_99 if year >= `min' & year <= `last' & country == "`country'", d
	loc av_elas_gdp_emp_1_99 = r(p50)
	qui replace elas_gdp_emp_1_99_imp = elas_gdp_emp_1_99 if year >= `min' & year <= `last' & country == "`country'"
	qui replace elas_gdp_emp_1_99_imp = `av_elas_gdp_emp_1_99' if elas_gdp_emp_1_99_imp == . & elas_gdp_emp != . & year >= `min' & year <= `last' & country == "`country'"
	qui sum elas_gdp_emp_1_99_imp if year >= `min' & year <= `last' & country == "`country'"
	loc av_elas_gdp_emp_1_99_imp = r(mean)
	post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("avg_1_99_imp") ("gdp_activity") (`av_elas_gdp_emp_1_99_imp')
	
	* Sectoral GDP-Sectoral Workers 
	**********************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui sum elas_gdp_for_`sector'_1_99 if year >= `min' & year <= `last' & country == "`country'", d
		loc avg_elas_gdp_for_`sector'_1_99 = r(p50)
		qui replace elas_gdp_for_`sector'_1_99_imp = elas_gdp_for_`sector'_1_99 if year >= `min' & year <= `last' & country == "`country'"
		qui replace elas_gdp_for_`sector'_1_99_imp = `avg_elas_gdp_for_`sector'_1_99' if elas_gdp_for_`sector'_1_99_imp == . & elas_gdp_for_`sector' != . & year >= `min' & year <= `last' & country == "`country'"
		qui sum elas_gdp_for_`sector'_1_99_imp if year >= `min' & year <= `last' & country == "`country'"
		loc avg_elas_gdp_for_`sector'_1_99_imp = r(mean)
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("avg_1_99_imp") ("gdp_for_`sector'") (`avg_elas_gdp_for_`sector'_1_99_imp')
		
		** Informal
		qui sum elas_gdp_inf_`sector'_1_99 if year >= `min' & year <= `last' & country == "`country'", d
		loc avg_elas_gdp_inf_`sector'_1_99 = r(p50)
		qui replace elas_gdp_inf_`sector'_1_99_imp = elas_gdp_inf_`sector'_1_99 if year >= `min' & year <= `last' & country == "`country'"
		qui replace elas_gdp_inf_`sector'_1_99_imp = `avg_elas_gdp_inf_`sector'_1_99' if elas_gdp_inf_`sector'_1_99_imp == . & elas_gdp_inf_`sector' != . & year >= `min' & year <= `last' & country == "`country'"
		qui sum elas_gdp_inf_`sector'_1_99_imp if year >= `min' & year <= `last' & country == "`country'"
		loc avg_elas_gdp_inf_`sector'_1_99_imp = r(mean)
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("avg_1_99_imp") ("gdp_inf_`sector'") (`avg_elas_gdp_inf_`sector'_1_99_imp')
		
	}
	
	* Sectoral Productivity-Sectoral Income 
	******************************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui sum elas_prod_for_`sector'_1_99 if year >= `min' & year <= `last' & country == "`country'", d
		loc avg_elas_prod_for_`sector'_1_99 = r(p50)
		qui replace elas_prod_for_`sector'_1_99_imp = elas_prod_for_`sector'_1_99 if year >= `min' & year <= `last' & country == "`country'"
		qui replace elas_prod_for_`sector'_1_99_imp = `avg_elas_prod_for_`sector'_1_99' if elas_prod_for_`sector'_1_99_imp == . & elas_prod_for_`sector' != . & year >= `min' & year <= `last' & country == "`country'"
		qui sum elas_prod_for_`sector'_1_99_imp if year >= `min' & year <= `last' & country == "`country'"
		loc avg_elas_prod_for_`sector'_1_99_imp = r(mean)
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("avg_1_99_imp") ("prod_for_`sector'") (`avg_elas_prod_for_`sector'_1_99')
		
		** Informal
		qui sum elas_prod_inf_`sector'_1_99 if year >= `min' & year <= `last' & country == "`country'", d
		loc avg_elas_prod_inf_`sector'_1_99 = r(p50)
		qui replace elas_prod_inf_`sector'_1_99_imp = elas_prod_inf_`sector'_1_99 if year >= `min' & year <= `last' & country == "`country'"
		qui replace elas_prod_inf_`sector'_1_99_imp = `avg_elas_prod_inf_`sector'_1_99' if elas_prod_inf_`sector'_1_99_imp == . & elas_prod_inf_`sector' != . & year >= `min' & year <= `last' & country == "`country'"
		qui sum elas_prod_inf_`sector'_1_99_imp if year >= `min' & year <= `last' & country == "`country'"
		loc avg_elas_prod_inf_`sector'_1_99_imp = r(mean)
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("avg_1_99_imp") ("prod_inf_`sector'") (`avg_elas_prod_inf_`sector'_1_99_imp')
		
	}
	
	
	*********************************************************************
	* 2.1.4 - Mean regression
	*********************************************************************
	
	* GDP-Activity
	*****************
	qui reg log_active_population log_gdp if year >= `min' & year <= `last' & country == "`country'"
	loc reg_gdp_emp = _b[log_gdp]
	post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("reg") ("gdp_activity") (`reg_gdp_emp')
	
	* Sectoral GDP-Sectoral Workers 
	**********************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui reg log_formal_workers_`sector' log_`sector' if year >= `min' & year <= `last' & country == "`country'"
		loc reg_gdp_for_`sector' = _b[log_`sector']
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("reg") ("gdp_for_`sector'") (`reg_gdp_for_`sector'')
		
		** Informal
		qui reg log_informal_workers_`sector' log_`sector' if year >= `min' & year <= `last' & country == "`country'"
		loc reg_gdp_inf_`sector' = _b[log_`sector']
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("reg") ("gdp_inf_`sector'") (`reg_gdp_inf_`sector'')
		
	}
	
	* Sectoral Productivity-Sectoral Income 
	******************************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui reg log_avg_formal_income_`sector' log_prod_`sector' if year >= `min' & year <= `last' & country == "`country'"
		loc reg_prod_for_`sector' = _b[log_prod_`sector']
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("reg") ("prod_for_`sector'") (`reg_prod_for_`sector'')
		
		** Informal
		qui reg log_avg_informal_income_`sector' log_prod_`sector' if year >= `min' & year <= `last' & country == "`country'"
		loc reg_prod_inf_`sector' = _b[log_prod_`sector']
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("reg") ("prod_inf_`sector'") (`reg_prod_inf_`sector'')
		
	}
	
	
	*********************************************************************
	* 2.1.5 - Median regression
	*********************************************************************
	
	if "`country'" != "CHL" {
		
		* GDP-Activity
		*****************
		qui qreg log_active_population log_gdp if year >= `min' & year <= `last' & country == "`country'", vce(robust)
		loc med_reg_gdp_emp = _b[log_gdp]
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("med_reg") ("gdp_activity") (`med_reg_gdp_emp')
		
		* Sectoral GDP-Sectoral Workers 
		**********************************
		local sectors "agri ind serv"
		foreach sector of local sectors {
			
			** Formal
			qui qreg log_formal_workers_`sector' log_`sector' if year >= `min' & year <= `last' & country == "`country'"
			loc med_reg_gdp_for_`sector' = _b[log_`sector']
			post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("med_reg") ("gdp_for_`sector'") (`med_reg_gdp_for_`sector'')
			
			** Informal
			qui qreg log_informal_workers_`sector' log_`sector' if year >= `min' & year <= `last' & country == "`country'"
			loc med_reg_gdp_inf_`sector' = _b[log_`sector']
			post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("med_reg") ("gdp_inf_`sector'") (`med_reg_gdp_inf_`sector'')
			
		}
		
		* Sectoral Productivity-Sectoral Income 
		******************************************
		local sectors "agri ind serv"
		foreach sector of local sectors {
			
			** Formal
			qui qreg log_avg_formal_income_`sector' log_prod_`sector' if year >= `min' & year <= `last' & country == "`country'"
			loc med_reg_prod_for_`sector' = _b[log_prod_`sector']
			post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("med_reg") ("prod_for_`sector'") (`med_reg_prod_for_`sector'')
			
			** Informal
			qui qreg log_avg_informal_income_`sector' log_prod_`sector' if year >= `min' & year <= `last' & country == "`country'"
			loc med_reg_prod_inf_`sector' = _b[log_prod_`sector']
			post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("med_reg") ("prod_inf_`sector'") (`med_reg_prod_inf_`sector'')
			
		}
	}
	
	
	*********************************************************************
	* 2.1.6 - Mean regression + Total GDP
	*********************************************************************
	
	* GDP-Activity
	*****************
	qui reg log_active_population log_gdp if year >= `min' & year <= `last' & country == "`country'"
	loc reg_gdp_emp_2 = _b[log_gdp]
	post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("reg_gdp") ("gdp_activity") (`reg_gdp_emp_2')
	
	* Sectoral GDP-Sectoral Workers 
	**********************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui reg log_formal_workers_`sector' log_`sector' log_gdp if year >= `min' & year <= `last' & country == "`country'"
		loc reg_gdp_for_`sector'_2 = _b[log_`sector']
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("reg_gdp") ("gdp_for_`sector'") (`reg_gdp_for_`sector'_2')
		
		** Informal
		qui reg log_informal_workers_`sector' log_`sector' log_gdp if year >= `min' & year <= `last' & country == "`country'"
		loc reg_gdp_inf_`sector'_2 = _b[log_`sector']
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("reg_gdp") ("gdp_inf_`sector'") (`reg_gdp_inf_`sector'_2')
		
	}
	
	* Sectoral Productivity-Sectoral Income 
	******************************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui reg log_avg_formal_income_`sector' log_prod_`sector' log_gdp if year >= `min' & year <= `last' & country == "`country'"
		loc reg_prod_for_`sector'_2 = _b[log_prod_`sector']
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("reg_gdp") ("prod_for_`sector'") (`reg_prod_for_`sector'_2')
		
		** Informal
		qui reg log_avg_informal_income_`sector' log_prod_`sector' log_gdp if year >= `min' & year <= `last' & country == "`country'"
		loc reg_prod_inf_`sector'_2 = _b[log_prod_`sector']
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("reg_gdp") ("prod_inf_`sector'") (`reg_prod_inf_`sector'_2')
		
	}
	
	
	*********************************************************************
	* 2.1.7 - Mean regression + Total GDP * Informality rate
	*********************************************************************
	
	* GDP-Activity
	*****************
	qui reg log_active_population log_gdp iteration if year >= `min' & year <= `last' & country == "`country'"
	loc reg_gdp_emp_3 = _b[log_gdp]
	post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("reg_iter") ("gdp_activity") (`reg_gdp_emp_3')
	
	* Sectoral GDP-Sectoral Workers 
	**********************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui reg log_formal_workers_`sector' log_`sector' iteration if year >= `min' & year <= `last' & country == "`country'"
		loc reg_gdp_for_`sector'_3 = _b[log_`sector']
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("reg_iter") ("gdp_for_`sector'") (`reg_gdp_for_`sector'_3')
		
		** Informal
		qui reg log_informal_workers_`sector' log_`sector' iteration if year >= `min' & year <= `last' & country == "`country'"
		loc reg_gdp_inf_`sector'_3 = _b[log_`sector']
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("reg_iter") ("gdp_inf_`sector'") (`reg_gdp_inf_`sector'_3')
		
	}
	
	* Sectoral Productivity-Sectoral Income 
	******************************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui reg log_avg_formal_income_`sector' log_prod_`sector' iteration if year >= `min' & year <= `last' & country == "`country'"
		loc reg_prod_for_`sector'_3 = _b[log_prod_`sector']
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("reg_iter") ("prod_for_`sector'") (`reg_prod_for_`sector'_3')
		
		** Informal
		qui reg log_avg_informal_income_`sector' log_prod_`sector' iteration if year >= `min' & year <= `last' & country == "`country'"
		loc reg_prod_inf_`sector'_3 = _b[log_prod_`sector']
		post `regressions' ("`country'") ("_period1") ("`min' - `last'") ("reg_iter") ("prod_inf_`sector'") (`reg_prod_inf_`sector'_3')
		
	}
	
	
	*********************************************************************
	* 2.2 - Middle year to last year available
	*********************************************************************
	
	di in red "Period `min2' - `last'"
	
	*********************************************************************
	* 2.2.1 - Simple averages
	*********************************************************************
	
	* GDP-Activity
	*****************
	qui sum elas_gdp_emp if year >= `min2' & year <= `last' & country == "`country'"
	loc av_elas_gdp_emp = r(mean)
	post `regressions' ("`country'") ("_period2") ("`min2' - `last'") ("avg") ("gdp_activity") (`av_elas_gdp_emp')
	
	* Sectoral GDP-Sectoral Workers 
	**********************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui sum elas_gdp_for_`sector' if year >= `min2' & year <= `last' & country == "`country'"
		loc avg_elas_gdp_for_`sector' = r(mean)
		post `regressions' ("`country'") ("_period2") ("`min2' - `last'") ("avg") ("gdp_for_`sector'") (`avg_elas_gdp_for_`sector'')
		
		** Informal
		qui sum elas_gdp_inf_`sector' if year >= `min2' & year <= `last' & country == "`country'"
		loc avg_elas_gdp_inf_`sector' = r(mean)
		post `regressions' ("`country'") ("_period2") ("`min2' - `last'") ("avg") ("gdp_inf_`sector'") (`avg_elas_gdp_inf_`sector'')
		
	}
	
	* Sectoral Productivity-Sectoral Income 
	******************************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui sum elas_prod_for_`sector' if year >= `min2' & year <= `last' & country == "`country'"
		loc avg_elas_prod_for_`sector' = r(mean)
		post `regressions' ("`country'") ("_period2") ("`min2' - `last'") ("avg") ("prod_for_`sector'") (`avg_elas_prod_for_`sector'')
		
		** Informal
		qui sum elas_prod_inf_`sector' if year >= `min2' & year <= `last' & country == "`country'"
		loc avg_elas_prod_inf_`sector' = r(mean)
		post `regressions' ("`country'") ("_period2") ("`min2' - `last'") ("avg") ("prod_inf_`sector'") (`avg_elas_prod_inf_`sector'')
		
	}
	
	
	*********************************************************************
	* 2.2.2 - Averages without outliers (1%-99%)
	*********************************************************************
	
	* GDP-Activity
	*****************
	qui sum elas_gdp_emp if year >= `min2' & year <= `last' & country == "`country'", d
	qui replace elas_gdp_emp_1_99 = elas_gdp_emp if year >= `min2' & year <= `last' & country == "`country'" & elas_gdp_emp > r(p1) & elas_gdp_emp < r(p99)
	qui sum elas_gdp_emp_1_99 if year >= `min2' & year <= `last' & country == "`country'"
	loc av_elas_gdp_emp_1_99 = r(mean)
	post `regressions' ("`country'") ("_period2") ("`min2' - `last'") ("avg_1_99") ("gdp_activity") (`av_elas_gdp_emp_1_99')
	
	* Sectoral GDP-Sectoral Workers 
	**********************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui sum elas_gdp_for_`sector' if year >= `min2' & year <= `last' & country == "`country'", d
		qui replace elas_gdp_for_`sector'_1_99 = elas_gdp_for_`sector' if year >= `min2' & year <= `last' & country == "`country'" & elas_gdp_for_`sector' > r(p1) & elas_gdp_for_`sector' < r(p99)
		qui sum elas_gdp_for_`sector'_1_99 if year >= `min2' & year <= `last' & country == "`country'"
		loc avg_elas_gdp_for_`sector'_1_99 = r(mean)
		post `regressions' ("`country'") ("_period2") ("`min2' - `last'") ("avg_1_99") ("gdp_for_`sector'") (`avg_elas_gdp_for_`sector'_1_99')
		
		** Informal
		qui sum elas_gdp_inf_`sector' if year >= `min2' & year <= `last' & country == "`country'", d
		qui replace elas_gdp_inf_`sector'_1_99 = elas_gdp_inf_`sector' if year >= `min2' & year <= `last' & country == "`country'" & elas_gdp_inf_`sector' > r(p1) & elas_gdp_inf_`sector' < r(p99)
		qui sum elas_gdp_inf_`sector'_1_99 if year >= `min2' & year <= `last' & country == "`country'"
		loc avg_elas_gdp_inf_`sector'_1_99 = r(mean)
		post `regressions' ("`country'") ("_period2") ("`min2' - `last'") ("avg_1_99") ("gdp_inf_`sector'") (`avg_elas_gdp_inf_`sector'_1_99')
		
	}
	
	* Sectoral Productivity-Sectoral Income 
	******************************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui sum elas_prod_for_`sector' if year >= `min2' & year <= `last' & country == "`country'", d
		qui replace elas_prod_for_`sector'_1_99 = elas_prod_for_`sector' if year >= `min2' & year <= `last' & country == "`country'" & elas_prod_for_`sector' > r(p1) & elas_prod_for_`sector' < r(p99)
		qui sum elas_prod_for_`sector'_1_99 if year >= `min2' & year <= `last' & country == "`country'"
		loc avg_elas_prod_for_`sector'_1_99 = r(mean)
		post `regressions' ("`country'") ("_period2") ("`min2' - `last'") ("avg_1_99") ("prod_for_`sector'") (`avg_elas_prod_for_`sector'_1_99')
		
		** Informal
		qui sum elas_prod_inf_`sector' if year >= `min2' & year <= `last' & country == "`country'", d
		qui replace elas_prod_inf_`sector'_1_99 = elas_prod_inf_`sector' if year >= `min2' & year <= `last' & country == "`country'" & elas_prod_inf_`sector' > r(p1) & elas_prod_inf_`sector' < r(p99)
		qui sum elas_prod_inf_`sector'_1_99 if year >= `min2' & year <= `last' & country == "`country'"
		loc avg_elas_prod_inf_`sector'_1_99 = r(mean)
		post `regressions' ("`country'") ("_period2") ("`min2' - `last'") ("avg_1_99") ("prod_inf_`sector'") (`avg_elas_prod_inf_`sector'_1_99')
		
	}
	
	
	*********************************************************************
	* 2.2.3 - Averages with imputed outliers (1%-99% using mean)
	*********************************************************************
		
	* GDP-Activity
	*****************
	qui sum elas_gdp_emp_1_99 if year >= `min2' & year <= `last' & country == "`country'", d
	loc av_elas_gdp_emp_1_99 = r(p50)
	qui replace elas_gdp_emp_1_99_imp = elas_gdp_emp_1_99 if year >= `min2' & year <= `last' & country == "`country'"
	qui replace elas_gdp_emp_1_99_imp = `av_elas_gdp_emp_1_99' if elas_gdp_emp_1_99_imp == . & elas_gdp_emp != . & year >= `min2' & year <= `last' & country == "`country'"
	qui sum elas_gdp_emp_1_99_imp if year >= `min2' & year <= `last' & country == "`country'"
	loc av_elas_gdp_emp_1_99_imp = r(mean)
	post `regressions' ("`country'") ("_period2") ("`min2' - `last'") ("avg_1_99_imp") ("gdp_activity") (`av_elas_gdp_emp_1_99_imp')
	
	* Sectoral GDP-Sectoral Workers 
	**********************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui sum elas_gdp_for_`sector'_1_99 if year >= `min2' & year <= `last' & country == "`country'", d
		loc avg_elas_gdp_for_`sector'_1_99 = r(p50)
		qui replace elas_gdp_for_`sector'_1_99_imp = elas_gdp_for_`sector'_1_99 if year >= `min2' & year <= `last' & country == "`country'"
		qui replace elas_gdp_for_`sector'_1_99_imp = `avg_elas_gdp_for_`sector'_1_99' if elas_gdp_for_`sector'_1_99_imp == . & elas_gdp_for_`sector' != . & year >= `min2' & year <= `last' & country == "`country'"
		qui sum elas_gdp_for_`sector'_1_99_imp if year >= `min2' & year <= `last' & country == "`country'"
		loc avg_elas_gdp_for_`sector'_1_99_imp = r(mean)
		post `regressions' ("`country'") ("_period2") ("`min2' - `last'") ("avg_1_99_imp") ("gdp_for_`sector'") (`avg_elas_gdp_for_`sector'_1_99_imp')
		
		** Informal
		qui sum elas_gdp_inf_`sector'_1_99 if year >= `min2' & year <= `last' & country == "`country'", d
		loc avg_elas_gdp_inf_`sector'_1_99 = r(p50)
		qui replace elas_gdp_inf_`sector'_1_99_imp = elas_gdp_inf_`sector'_1_99 if year >= `min2' & year <= `last' & country == "`country'"
		qui replace elas_gdp_inf_`sector'_1_99_imp = `avg_elas_gdp_inf_`sector'_1_99' if elas_gdp_inf_`sector'_1_99_imp == . & elas_gdp_inf_`sector' != . & year >= `min2' & year <= `last' & country == "`country'"
		qui sum elas_gdp_inf_`sector'_1_99_imp if year >= `min2' & year <= `last' & country == "`country'"
		loc avg_elas_gdp_inf_`sector'_1_99_imp = r(mean)
		post `regressions' ("`country'") ("_period2") ("`min2' - `last'") ("avg_1_99_imp") ("gdp_inf_`sector'") (`avg_elas_gdp_inf_`sector'_1_99_imp')
		
	}
	
	* Sectoral Productivity-Sectoral Income 
	******************************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui sum elas_prod_for_`sector'_1_99 if year >= `min2' & year <= `last' & country == "`country'", d
		loc avg_elas_prod_for_`sector'_1_99 = r(p50)
		qui replace elas_prod_for_`sector'_1_99_imp = elas_prod_for_`sector'_1_99 if year >= `min2' & year <= `last' & country == "`country'"
		qui replace elas_prod_for_`sector'_1_99_imp = `avg_elas_prod_for_`sector'_1_99' if elas_prod_for_`sector'_1_99_imp == . & elas_prod_for_`sector' != . & year >= `min2' & year <= `last' & country == "`country'"
		qui sum elas_prod_for_`sector'_1_99_imp if year >= `min2' & year <= `last' & country == "`country'"
		loc avg_elas_prod_for_`sector'_1_99_imp = r(mean)
		post `regressions' ("`country'") ("_period2") ("`min2' - `last'") ("avg_1_99_imp") ("prod_for_`sector'") (`avg_elas_prod_for_`sector'_1_99')
		
		** Informal
		qui sum elas_prod_inf_`sector'_1_99 if year >= `min2' & year <= `last' & country == "`country'", d
		loc avg_elas_prod_inf_`sector'_1_99 = r(p50)
		qui replace elas_prod_inf_`sector'_1_99_imp = elas_prod_inf_`sector'_1_99 if year >= `min2' & year <= `last' & country == "`country'"
		qui replace elas_prod_inf_`sector'_1_99_imp = `avg_elas_prod_inf_`sector'_1_99' if elas_prod_inf_`sector'_1_99_imp == . & elas_prod_inf_`sector' != . & year >= `min2' & year <= `last' & country == "`country'"
		qui sum elas_prod_inf_`sector'_1_99_imp if year >= `min2' & year <= `last' & country == "`country'"
		loc avg_elas_prod_inf_`sector'_1_99_imp = r(mean)
		post `regressions' ("`country'") ("_period2") ("`min2' - `last'") ("avg_1_99_imp") ("prod_inf_`sector'") (`avg_elas_prod_inf_`sector'_1_99_imp')
		
	}
	
	
	*********************************************************************
	* 2.2.4 - Mean regression
	*********************************************************************
	
	* GDP-Activity
	*****************
	qui reg log_active_population log_gdp if year >= `min2' & year <= `last' & country == "`country'"
	loc reg_gdp_emp = _b[log_gdp]
	post `regressions' ("`country'") ("_period2") ("`min2' - `last'") ("reg") ("gdp_activity") (`reg_gdp_emp')
	
	* Sectoral GDP-Sectoral Workers 
	**********************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui reg log_formal_workers_`sector' log_`sector' if year >= `min2' & year <= `last' & country == "`country'"
		loc reg_gdp_for_`sector' = _b[log_`sector']
		post `regressions' ("`country'") ("_period2") ("`min2' - `last'") ("reg") ("gdp_for_`sector'") (`reg_gdp_for_`sector'')
		
		** Informal
		qui reg log_informal_workers_`sector' log_`sector' if year >= `min2' & year <= `last' & country == "`country'"
		loc reg_gdp_inf_`sector' = _b[log_`sector']
		post `regressions' ("`country'") ("_period2") ("`min2' - `last'") ("reg") ("gdp_inf_`sector'") (`reg_gdp_inf_`sector'')
		
	}
	
	* Sectoral Productivity-Sectoral Income 
	******************************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui reg log_avg_formal_income_`sector' log_prod_`sector' if year >= `min2' & year <= `last' & country == "`country'"
		loc reg_prod_for_`sector' = _b[log_prod_`sector']
		post `regressions' ("`country'") ("_period2") ("`min2' - `last'") ("reg") ("prod_for_`sector'") (`reg_prod_for_`sector'')
		
		** Informal
		qui reg log_avg_informal_income_`sector' log_prod_`sector' if year >= `min2' & year <= `last' & country == "`country'"
		loc reg_prod_inf_`sector' = _b[log_prod_`sector']
		post `regressions' ("`country'") ("_period2") ("`min2' - `last'") ("reg") ("prod_inf_`sector'") (`reg_prod_inf_`sector'')
		
	}
	
	
	*********************************************************************
	* 2.2.5 - Mean regression + Total GDP
	*********************************************************************
	
	* GDP-Activity
	*****************
	qui reg log_active_population log_gdp if year >= `min2' & year <= `last' & country == "`country'"
	loc reg_gdp_emp_2 = _b[log_gdp]
	post `regressions' ("`country'") ("_period2") ("`min2' - `last'") ("reg_gdp") ("gdp_activity") (`reg_gdp_emp_2')
	
	* Sectoral GDP-Sectoral Workers 
	**********************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui reg log_formal_workers_`sector' log_`sector' log_gdp if year >= `min2' & year <= `last' & country == "`country'"
		loc reg_gdp_for_`sector'_2 = _b[log_`sector']
		post `regressions' ("`country'") ("_period2") ("`min2' - `last'") ("reg_gdp") ("gdp_for_`sector'") (`reg_gdp_for_`sector'_2')
		
		** Informal
		qui reg log_informal_workers_`sector' log_`sector' log_gdp if year >= `min2' & year <= `last' & country == "`country'"
		loc reg_gdp_inf_`sector'_2 = _b[log_`sector']
		post `regressions' ("`country'") ("_period2") ("`min2' - `last'") ("reg_gdp") ("gdp_inf_`sector'") (`reg_gdp_inf_`sector'_2')
		
	}
	
	* Sectoral Productivity-Sectoral Income 
	******************************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui reg log_avg_formal_income_`sector' log_prod_`sector' log_gdp if year >= `min2' & year <= `last' & country == "`country'"
		loc reg_prod_for_`sector'_2 = _b[log_prod_`sector']
		post `regressions' ("`country'") ("_period2") ("`min2' - `last'") ("reg_gdp") ("prod_for_`sector'") (`reg_prod_for_`sector'_2')
		
		** Informal
		qui reg log_avg_informal_income_`sector' log_prod_`sector' log_gdp if year >= `min2' & year <= `last' & country == "`country'"
		loc reg_prod_inf_`sector'_2 = _b[log_prod_`sector']
		post `regressions' ("`country'") ("_period2") ("`min2' - `last'") ("reg_gdp") ("prod_inf_`sector'") (`reg_prod_inf_`sector'_2')
		
	}
	
	
	*********************************************************************
	* 2.2.6 - Mean regression + Total GDP * Informality rate
	*********************************************************************
	
	* GDP-Activity
	*****************
	qui reg log_active_population log_gdp iteration if year >= `min2' & year <= `last' & country == "`country'"
	loc reg_gdp_emp_3 = _b[log_gdp]
	post `regressions' ("`country'") ("_period2") ("`min2' - `last'") ("reg_iter") ("gdp_activity") (`reg_gdp_emp_3')
	
	* Sectoral GDP-Sectoral Workers 
	**********************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui reg log_formal_workers_`sector' log_`sector' iteration if year >= `min2' & year <= `last' & country == "`country'"
		loc reg_gdp_for_`sector'_3 = _b[log_`sector']
		post `regressions' ("`country'") ("_period2") ("`min2' - `last'") ("reg_iter") ("gdp_for_`sector'") (`reg_gdp_for_`sector'_3')
		
		** Informal
		qui reg log_informal_workers_`sector' log_`sector' iteration if year >= `min2' & year <= `last' & country == "`country'"
		loc reg_gdp_inf_`sector'_3 = _b[log_`sector']
		post `regressions' ("`country'") ("_period2") ("`min2' - `last'") ("reg_iter") ("gdp_inf_`sector'") (`reg_gdp_inf_`sector'_3')
		
	}
	
	* Sectoral Productivity-Sectoral Income 
	******************************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui reg log_avg_formal_income_`sector' log_prod_`sector' iteration if year >= `min2' & year <= `last' & country == "`country'"
		loc reg_prod_for_`sector'_3 = _b[log_prod_`sector']
		post `regressions' ("`country'") ("_period2") ("`min2' - `last'") ("reg_iter") ("prod_for_`sector'") (`reg_prod_for_`sector'_3')
		
		** Informal
		qui reg log_avg_informal_income_`sector' log_prod_`sector' iteration if year >= `min2' & year <= `last' & country == "`country'"
		loc reg_prod_inf_`sector'_3 = _b[log_prod_`sector']
		post `regressions' ("`country'") ("_period2") ("`min2' - `last'") ("reg_iter") ("prod_inf_`sector'") (`reg_prod_inf_`sector'_3')
		
	}
	
	
	*********************************************************************
	* 2.3 - Recent year to last year available
	*********************************************************************
	
	di in red "Period `min3' - `last'"
	
	*********************************************************************
	* 2.3.1 - Simple averages
	*********************************************************************
	
	* GDP-Activity
	*****************
	qui sum elas_gdp_emp if year >= `min3' & year <= `last' & country == "`country'"
	loc av_elas_gdp_emp = r(mean)
	post `regressions' ("`country'") ("_period3") ("`min3' - `last'") ("avg") ("gdp_activity") (`av_elas_gdp_emp')
	
	* Sectoral GDP-Sectoral Workers 
	**********************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui sum elas_gdp_for_`sector' if year >= `min3' & year <= `last' & country == "`country'"
		loc avg_elas_gdp_for_`sector' = r(mean)
		post `regressions' ("`country'") ("_period3") ("`min3' - `last'") ("avg") ("gdp_for_`sector'") (`avg_elas_gdp_for_`sector'')
		
		** Informal
		qui sum elas_gdp_inf_`sector' if year >= `min3' & year <= `last' & country == "`country'"
		loc avg_elas_gdp_inf_`sector' = r(mean)
		post `regressions' ("`country'") ("_period3") ("`min3' - `last'") ("avg") ("gdp_inf_`sector'") (`avg_elas_gdp_inf_`sector'')
		
	}
	
	* Sectoral Productivity-Sectoral Income 
	******************************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui sum elas_prod_for_`sector' if year >= `min3' & year <= `last' & country == "`country'"
		loc avg_elas_prod_for_`sector' = r(mean)
		post `regressions' ("`country'") ("_period3") ("`min3' - `last'") ("avg") ("prod_for_`sector'") (`avg_elas_prod_for_`sector'')
		
		** Informal
		qui sum elas_prod_inf_`sector' if year >= `min3' & year <= `last' & country == "`country'"
		loc avg_elas_prod_inf_`sector' = r(mean)
		post `regressions' ("`country'") ("_period3") ("`min3' - `last'") ("avg") ("prod_inf_`sector'") (`avg_elas_prod_inf_`sector'')
		
	}
	
	
	*********************************************************************
	* 2.3.2 - Averages without outliers (1%-99%)
	*********************************************************************
	
	* GDP-Activity
	*****************
	qui sum elas_gdp_emp if year >= `min3' & year <= `last' & country == "`country'", d
	qui replace elas_gdp_emp_1_99 = elas_gdp_emp if year >= `min3' & year <= `last' & country == "`country'" & elas_gdp_emp > r(p1) & elas_gdp_emp < r(p99)
	qui sum elas_gdp_emp_1_99 if year >= `min3' & year <= `last' & country == "`country'"
	loc av_elas_gdp_emp_1_99 = r(mean)
	post `regressions' ("`country'") ("_period3") ("`min3' - `last'") ("avg_1_99") ("gdp_activity") (`av_elas_gdp_emp_1_99')
	
	* Sectoral GDP-Sectoral Workers 
	**********************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui sum elas_gdp_for_`sector' if year >= `min3' & year <= `last' & country == "`country'", d
		qui replace elas_gdp_for_`sector'_1_99 = elas_gdp_for_`sector' if year >= `min3' & year <= `last' & country == "`country'" & elas_gdp_for_`sector' > r(p1) & elas_gdp_for_`sector' < r(p99)
		qui sum elas_gdp_for_`sector'_1_99 if year >= `min3' & year <= `last' & country == "`country'"
		loc avg_elas_gdp_for_`sector'_1_99 = r(mean)
		post `regressions' ("`country'") ("_period3") ("`min3' - `last'") ("avg_1_99") ("gdp_for_`sector'") (`avg_elas_gdp_for_`sector'_1_99')
		
		** Informal
		qui sum elas_gdp_inf_`sector' if year >= `min3' & year <= `last' & country == "`country'", d
		qui replace elas_gdp_inf_`sector'_1_99 = elas_gdp_inf_`sector' if year >= `min3' & year <= `last' & country == "`country'" & elas_gdp_inf_`sector' > r(p1) & elas_gdp_inf_`sector' < r(p99)
		qui sum elas_gdp_inf_`sector'_1_99 if year >= `min3' & year <= `last' & country == "`country'"
		loc avg_elas_gdp_inf_`sector'_1_99 = r(mean)
		post `regressions' ("`country'") ("_period3") ("`min3' - `last'") ("avg_1_99") ("gdp_inf_`sector'") (`avg_elas_gdp_inf_`sector'_1_99')
		
	}
	
	* Sectoral Productivity-Sectoral Income 
	******************************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui sum elas_prod_for_`sector' if year >= `min3' & year <= `last' & country == "`country'", d
		qui replace elas_prod_for_`sector'_1_99 = elas_prod_for_`sector' if year >= `min3' & year <= `last' & country == "`country'" & elas_prod_for_`sector' > r(p1) & elas_prod_for_`sector' < r(p99)
		qui sum elas_prod_for_`sector'_1_99 if year >= `min3' & year <= `last' & country == "`country'"
		loc avg_elas_prod_for_`sector'_1_99 = r(mean)
		post `regressions' ("`country'") ("_period3") ("`min3' - `last'") ("avg_1_99") ("prod_for_`sector'") (`avg_elas_prod_for_`sector'_1_99')
		
		** Informal
		qui sum elas_prod_inf_`sector' if year >= `min3' & year <= `last' & country == "`country'", d
		qui replace elas_prod_inf_`sector'_1_99 = elas_prod_inf_`sector' if year >= `min3' & year <= `last' & country == "`country'" & elas_prod_inf_`sector' > r(p1) & elas_prod_inf_`sector' < r(p99)
		qui sum elas_prod_inf_`sector'_1_99 if year >= `min3' & year <= `last' & country == "`country'"
		loc avg_elas_prod_inf_`sector'_1_99 = r(mean)
		post `regressions' ("`country'") ("_period3") ("`min3' - `last'") ("avg_1_99") ("prod_inf_`sector'") (`avg_elas_prod_inf_`sector'_1_99')
		
	}
	
	
	*********************************************************************
	* 2.3.3 - Averages with imputed outliers (1%-99% using mean)
	*********************************************************************
		
	* GDP-Activity
	*****************
	qui sum elas_gdp_emp_1_99 if year >= `min3' & year <= `last' & country == "`country'", d
	loc av_elas_gdp_emp_1_99 = r(p50)
	qui replace elas_gdp_emp_1_99_imp = elas_gdp_emp_1_99 if year >= `min3' & year <= `last' & country == "`country'"
	qui replace elas_gdp_emp_1_99_imp = `av_elas_gdp_emp_1_99' if elas_gdp_emp_1_99_imp == . & elas_gdp_emp != . & year >= `min3' & year <= `last' & country == "`country'"
	qui sum elas_gdp_emp_1_99_imp if year >= `min3' & year <= `last' & country == "`country'"
	loc av_elas_gdp_emp_1_99_imp = r(mean)
	post `regressions' ("`country'") ("_period3") ("`min3' - `last'") ("avg_1_99_imp") ("gdp_activity") (`av_elas_gdp_emp_1_99_imp')
	
	* Sectoral GDP-Sectoral Workers 
	**********************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui sum elas_gdp_for_`sector'_1_99 if year >= `min3' & year <= `last' & country == "`country'", d
		loc avg_elas_gdp_for_`sector'_1_99 = r(p50)
		qui replace elas_gdp_for_`sector'_1_99_imp = elas_gdp_for_`sector'_1_99 if year >= `min3' & year <= `last' & country == "`country'"
		qui replace elas_gdp_for_`sector'_1_99_imp = `avg_elas_gdp_for_`sector'_1_99' if elas_gdp_for_`sector'_1_99_imp == . & elas_gdp_for_`sector' != . & year >= `min3' & year <= `last' & country == "`country'"
		qui sum elas_gdp_for_`sector'_1_99_imp if year >= `min3' & year <= `last' & country == "`country'"
		loc avg_elas_gdp_for_`sector'_1_99_imp = r(mean)
		post `regressions' ("`country'") ("_period3") ("`min3' - `last'") ("avg_1_99_imp") ("gdp_for_`sector'") (`avg_elas_gdp_for_`sector'_1_99_imp')
		
		** Informal
		qui sum elas_gdp_inf_`sector'_1_99 if year >= `min3' & year <= `last' & country == "`country'", d
		loc avg_elas_gdp_inf_`sector'_1_99 = r(p50)
		qui replace elas_gdp_inf_`sector'_1_99_imp = elas_gdp_inf_`sector'_1_99 if year >= `min3' & year <= `last' & country == "`country'"
		qui replace elas_gdp_inf_`sector'_1_99_imp = `avg_elas_gdp_inf_`sector'_1_99' if elas_gdp_inf_`sector'_1_99_imp == . & elas_gdp_inf_`sector' != . & year >= `min3' & year <= `last' & country == "`country'"
		qui sum elas_gdp_inf_`sector'_1_99_imp if year >= `min3' & year <= `last' & country == "`country'"
		loc avg_elas_gdp_inf_`sector'_1_99_imp = r(mean)
		post `regressions' ("`country'") ("_period3") ("`min3' - `last'") ("avg_1_99_imp") ("gdp_inf_`sector'") (`avg_elas_gdp_inf_`sector'_1_99_imp')
		
	}
	
	* Sectoral Productivity-Sectoral Income 
	******************************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui sum elas_prod_for_`sector'_1_99 if year >= `min3' & year <= `last' & country == "`country'", d
		loc avg_elas_prod_for_`sector'_1_99 = r(p50)
		qui replace elas_prod_for_`sector'_1_99_imp = elas_prod_for_`sector'_1_99 if year >= `min3' & year <= `last' & country == "`country'"
		qui replace elas_prod_for_`sector'_1_99_imp = `avg_elas_prod_for_`sector'_1_99' if elas_prod_for_`sector'_1_99_imp == . & elas_prod_for_`sector' != . & year >= `min3' & year <= `last' & country == "`country'"
		qui sum elas_prod_for_`sector'_1_99_imp if year >= `min3' & year <= `last' & country == "`country'"
		loc avg_elas_prod_for_`sector'_1_99_imp = r(mean)
		post `regressions' ("`country'") ("_period3") ("`min3' - `last'") ("avg_1_99_imp") ("prod_for_`sector'") (`avg_elas_prod_for_`sector'_1_99')
		
		** Informal
		qui sum elas_prod_inf_`sector'_1_99 if year >= `min3' & year <= `last' & country == "`country'", d
		loc avg_elas_prod_inf_`sector'_1_99 = r(p50)
		qui replace elas_prod_inf_`sector'_1_99_imp = elas_prod_inf_`sector'_1_99 if year >= `min3' & year <= `last' & country == "`country'"
		qui replace elas_prod_inf_`sector'_1_99_imp = `avg_elas_prod_inf_`sector'_1_99' if elas_prod_inf_`sector'_1_99_imp == . & elas_prod_inf_`sector' != . & year >= `min3' & year <= `last' & country == "`country'"
		qui sum elas_prod_inf_`sector'_1_99_imp if year >= `min3' & year <= `last' & country == "`country'"
		loc avg_elas_prod_inf_`sector'_1_99_imp = r(mean)
		post `regressions' ("`country'") ("_period3") ("`min3' - `last'") ("avg_1_99_imp") ("prod_inf_`sector'") (`avg_elas_prod_inf_`sector'_1_99_imp')
		
	}
	
	
	*********************************************************************
	* 2.3.4 - Mean regression
	*********************************************************************
	
	* GDP-Activity
	*****************
	qui reg log_active_population log_gdp if year >= `min3' & year <= `last' & country == "`country'"
	loc reg_gdp_emp = _b[log_gdp]
	post `regressions' ("`country'") ("_period3") ("`min3' - `last'") ("reg") ("gdp_activity") (`reg_gdp_emp')
	
	* Sectoral GDP-Sectoral Workers 
	**********************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui reg log_formal_workers_`sector' log_`sector' if year >= `min3' & year <= `last' & country == "`country'"
		loc reg_gdp_for_`sector' = _b[log_`sector']
		post `regressions' ("`country'") ("_period3") ("`min3' - `last'") ("reg") ("gdp_for_`sector'") (`reg_gdp_for_`sector'')
		
		** Informal
		qui reg log_informal_workers_`sector' log_`sector' if year >= `min3' & year <= `last' & country == "`country'"
		loc reg_gdp_inf_`sector' = _b[log_`sector']
		post `regressions' ("`country'") ("_period3") ("`min3' - `last'") ("reg") ("gdp_inf_`sector'") (`reg_gdp_inf_`sector'')
		
	}
	
	* Sectoral Productivity-Sectoral Income 
	******************************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui reg log_avg_formal_income_`sector' log_prod_`sector' if year >= `min3' & year <= `last' & country == "`country'"
		loc reg_prod_for_`sector' = _b[log_prod_`sector']
		post `regressions' ("`country'") ("_period3") ("`min3' - `last'") ("reg") ("prod_for_`sector'") (`reg_prod_for_`sector'')
		
		** Informal
		qui reg log_avg_informal_income_`sector' log_prod_`sector' if year >= `min3' & year <= `last' & country == "`country'"
		loc reg_prod_inf_`sector' = _b[log_prod_`sector']
		post `regressions' ("`country'") ("_period3") ("`min3' - `last'") ("reg") ("prod_inf_`sector'") (`reg_prod_inf_`sector'')
		
	}
	
	
	*********************************************************************
	* 2.3.5 - Mean regression + Total GDP
	*********************************************************************
	
	* GDP-Activity
	*****************
	qui reg log_active_population log_gdp if year >= `min3' & year <= `last' & country == "`country'"
	loc reg_gdp_emp_2 = _b[log_gdp]
	post `regressions' ("`country'") ("_period3") ("`min3' - `last'") ("reg_gdp") ("gdp_activity") (`reg_gdp_emp_2')
	
	* Sectoral GDP-Sectoral Workers 
	**********************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui reg log_formal_workers_`sector' log_`sector' log_gdp if year >= `min3' & year <= `last' & country == "`country'"
		loc reg_gdp_for_`sector'_2 = _b[log_`sector']
		post `regressions' ("`country'") ("_period3") ("`min3' - `last'") ("reg_gdp") ("gdp_for_`sector'") (`reg_gdp_for_`sector'_2')
		
		** Informal
		qui reg log_informal_workers_`sector' log_`sector' log_gdp if year >= `min3' & year <= `last' & country == "`country'"
		loc reg_gdp_inf_`sector'_2 = _b[log_`sector']
		post `regressions' ("`country'") ("_period3") ("`min3' - `last'") ("reg_gdp") ("gdp_inf_`sector'") (`reg_gdp_inf_`sector'_2')
		
	}
	
	* Sectoral Productivity-Sectoral Income 
	******************************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui reg log_avg_formal_income_`sector' log_prod_`sector' log_gdp if year >= `min3' & year <= `last' & country == "`country'"
		loc reg_prod_for_`sector'_2 = _b[log_prod_`sector']
		post `regressions' ("`country'") ("_period3") ("`min3' - `last'") ("reg_gdp") ("prod_for_`sector'") (`reg_prod_for_`sector'_2')
		
		** Informal
		qui reg log_avg_informal_income_`sector' log_prod_`sector' log_gdp if year >= `min3' & year <= `last' & country == "`country'"
		loc reg_prod_inf_`sector'_2 = _b[log_prod_`sector']
		post `regressions' ("`country'") ("_period3") ("`min3' - `last'") ("reg_gdp") ("prod_inf_`sector'") (`reg_prod_inf_`sector'_2')
		
	}
	
	
	*********************************************************************
	* 2.3.6 - Mean regression + Total GDP * Informality rate
	*********************************************************************
	
	* GDP-Activity
	*****************
	qui reg log_active_population log_gdp iteration if year >= `min3' & year <= `last' & country == "`country'"
	loc reg_gdp_emp_3 = _b[log_gdp]
	post `regressions' ("`country'") ("_period3") ("`min3' - `last'") ("reg_iter") ("gdp_activity") (`reg_gdp_emp_3')
	
	* Sectoral GDP-Sectoral Workers 
	**********************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui reg log_formal_workers_`sector' log_`sector' iteration if year >= `min3' & year <= `last' & country == "`country'"
		loc reg_gdp_for_`sector'_3 = _b[log_`sector']
		post `regressions' ("`country'") ("_period3") ("`min3' - `last'") ("reg_iter") ("gdp_for_`sector'") (`reg_gdp_for_`sector'_3')
		
		** Informal
		qui reg log_informal_workers_`sector' log_`sector' iteration if year >= `min3' & year <= `last' & country == "`country'"
		loc reg_gdp_inf_`sector'_3 = _b[log_`sector']
		post `regressions' ("`country'") ("_period3") ("`min3' - `last'") ("reg_iter") ("gdp_inf_`sector'") (`reg_gdp_inf_`sector'_3')
		
	}
	
	* Sectoral Productivity-Sectoral Income 
	******************************************
	local sectors "agri ind serv"
	foreach sector of local sectors {
		
		** Formal
		qui reg log_avg_formal_income_`sector' log_prod_`sector' iteration if year >= `min3' & year <= `last' & country == "`country'"
		loc reg_prod_for_`sector'_3 = _b[log_prod_`sector']
		post `regressions' ("`country'") ("_period3") ("`min3' - `last'") ("reg_iter") ("prod_for_`sector'") (`reg_prod_for_`sector'_3')
		
		** Informal
		qui reg log_avg_informal_income_`sector' log_prod_`sector' iteration if year >= `min3' & year <= `last' & country == "`country'"
		loc reg_prod_inf_`sector'_3 = _b[log_prod_`sector']
		post `regressions' ("`country'") ("_period3") ("`min3' - `last'") ("reg_iter") ("prod_inf_`sector'") (`reg_prod_inf_`sector'_3')
		
	}
	
	
}

postclose `regressions'
use `aux', clear
compress

replace Period = "Long" if Period == "_period1"
replace Period = "Middle" if Period == "_period2"
replace Period = "Short" if Period == "_period3"

sort Country Period Year Model Elasticity
save "Elasticities.dta", replace
save "inputs_version_control\Elasticities_${version}.dta", replace
export excel using "$path_mpo\input_MASTER.xlsx", sheet("Elasticities") sheetreplace firstrow(variables)
export excel using "$path_share\input_MASTER.xlsx", sheet("Elasticities") sheetreplace firstrow(variables)

