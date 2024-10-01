*!v1.0
*=============================================================================
* TITLE: 07 - Simulating changes in the unemployment rate
*===========================================================================
* Prepared by: Sergio Olivieri
* E-mail: solivieri@worldbank.org
*=============================================================================
* Created on : Mar 17, 2020
* Last update: Jan 04, 2021
*			   Aug 09, 2022 Kelly Y. Montoya minor corrections and warnings.
*=============================================================================

*=============================================================================

* sample unemployment rate 
gen     aux = unemplyd / lf_samp 
sum aux [w = wgt] if lf_samp == 1
* goal
mat unemploy = r(mean)*(1 + growth_labor[2,1])
mat list unemploy

* allocate individuals according to their probability of being unemployed
*gen    unemplyd_s = unemplyd  if active_s == 1
clonevar unemplyd_s = unemplyd
clonevar U10 = U10_1 
replace  U10 = U10_2 if U10 == .
gsort -unemplyd_s U10 id 
cap drop aux*

qui sum fexp_s			            if active_s == 1 
gen double aux = sum(fexp_s)/r(sum) if active_s == 1 

replace unemplyd_s = 1			    if aux <= (unemploy[1,1] + epsfloat()) & active_s == 1 
replace unemplyd_s = 0			    if aux >  (unemploy[1,1] + epsfloat()) & active_s == 1 

* simulating: employment status
*gen     emplyd_s = emplyd  if active_s  == 1
clonevar emplyd_s = emplyd
replace emplyd_s = 1       if unemplyd_s == 0 & active_s == 1
replace emplyd_s = 0       if unemplyd_s == 1 & active_s == 1
tab emplyd_s active_s

* check 
capt drop aux
gen     aux = unemplyd / lf_samp 
sum aux [w = wgt] if lf_samp == 1 
scalar v0 = r(mean)

cap drop aux
gen     aux = unemplyd_s / active_s 
sum aux [w = fexp_s] if active_s == 1 
scalar v1 = r(mean)

di scalar(v1)/scalar(v0)-1
mat list growth_labor

if abs( round((scalar(v1)/scalar(v0)-1),.005) - round(growth_labor[2,1],.005) ) != 0 {
	di in red "WARNING: New active population doesn´t match growth rate."
	break
}

drop aux*
*=============================================================================
*                                     END
*=============================================================================
