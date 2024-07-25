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

* average labor incomes
import excel using "$inputs", sheet("input_labor_incomes") first clear    //input_gdp2
mkmat rate, mat(growth_labor_income)

* macro data
import excel using "$inputs", sheet("input_gdp") first clear
mkmat rate, mat(growth_macro_data)

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

