*!v1.0
*=============================================================================
* TITLE: 14 - Household consumption
*===========================================================================
* Prepared by: Israel Osorio-Rodarte
* E-mail: iosoriorodarte@worldbank.org
*=============================================================================
* Created on : Oct 04, 2024
* Last update: Sep 06, 2024
*=============================================================================
* Modified by: 
* Modification: 
*=============================================================================
* Declare global for doint psmatch
* Option "no" would do a simple 1-to-1 income to consumption passthrough
global do_psmatch "yes"


* Generate original welfare aggregate
	gen double welfare_ppp17 = ((12/365)*welfarenat/cpi2017/icp2017)

********************************************************************************
* This is a simple case of a 1-to-1 income to consumption passthrough
********************************************************************************
if "$do_psmatch"=="no" {
	gen double pc_con_s = .
	replace pc_con_s = welfare_ppp17 * (pc_inc_s/ipcf_ppp17) if pc_inc_s!=0 & ipcf_ppp17!=0
	replace pc_con_s = welfare_ppp17 * (pc_inc_s/ipcf_ppp17) if pc_inc_s==0 & ipcf_ppp17!=0
	replace pc_con_s = welfare_ppp17                         if pc_inc_s!=0 & ipcf_ppp17==0
	replace pc_con_s = welfare_ppp17                         if pc_inc_s==0 & ipcf_ppp17==0
}

