*=============================================================================
* TITLE: 03 - Modelling labor status by education skills 
*=============================================================================
* Prepared by: Sergio Olivieri
* E-mail: solivieri@worldbank.org
*=============================================================================
* Created on : Mar 17, 2020
* Last update: Jan 27, 2022 Kelly Y. Montoya
* Last update: March 22 - Cicero Braga (region dummies)
*			   Mar 31, 2022 Included region for ECU (KM)
*			   Apr 19, 2022 Included estimations saving for post-estimation (KM)
*			   Feb 17, 2023 Changed region set up (KM)
*=============================================================================

*=============================================================================
* independet variables
*=============================================================================

encode subnatid1, gen(region)


loc mnl_rhs           c.age##c.age urban ib0.male#ibn.h_head#ib0.married
loc mnl_rhs `mnl_rhs' remitt_any depen oth_pub ib0.male#ibn.educ_lev atschool
loc mnl_rhs `mnl_rhs' ib1.region

* skill levels
levelsof skill, loc(numb_skills)

foreach skill of numlist `numb_skills' {

	sum occupation if skill == `skill' 
	loc base = r(min)
    	
	* Parameters
	*if "$use_saved_parameters" == "no" {
		mlogit occupation `mnl_rhs'  [pw = wgt] if skill == `skill' & sample ==1, baseoutcome(`base')
		/*capture mkdir "${data}\models/${country}_${year}"
		estimates save "${data}\models/${country}_${year}\Status_skill_`skill'.dta", replace
	}
	else {
		estimates use "${data}\models/${country}_${year}\Status_skill_`skill'.dta"
		estimates esample: occupation `mnl_rhs' [aw = pondera] if
       skill == `skill' & sample ==1, baseoutcome(`base')

	}*/

	*=========================================================================
	* residuals
	*=========================================================================
	
	levelsof occupation if skill == `skill', local(occ_cat) 
	loc rvarlist
	
	foreach sect of numlist `occ_cat' {
	loc rvarlist "`rvarlist' U`sect'_`skill'"
	}
	
	set seed 23081985
	simchoiceres `rvarlist' if skill == `skill', total
}

*=============================================================================
*										END
*=============================================================================
