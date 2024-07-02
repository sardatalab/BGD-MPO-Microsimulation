*===========================================================================
* TITLE: 05 - Population Growth
*===========================================================================
* Prepared by: Sergio Olivieri
* E-mail: solivieri@worldbank.org
*===========================================================================
* Created on : Mar 17, 2020
* Last update: Jan 05, 2021
*===========================================================================
* Modified by: Kelly Y. Montoya
*				Jul 25, 2022 - Adjusted fexp_s according to WDI population.
*===========================================================================
loc prior_wgt "wgt"
loc nw_name   "all"

*===========================================================================
* household ID (numeric) = psu + household   
*sort psu id, stable
*egen psuhid = group(psu id)



if $weights == 1 {
*===========================================================================
* 1. dummies for category
*===========================================================================
* dummies by cross categories "gender and age groups"
gen     age_groups =  .
replace age_groups =  1 if age >=  0 & age <=  14
replace age_groups =  2 if age >= 15 & age <=  29
replace age_groups =  3 if age >= 30 & age <=  44
replace age_groups =  4 if age >= 45 & age <=  64
replace age_groups =  5 if age >= 65 

egen int groupvar = group(male age_groups) 
xi i.groupvar, noomit prefix(_by)
unab caliblist: _by*


loc mem_rel   "h_head"
loc byvars    "male age_groups"
loc hhd_id    "hhid"
loc prior_wgt "wgt"
loc nw_name   "all"

*===========================================================================
* 2. means by category and total population in base year
*===========================================================================
total `caliblist' [pw = `prior_wgt'] 
mat  tot_old = e(b)

* share by groups
sum `prior_wgt' if e(sample), meanonly 
scalar  total_`nw_name' = r(sum)
mat mean_old = tot_old / r(sum)
mat mean_old = mean_old'

* add n-1 restrictions
mata: st_matrix("tot_new", st_matrix("tot_old"):*st_matrix("vec_pop_grw1")')
mata: st_matrix("mean_`nw_name'",st_matrix("tot_new")'/sum(st_matrix("tot_new")))
mata: st_local("totalnew",strofreal(sum(st_matrix("tot_new")),"%20.5f"))
mata: st_numscalar("TN1",sum(st_matrix("tot_new")))
mat mean_`nw_name'c = mean_`nw_name'[2...,1]

*===========================================================================
* 3. constrains
*===========================================================================
capture drop sort
gsort `hhd_id' -`mem_rel'
gen long sort = _n 
bysort `hhd_id' (sort): gen byte _first = (_n == 1) 


capture drop aux
gen aux = 1 
egen _hhsize = sum(aux), by(`hhd_id')


* I use this expression in case individuals have different weights in the household
* Within the household
bysort `hhd_id' (sort): gen double _sumw_`nw_name' = sum(`prior_wgt')    
bysort `hhd_id' (sort): replace    _sumw_`nw_name' = _sumw_`nw_name'[_N] 

foreach x of varlist `caliblist' {
    bysort `hhd_id' (sort): gen double m_`nw_name'_`x' = sum(`x' * `prior_wgt' ) 
    bysort `hhd_id' (sort): replace    m_`nw_name'_`x' = m_all_`x'[_N]/_sumw_`nw_name'
	loc recaliblist `recaliblist' m_`nw_name'_`x'
}

* add n-1 restrictions
loc first: word 1 of `recaliblist'
loc recaliblist: list recaliblist - first
mat rownames mean_`nw_name'c = `recaliblist'

loc nw_name = "all"
loc mem_rel  "h_head"
tempvar factor_`nw_name'
loc varlist: rownames(mean_`nw_name'c)
mata: st_local("totalnew",strofreal(sum(st_matrix("tot_new")),"%20.5f"))

noi di "maxentropy `varlist' if `mem_rel' == 1, matrix(mean_`nw_name'c) prior(`prior_wgt') generate(`factor_`nw_name'') total(`totalnew')"
maxentropy `varlist' if `mem_rel' == 1, matrix(mean_`nw_name'c) prior(`prior_wgt') generate(`factor_`nw_name'') total(`totalnew')

bysort `hhd_id' (sort): gen `nw_name'_wgt = `prior_wgt' * `factor_`nw_name''[1]/_sumw_`nw_name'
la var `nw_name'_wgt "Simulated `nw_name' weights"

drop aux* psuhid groupvar age_groups

//gen fexp_s = fexp
//label var fexp_s "weight -$scenario"

rename  all_wgt fexp_s 


}


if $weights == 0 {
    
	sum wgt [w = wgt]
	sca var0 = r(sum_w)
	sca var1 = growth_pop_wdi[1,1]
	sca ratio_pop = var1/var0
	gen fexp_s = round(`prior_wgt'* ratio_pop)
	
	* Check
	sum fexp_s [w = fexp_s]
	if abs(r(sum_w) - growth_pop_wdi[1,1]) > 1000000 di in red "WARNING: Population differs in more than a million people with WDI."
	
	
	* Another way to adjust but keeping all decimal positions.
	/*sum fexp_s [w = fexp_s]
	if abs(r(sum_w) - growth_pop_wdi[1,1]) != 0 {
	    sum fexp_s [w = fexp_s]
		sca var0 = r(sum_w) - growth_pop_wdi[1,1]
		sca var1 = growth_pop_wdi[1,1]
		sca ratio_pop = var0/var1
		replace fexp_s = fexp_s * (1 + ratio_pop)
	}*/

}

*===========================================================================
*                                     END
*===========================================================================
