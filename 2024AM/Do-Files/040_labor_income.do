*!v1.0
*=============================================================================
* TITLE: 04 - Modeling labor incomes by education skills and economic sector
*===========================================================================
* Prepared by: Sergio Olivieri
* E-mail: solivieri@worldbank.org
*=============================================================================
* Created on : Mar 17, 2020
* Last update: Jan 08, 2021
* 			   Apr 19, 2022 - Included estimations saving (Kelly Y. Montoya)
*			   Jul 25, 2022 - Change loc numsector (only 3 sectors). KYM
*=============================================================================

*=============================================================================

* y vars 
loc depvar "ln_lai_m"

* x vars 
loc ols_rhs           c.age##c.age urban ib0.male##ib0.h_head
loc ols_rhs `ols_rhs' ib0.male#ibn.educ_lev salaried public_job
loc ols_rhs `ols_rhs' ib1.region

levelsof sect_main , loc(numb_sectors)
levelsof skill, loc(numb_skills)

foreach sector of numlist `numb_sectors' {

	foreach skill of numlist `numb_skills' {
	
		* Parameters
		if "$use_saved_parameters" == "no" {
			regress `depvar' `ols_rhs' [pw = wgt] if sect_main == `sector' & skill == `skill'   & sample == 1
			estimates save "${data_root}/models/${country}_${year}/Income_sector_`sector'_skill_`skill'.dta", replace
		}
		else {
			estimates use "${data_root}/models/${country}_${year}\Income_sector_`sector'_skill_`skill'.dta"
			estimates esample: `depvar' `ols_rhs' [pw = pondera] if `numsector' == `sector' & skill == `skill'   & sample==1
		}
	
		mat b_`sector'_`skill' = e(b)
		scalar sigma_`sector'_`skill' = e(rmse)	 
	}
}

*=============================================================================
*                                     END
*=============================================================================
