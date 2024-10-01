*!v1.0
*===========================================================================
* TITLE: Set up parameters
*===========================================================================
* Prepared by: Sergio Olivieri
* E-mail: solivieri@worldbank.org
*===========================================================================
* Created on : Dec 03, 2020
* Last update: Jun 26, 2024 - Israel Osorio Rodarte
*			   Jan 04, 2021 Kelly Y. Montoya
*			   Jan 13, 2021 - Modification of average labor income sheet
*			   Jul 22, 2022 - Added macro data matrix for re-scaling with sectoral and total GDP in the new model
*			   Jul 25, 2022 - Added WDI population matrix for new weights
*			   Jul 26, 2022 - Moved model set up from master. Muted population by gender.
*===========================================================================

*===========================================================================
* setting up the model
*===========================================================================


* mata matrix
mata:
void st_shares(string scalar name1)
{
	real matrix M,N,P
	M = st_matrix(name1)
    N = runningsum(M[1..(rows(M)-1),1])
    P = N:/M[rows(M),1]
    st_matrix("shr",P)
}
end


*===========================================================================
* general parameters
*===========================================================================

preserve

import excel using "$inputs", sheet("input_setup") first clear

* type of estimation
gl national   = type_estimation[1]
if $national == 1 gl tipo "local"
if $national == 0 gl tipo "inter"  

* select scenario
*gl model = model[1]
*tostring model, replace

* bonus
if inlist(bonus,1) gl bonus = 1
if inlist(bonus,0) gl bonus = 0 

* sectors (by default 6 sectors)
gl m = num_sectors[1]

* new weights
if inlist(weights,1) gl weights = 1
if inlist(weights,0) gl weights = 0

* Read LAV sheet from Excel Input File
import excel using "$inputs", sheet("linkage_aggregate_variables") first clear    // previously called resumen
	keep parameters value* lav*
	drop if parameters==""
	reshape long value lav, i(parameters) j(year)
	keep if year==$sim_year
	rename lav rate
	tempfile lavdata
save `lavdata', replace

* macro data (See sheet "input_gpd")
use `lavdata', clear
	keep if substr(parameters,1,3)=="gdp"
	sort parameters
mkmat rate, mat(growth_macro_data)

* average labor incomes (See sheet "input_labor_incomes")
use `lavdata', clear
	keep if substr(parameters,1,3)=="inc"
	gen A = substr(parameters,length(parameters)-1,2)
	replace A = "z0" if A=="A0"	// To place it at the bottom
	sort A parameters
mkmat rate, mat(growth_labor_income)

* labor market (See sheet "input_labor")
use `lavdata', clear
	keep if substr(parameters,1,2)=="sh"|parameters=="parti_rate"|parameters=="unemp_rate"
	gen A = "A0"
	replace A = substr(parameters,length(parameters)-1,2) if substr(parameters,1,2)=="sh"
	sort A parameters
mkmat rate, mat(growth_labor)

* non-labor incomes (See sheet "input_nonlabor")
use `lavdata', clear
	gen order = . 
	replace order = 1 if parameter=="remittances"
	replace order = 2 if parameter=="pensions"
	replace order = 3 if parameter=="capital"
	replace order = 4 if parameter=="bdh"
	replace order = 5 if parameter=="jgl"
	keep if order!=.
	sort order
mkmat rate, mat(growth_nlabor)

* total population (See sheet "input_pop_wdi")
use `lavdata', clear
	keep if parameter=="total population"
mkmat value, mat(growth_pop_wdi)
*Alternatively, for using the growth rate:
*mkmat rate, mat(growth_pop_wdi)

* GDP Per Capita
use `lavdata', clear
	keep if parameter=="pccons"
mkmat rate, mat(pccons)

restore

*===========================================================================
*                                     END
*===========================================================================

