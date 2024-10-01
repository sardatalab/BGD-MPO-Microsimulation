*!v1.0
*=============================================================================
* TITLE: 14 - Household consumption
*===========================================================================
* Prepared by: Israel Osorio-Rodarte
* E-mail: iosoriorodarte@worldbank.org
*=============================================================================
* Created on : Sep 06, 2024
* Last update: Sep 06, 2024
*=============================================================================
* Modified by: 
* Modification: 
*=============================================================================


* Generate original welfare aggregate
	gen double welfare_ppp17 = ((12/365)*welfarenat/cpi2017/icp2017)

* Quintiles at the national level
	xtile ntiles = welfare_ppp17 [w=wgt], nq(5)

* Variables head, and age of househhold head
	gen head = (relationharm==1)
	gen _agehead = age if head==1
	bys idh: egen agehead = median(_agehead)
	drop _agehead

* Income to consumption ratio (original)
	gen double ratio_orig = (ipcf_ppp17/welfare_ppp17)
	
* Impute missing values for male - there shouldn't be any missing values in independent vars
	replace male = 0 if male==.	
	
* Fix educy - there shouldn't be any missing values in independent vars
	replace educy = 0 if educy==.	
	
* Classifying househhold into 4 different cases for changes in per capita income
	gen case = .

	replace case = 			1 if (ipcf_ppp17> 0 & ipcf_ppp17!=.) & (pc_inc_s> 0 & pc_inc_s!=.)	// Remained with positive income
	replace case = 			2 if (ipcf_ppp17==0                ) & (pc_inc_s==0              )	// Remained with zero income
	replace case = 			3 if (ipcf_ppp17==0                ) & (pc_inc_s> 0 & pc_inc_s!=.)	// Turned to positive income
	replace case = 			4 if (ipcf_ppp17> 0 & ipcf_ppp17!=.) & (pc_inc_s==0              )	// Turned to income equal to zero
	
	label define lblcase 1 "Case 1: X>0, X'>0, Y>0 -> Y'=Y(X'/X)", add
	label define lblcase 2 "Case 2: X=0, X'=0, Y>0 -> Y'=Y", add
	label define lblcase 3 "Case 3: X=0, X'>0, Y>0 -> Y'= n.n.f(determinants|Y'>Y)", add
	label define lblcase 4 "Case 4: X>0, X'=0, Y>0 -> Y'= n.n.f(determinants|Y'<Y)", add	
	label values case lblcase
	
	gen double nwf = . 
	label var nwf "New Welfare at household head level (bridge)"
	
* Treatment for Case 1: Passthough changes in per capita income to per capita consumption
	*replace nwf = welfare_ppp17 * (pc_inc_s/ipcf_ppp17)  if case==1	
	
* Treatment for Case 2: Since initial and final per capita income are zero, household will continue with
*					   the same per capita consumption
	replace nwf = welfare_ppp17 if case==2
	
* Treatement for Case 3: Household will be matched with the most similar household considering a higher per capita consumption
	gen byte case3_treated = .
	replace  case3_treated = 0 if (ipcf_ppp17> 0 & ipcf_ppp17!=.) 								// Not treated: Households with initial positive income
	replace  case3_treated = 1 if (ipcf_ppp17==0                ) & (pc_inc_s> 0 & pc_inc_s!=.)	// Treated: Households that turned to positive income

* Treatement for Case 4. Household will be matched with the most similar household considering a lower per capita consumption
	gen byte case4_treated = .
	replace  case4_treated = 0 if (ipcf_ppp17==0 | (ipcf_ppp17>0 & ipcf_ppp17!=.)) 				// Not treated: Households with initial with zero income
	replace  case4_treated = 1 if (ipcf_ppp17> 0 & ipcf_ppp17!=.) & (pc_inc_s==0              )	// Trated: Households that turned to income equal to zero
	
* Case 1
	error 1
	clonevar pc_inc_match = pc_inc_s
	
	local vars_match "age hsize pc_inc_match"
	local vars_group "region ntile urban"
	
	frame put ratio_orig `vars_match' `vars_gropu' if case==1 & hhead==1 into(matreceiver)
	
	
* Case 3
	sort idh idp

	psmatch2 case3_treated agehead male own hsize educy i.urban i.ntiles if head==1 & case3_treated!=., neighbor(1) noreplacement
	
	levelsof _id if _treated==1, local(allids)	
	
	foreach id of local allids {
		
		noi di "`id'"
		sum _pscore if _id==`id'
			scalar ps`id' = r(mean)
		sum welfare_ppp17 if _id==`id'
			scalar wf`id' = r(mean)
		
		gen double _psd`id' = abs(_pscore - ps`id') if _treated==0 & welfare_ppp17>wf`id'
			sum _psd`id'
			scalar mind`id' = r(min)
		count if _psd`id' == mind`id'
		
		if r(N)==0 {
			noi di "No matching for `id'. Error"
			error 1
		}
		if r(N)==1 {
			sum welfare_ppp17 if _psd`id'==mind`id'
			replace nwf = r(mean) if _id==`id'
		}
		if r(N)> 1 & r(N)!=. {
			noi di "Select one, randomly"
			gen _rd = runiform() if _psd`id' == mind`id'
			sum _rd
				sum welfare_ppp17 if _rd == r(min)	
				replace nwf = r(mean) if _id==`id'
			drop _rd
		}
		
		drop _psd`id'
	}

	drop _pscore _treated _support _weight _id _n1 _nn _pdif
	
		
* Case 4 - Turning into zero income

	sort idh idp	
	* Using a restricted sample may overshoot the regression
	*psmatch2 case4_treated agehead hsize educy if head==1 & case4_treated!=., neighbor(1) noreplacement
	
	psmatch2 case4_treated agehead male own hsize educy i.urban i.ntiles if head==1 & case4_treated!=., neighbor(1) noreplacement
	
	levelsof _id if _treated==1, local(allids)	
	
	foreach id of local allids {
		
		noi di "`id'"
		sum _pscore if _id==`id'
			scalar ps`id' = r(mean)
		sum welfare_ppp17 if _id==`id'
			scalar wf`id' = r(mean)
		
		gen double _psd`id' = abs(_pscore - ps`id') if _treated==0 & welfare_ppp17<wf`id'
			sum _psd`id'
			scalar mind`id' = r(min)
		count if _psd`id' == mind`id'
		
		if r(N)==0 {
			noi di "No matching for `id'. Error"
			error 1
		}
		if r(N)==1 {
			sum welfare_ppp17 if _psd`id'==mind`id'
			replace nwf = r(mean) if _id==`id'
		}
		if r(N)> 1 & r(N)!=. {
			noi di "Select one, randomly"
			gen _rd = runiform() if _psd`id' == mind`id'
			sum _rd
				sum welfare_ppp17 if _rd == r(min)	
				replace nwf = r(mean) if _id==`id'
			drop _rd
		}
		
		drop _psd`id'
	}

	drop _pscore  _support _weight _id _n1 _nn _pdif
	bys idh: egen pc_con_s = mean(nwf)
	
	* Re-scale according to growth in private consumption per capita
	sum welfare_ppp17 [w=wgt]
		scalar pcconsbase = r(mean)
		
	sum pc_con_s [w=wgt]
		scalar pccons_int = r(mean)
	
	scalar objective_pccons = pccons[1,1]+1
	
	rename pc_con_s pc_con_preadj
	
	gen double pc_con_s = pc_con_preadj / (objective_pccons * (pccons_int/pcconsbase))
	label var pc_con_s "Final Per Capita Household Consumption"
	
	
*=============================================================================
*                                     END
*=============================================================================

	
	