********************************************************************************
* This is a more match between similar households
********************************************************************************
if "$do_psmatch"=="yes" {
	* Quintiles at the national level
		xtile ntiles = welfare_ppp17 [w=wgt], nq(5)

	* Variables head, and age of househhold head
		gen head = (relationharm==1)
		gen _agehead = age if head==1
		bys hhid: egen agehead = median(_agehead)
		drop _agehead

	* Income to consumption ratio (original)
		gen double ratio_orig = (ipcf_ppp17/welfare_ppp17)
		
	* Impute missing values for male - there shouldn't be any missing values in independent vars
		replace male = 0 if male==.	
			
	* Classifying households into 4 different cases for changes in per capita income
		
		gen incomeratio = ipcf_ppp17/pc_inc_s if ipcf_ppp17!=0

		gen case = .

		replace case = 			0 if (incomeratio>=.999) & (incomeratio<=1.001) // Remained with "practically" the same income
		replace case = 			0 if ipcf_ppp17==0 & pc_inc_s==0				// Including zeros
		
		replace case = 			1 if (ipcf_ppp17> 0 & ipcf_ppp17!=.) & ///
									 (  pc_inc_s> 0 & pc_inc_s!=.) 	 & ///
									 case!=0			   				// Remained with positive income
		
		replace case = 			2 if (ipcf_ppp17==0                ) & (pc_inc_s> 0 & pc_inc_s!=.)	& case!=0 // Turned to positive income
		
		replace case = 			3 if (ipcf_ppp17> 0 & ipcf_ppp17!=.) & (pc_inc_s==0              )	& case!=0 // Turned to income equal to zero
		
		label define lblcase 0 "Case 0: X=X' -> Y'=Y", add	
		label define lblcase 1 "Case 1: X>0, X'>0, Y>0 -> Y'= X'* matched_ratio(Y/X)", add
		label define lblcase 2 "Case 2: X=0, X'>0, Y>0 -> Y'= X'* matched_ratio(Y/X)|Y'>Y)", add
		label define lblcase 3 "Case 3: X>0, X'=0, Y>0 -> Y'= X'* matched_ratio(Y/X)|Y'<Y)", add	
		
		label values case lblcase
		
		gen double nwf = . 
		label var nwf "New Welfare at household head level (bridge)"

	****************************************************************************
	* Treatment for Case 0: Since initial and final per capita income are equal, 
	* household will continue with the same per capita consumption
	****************************************************************************

		replace nwf = welfare_ppp17 if case==0

	****************************************************************************	
	* Treatment for Case 1: Look for a similar household and import their 
	* original income to consumption ratio.
	****************************************************************************
	{
		* Setting up the Sample B.(Receiver).
		* Cloning the simulated per capita income
			clonevar ratio_outcome = ratio_orig
			clonevar pc_inc_match  = ipcf_ppp17
		
			local vars_order "hhid pid"
			local vars_match "agehead hsize pc_inc_match"
			local vars_group "region ntile urban"
			local vars_addit "ipcf_ppp17 pc_inc_s welfare_ppp17 ratio_orig ratio_outcome"
			
		* Create frame for receivers
			frame put ratio_orig `vars_order' `vars_match' `vars_group' `vars_addit' if case==1 & h_head==1, into(matreceiver)
			frame matreceiver {
				gen case1_treated = 0
			}
			
		* Setting Sample A.(Donor).
		* Create frame for donors
			frame copy matreceiver matdonor , replace
			frame matdonor {
				replace case1_treated = 1
				replace pc_inc_match  = pc_inc_s
				replace ratio_outcome = (pc_inc_s/welfare_ppp17)
			}
		
		* Append both frames
		frame change matreceiver
		myfrappend _all, from(matdonor)	// See code to append frames in aux folder
		frame change default
		
		* PSMATCH2 on both frames, by group
		frame matreceiver {
			
			egen g = group(`vars_group')
			gen double ratio_sim = .
			levelsof g, local(allvarsgroup)
		
			foreach gr of local allvarsgroup {
				
				sort case1_treated `vars_order'
				replace ratio_sim = 3
				cap psmatch2 case1_treated `vars_match' if g==`gr', neighbor(1) outcome(ratio_outcome)
				if _rc {
					* This may happen when pc_inc_math predicts data perfectly.
					* Then keep the original ratio_sim
					replace ratio_sim = ratio_outcome
				}
				else {
					replace ratio_sim = _ratio_outcome  if g==`gr' & case1_treated==1
					drop _*
				}
			}
			
			keep if case1_treated==1
			
		}
		
		* Merge widh default frame
		frlink m:1 hhid, frame(matreceiver)
		frget ratio_sim = ratio_sim, from(matreceiver)
		
		frame drop matreceiver matdonor
		drop matreceiver
		drop pc_inc_match ratio_outcome
		
		* Specify a band for the change in the new ratio
		replace ratio_sim = ratio_orig * 1.2 if (ratio_sim/ratio_orig)>1.2
		replace ratio_sim = ratio_orig * 0.8 if (ratio_sim/ratio_orig)<0.8
		
		replace nwf = pc_inc_s / ratio_sim if case==1
		
	}
			
	****************************************************************************
	* Treatement for Case 2: Household will be matched with the most similar 
	* household considering a higher per capita consumption
	****************************************************************************
	{
		gen byte case2_treated = .
		replace  case2_treated = 0 if (ipcf_ppp17> 0 & ipcf_ppp17!=.) 								// Not treated: Households with initial positive income
		replace  case2_treated = 1 if (ipcf_ppp17==0                ) & (pc_inc_s> 0 & pc_inc_s!=.)	// Treated: Households that turned to positive income

		sum case2_treated
		if r(mean)>0 & r(mean)!=. {
			sort hhid pid
			psmatch2 case2_treated agehead male hsize educ_level i.urban i.ntiles if head==1 & case2_treated!=., neighbor(1) noreplacement
			
			levelsof _id if _treated==1, local(allids)	
			
			foreach id of local allids {
				
				* Here we recover the psscore and welfare of a treated individual
				noi di "`id'"
				sum _pscore if _id==`id'
					scalar ps`id' = r(mean)
				sum welfare_ppp17 if _id==`id'
					scalar wf`id' = r(mean)
				
				* Here we calculate the absolute difference in psscore between 
				* a treated individual and all untreated in the sample
				gen double _psd`id' = abs(_pscore - ps`id') if _treated==0 & welfare_ppp17>wf`id'
					* Select the minimum absolute difference
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
					noi di "Out of those selected, pick one, randomly"
					gen _rd = runiform() if _psd`id' == mind`id'
					sum _rd
						sum welfare_ppp17 if _rd == r(min)	
						replace nwf = r(mean) if _id==`id'
					drop _rd
				}
				
				drop _psd`id'
			}

			drop _pscore _treated _support _weight _id _n1 _nn _pdif
		}

	}

	****************************************************************************
	* Treatement for Case 3. Household will be matched with the most similar
	* household considering a lower per capita consumption
	****************************************************************************
	{
		gen byte case3_treated = .
		replace  case3_treated = 0 if (ipcf_ppp17==0 | (ipcf_ppp17>0 & ipcf_ppp17!=.)) 	// Not treated: Households with initial with zero income
		replace  case3_treated = 1 if (ipcf_ppp17> 0 & ipcf_ppp17!=.) & (pc_inc_s==0)	// Trated: Households that turned to income equal to zero
		
		sum case3_treated
		if r(mean)>0 & r(mean)!=. {
			* Using a restricted sample may overshoot the regression
			*psmatch2 case3_treated agehead hsize educ_level if head==1 & case3_treated!=., neighbor(1) noreplacement
			sort hhid pid
			psmatch2 case3_treated agehead male hsize educ_level i.urban i.ntiles if head==1 & case3_treated!=., neighbor(1) noreplacement
			
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
		}
	}
		
	* Assign household level income, nwf, to all household members
		bys hhid: egen pc_con_s = mean(nwf)
		
	* Recalculate the new ratio simulated
		replace ratio_sim = pc_inc_s/pc_con_s
		label variable ratio_sim "Simulated income/consumption ratio"	

}
********************************************************************************
* Private Consumption Re-scale
********************************************************************************
		
	* Re-scale according to growth in private consumption per capita
	sum welfare_ppp17 [w=wgt]
		scalar pcconsbase = r(mean)
		
	sum pc_con_s [w=wgt]
		scalar pccons_int = r(mean)
	
	scalar objective_pccons = pccons[1,1]+1
	
	rename pc_con_s pc_con_preadj
	
	gen double pc_con_s = pc_con_preadj * (objective_pccons * pcconsbase) / (pccons_int)
	label var pc_con_s "Final Per Capita Household Consumption"
	
	
*=============================================================================
*                                     END
*=============================================================================

	
	