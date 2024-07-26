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
gl model = model[1]
tostring model, replace

* bonus
if inlist(bonus,1) gl bonus = 1
if inlist(bonus,0) gl bonus = 0 

* sectors (by default 6 sectors)
gl m = num_sectors[1]

* new weights
if inlist(weights,1) gl weights = 1
if inlist(weights,0) gl weights = 0

* macro data
import excel using "$inputs", sheet("input_gdp") first clear

* macro data from simulation file
	use dateid bgdnv* using "$data_in/Macro and elasticities/bgd - spring meetings 2024 - pov - corrected pop 2.dta", clear
	gen year = yofd(dateid)
	drop dateid
	foreach var of varlist bgd* {
		local nname = substr("`var'",4,60)
		rename `var' `nname'
	}
	
	gen double nvindrestkn = (nvindtotlkn - nvindconskn)
	gen double nvsrvrestkn = (nvsrvtotlkn - nvsrvtrnskn - nvsrvfinakn)
	
	keep  year nvagrtotlkn nvindconskn nvindrestkn nvsrvtrnskn nvsrvfinakn nvsrvrestkn
	order year nvagrtotlkn nvindconskn nvindrestkn nvsrvtrnskn nvsrvfinakn nvsrvrestkn
	
	egen double nvgdptotlkn = rsum(nvagrtotlkn nvindconskn nvindrestkn nvsrvtrnskn nvsrvfinakn nvsrvrestkn)
	
	tsset year, yearly
	
	foreach var of varlist nv*kn {
		sum `var' if year==$base_year
		local b`var' = r(mean)
		gen double lav`var' = `var'/`b`var''-1
	}
	
	keep if year == $sim_year
	keep year lav*
	reshape long lav, i(year) j(sector) string
	rename lav rate
	rename sector strsector	
	
	gen sector = .
	replace sector = 1 if strsector=="nvagrtotlkn"
	replace sector = 2 if strsector=="nvindrestkn"
	replace sector = 3 if strsector=="nvindconskn"
	replace sector = 4 if strsector=="nvsrvrestkn"
	replace sector = 5 if strsector=="nvsrvtrnskn"
	replace sector = 6 if strsector=="nvsrvfinakn"
									  
	replace sector = 7 if strsector=="nvgdptotlkn"
	
	#delimit ;
	label define lblsector
	1 "gdp_agric"
	2 "gdp_ind"
	3 "gdp_cons"
	4 "gdp_serv"
	5 "gdp_transp"
	6 "gdp_fin"
	7 "gdp";
	#delimit cr
	label values sector lblsector
	drop strsector
	order year sector
	sort year sector
	
mkmat rate, mat(growth_macro_data)

* average labor incomes
import excel using "$inputs", sheet("input_labor_incomes") first clear    //input_gdp2
mkmat rate, mat(growth_labor_income)

* labor market
import excel using "$inputs", sheet("input_labor") first clear
mkmat rate, mat(growth_labor)

* non-labor incomes
import excel using "$inputs", sheet("input_nonlabor") first clear
mkmat rate, mat(growth_nlabor)

* total population
import excel using "$inputs", sheet("input_pop_wdi") first clear
mkmat value, mat(growth_pop_wdi)


restore

*===========================================================================
*                                     END
*===========================================================================

