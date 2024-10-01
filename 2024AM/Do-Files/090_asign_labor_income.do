*!v1.0
*===========================================================================
* TITLE: 090 - Assign labor income by sector
*===========================================================================
* Prepared by: Sergio Olivieri
* E-mail: solivieri@worldbank.org
*===========================================================================
* Created on : Mar 17, 2020
* Last update: Jan 04, 2021
*===========================================================================

*===========================================================================
* Random numbers
*===========================================================================
capture drop aleat_ila
set seed 23081985
gen aleat_ila = uniform() if sample == 1 

** I- Asign the contrafactual labor income by sector

*  IMPUTATION of salaried to those who come from the non-employed status in order to obtain the INCOME LINEAR PROJECTION
sum sectorg
loc lim = r(max)
replace salaried = . if unemplyd == 1

forvalues i = 1/`lim' {
   forvalues k =1(1)2 {
	   
   sum salaried  [w = wgt] if sectorg == `i' & sample_`k' == 1
   sca ns_`k'_`i' = 1-r(mean)
   
   sum public_job    [w = wgt] if sectorg == `i' & sample_`k' == 1
   sca pj_`k'_`i' = 1-r(mean)
	
   }
}

*===========================================================================
* SALARIED - NON-SALARIED
*===========================================================================

* Identifies the people who change sector by education level
gen     ch_l = (occupation != occupation_s) if sample_1 == 1 & (occupation_s > 0 & occupation_s < .) & salaried == .
replace ch_l = . if ch_l == 0
gen     ch_h = (occupation != occupation_s) if sample_2 == 1 & (occupation_s > 0 & occupation_s < .) & salaried == .
replace ch_h = . if ch_h == 0

* Assigns the same salaried structure of the sector
capture drop aux_l* aux_h* 
* Creates the new salaried variable
clonevar salaried_s = salaried
replace  salaried_s = 1 if (ch_l == 1 | ch_h == 1) 

forvalues i = 1/`lim' {
	sum  ch_l [aw = fexp_s] if sect_main_s== `i'
	if r(sum) != 0 {
		gen  aux_l_`i' = sum(fexp_s)/r(sum) if ch_l == 1 & sect_main_s== `i'
		sort aleat_ila, stable
		replace salaried_s = 0 if  aux_l_`i' <= ns_1_`i'
		di in ye "share of self employment is ===>   ns_1_`i'  = " scalar(ns_1_`i')
		ta salaried_s [aw=fexp_s] if aux_l_`i' != .
	}

	sum  ch_h [aw = fexp_s] if occupation_s == `i'
	if r(sum) != 0 {
		gen  aux_h_`i' = sum(fexp_s)/r(sum) if ch_h == 1 & sect_main_s== `i'
		sort aleat_ila, stable
		replace salaried_s = 0 if  aux_h_`i' <= ns_2_`i'
		di in ye "share of self employment is ===>   ns_2_`i'  = " scalar(ns_2_`i')
		ta salaried_s [aw=fexp_s] if aux_h_`i' != .
	}
}


rename ch_l ch_l_sal
rename ch_h ch_h_sal
capture drop aux_l_*
capture drop aux_h_*

*===========================================================================
* PUBLIC - PRIVATE JOBS
*===========================================================================

* a) Identifies the people who change sector by education level
gen     ch_l = (occupation != occupation_s) if sample_1 == 1 & (occupation_s > 0 & occupation_s < .) & public_job == .
replace ch_l = . if ch_l == 0
gen     ch_h = (occupation != occupation_s) if sample_2 == 1 & (occupation_s > 0 & occupation_s < .) & public_job == .
replace ch_h = . if ch_h == 0


* c) Creates the new public_job variable
clonevar public_job_s = public_job
replace  public_job_s = 1 if (ch_l == 1 | ch_h == 1) 
ta public_job
ta public_job_s

*===========================================================================
forvalues i = 1/`lim' {
	sum  ch_l [aw = fexp_s] if sect_main_s== `i'
	if r(sum) != 0 {
		gen  aux_l_`i' = sum(fexp_s)/r(sum) if ch_l == 1 & sect_main_s== `i'
		sort aleat_ila, stable
		replace public_job_s = 0 if  aux_l_`i' <= pj_1_`i'
		di in ye "share of private employment is ===>   pj_1_`i'  = " scalar(pj_1_`i')
		ta public_job_s [aw=fexp_s] if aux_l_`i' != .
	}

	sum  ch_h [aw = fexp_s] if sect_main_s== `i'
	if r(sum) != 0 {
		gen  aux_h_`i' = sum(fexp_s)/r(sum) if ch_h == 1 & sect_main_s== `i'
		sort aleat_ila, stable
		replace public_job_s = 0 if  aux_h_`i' <= pj_2_`i'
		di in ye "share of private employment is ===>   pj_2_`i'  = " scalar(pj_2_`i')
		ta public_job_s [aw=fexp_s] if aux_h_`i' != .
	}
}

rename ch_l ch_l_pj
rename ch_h ch_h_pj
capture drop aux_l_*
capture drop aux_h_*
capture drop ch_l_sal
capture drop ch_h_sal
capture drop ch_l_pj
capture drop ch_h_pj

*===========================================================================
* II- Compute the income of employed simulated who come from other sector status
*===========================================================================

* Income estimation by education level
gen  predila_n  = .
/*
if $m == 1 {

	forvalues n = 1/2 {

		* linear projection
	
		* Those who come from INACTIVITY
		mat score predila_n = b_1_`n' if occupation == 0 & occupation_s == 2 & sample_`n' == 1, replace
		mat score predila_n = b_2_`n' if occupation == 0 & occupation_s == 3 & sample_`n' == 1, replace
		mat score predila_n = b_3_`n' if occupation == 0 & occupation_s == 4 & sample_`n' == 1, replace

		* Those who come from UNEMPLOYMENT
		mat score predila_n = b_1_`n' if occupation == 1 & occupation_s == 2 & sample_`n' == 1, replace
		mat score predila_n = b_2_`n' if occupation == 1 & occupation_s == 3 & sample_`n' == 1, replace
		mat score predila_n = b_3_`n' if occupation == 1 & occupation_s == 4 & sample_`n' == 1, replace

		* Those who come from AGRICULTURE
		mat score predila_n = b_2_`n' if occupation == 2 & occupation_s == 3 & sample_`n' == 1, replace
		mat score predila_n = b_3_`n' if occupation == 2 & occupation_s == 4 & sample_`n' == 1, replace

		* Those who come from INDUSTRY
		mat score predila_n = b_1_`n' if occupation == 3 & occupation_s == 2 & sample_`n' == 1, replace
		mat score predila_n = b_3_`n' if occupation == 3 & occupation_s == 4 & sample_`n' == 1, replace

		* Those who come from SERVICES
		mat score predila_n = b_1_`n' if occupation == 4 & occupation_s == 2 & sample_`n' == 1, replace
		mat score predila_n = b_2_`n' if occupation == 4 & occupation_s == 3 & sample_`n' == 1, replace

		* Those who remain in their sector but changes their informality status   
		mat score predila_n = b_1_`n' if occupation == 2 & occupation_s == 2 & sample_`n' == 1 & informal_s == 1 & informal == 0, replace
		mat score predila_n = b_2_`n' if occupation == 3 & occupation_s == 3 & sample_`n' == 1 & informal_s == 1 & informal == 0, replace
		mat score predila_n = b_3_`n' if occupation == 4 & occupation_s == 4 & sample_`n' == 1 & informal_s == 1 & informal == 0, replace

		mat score predila_n = b_1_`n' if occupation == 2 & occupation_s == 2 & sample_`n' == 1 & informal_s == 0 & informal == 1, replace
		mat score predila_n = b_2_`n' if occupation == 3 & occupation_s == 3 & sample_`n' == 1 & informal_s == 0 & informal == 1, replace
		mat score predila_n = b_3_`n' if occupation == 4 & occupation_s == 4 & sample_`n' == 1 & informal_s == 0 & informal == 1, replace
		 
		mat score predila_n = b_1_`n' if occupation == 2 & occupation_s == 2 & sample_`n' == 1 & informal_s == 1 & informal == 1, replace
		mat score predila_n = b_2_`n' if occupation == 3 & occupation_s == 3 & sample_`n' == 1 & informal_s == 1 & informal == 1, replace
		mat score predila_n = b_3_`n' if occupation == 4 & occupation_s == 4 & sample_`n' == 1 & informal_s == 1 & informal == 1, replace

		mat score predila_n = b_1_`n' if occupation == 2 & occupation_s == 2 & sample_`n' == 1 & informal_s == 0 & informal == 0, replace
		mat score predila_n = b_2_`n' if occupation == 3 & occupation_s == 3 & sample_`n' == 1 & informal_s == 0 & informal == 0, replace
		mat score predila_n = b_3_`n' if occupation == 4 & occupation_s == 4 & sample_`n' == 1 & informal_s == 0 & informal == 0, replace
		 
		*  Residuals   
		replace   predila_n = predila_n + invnorm(aleat_ila)* sigma_1_`n' if occupation_s == 2 & sample_`n' == 1 
		replace   predila_n = predila_n + invnorm(aleat_ila)* sigma_2_`n' if occupation_s == 3 & sample_`n' == 1
		replace   predila_n = predila_n + invnorm(aleat_ila)* sigma_3_`n' if occupation_s == 4 & sample_`n' == 1
	}

	replace predila_n = exp(predila_n)

	* Those who mantain their employment status and sector
	gen     lai_m_s = .
	replace lai_m_s = lai_m if occupation == 2 & occupation_s == 2                
	replace lai_m_s = .     if occupation == 2 & occupation_s == 2 & (lai_m == .) 
	replace lai_m_s = lai_m if occupation == 3 & occupation_s == 3                
	replace lai_m_s = .     if occupation == 3 & occupation_s == 3 & (lai_m == .) 
	replace lai_m_s = lai_m if occupation == 4 & occupation_s == 4                
	replace lai_m_s = .     if occupation == 4 & occupation_s == 4 & (lai_m == .) 

	* New employed who come from other sectors, non-employed or unemployed 
	replace lai_m_s = predila_n  if occupation_s == 2 & lai_m_s == .
	replace lai_m_s = predila_n  if occupation_s == 3 & lai_m_s == .
	replace lai_m_s = predila_n  if occupation_s == 4 & lai_m_s == .

	* Those who mantain their sectors but change their formality status
	replace lai_m_s = predila_n  if occupation == 2 & occupation_s == 2 & (lai_m == .) & informal_s == 1 & informal == 0
	replace lai_m_s = predila_n  if occupation == 3 & occupation_s == 3 & (lai_m == .) & informal_s == 1 & informal == 0
	replace lai_m_s = predila_n  if occupation == 4 & occupation_s == 4 & (lai_m == .) & informal_s == 1 & informal == 0

	replace lai_m_s = predila_n  if occupation == 2 & occupation_s == 2 & (lai_m == .) & informal_s == 0 & informal == 1
	replace lai_m_s = predila_n  if occupation == 3 & occupation_s == 3 & (lai_m == .) & informal_s == 0 & informal == 1
	replace lai_m_s = predila_n  if occupation == 4 & occupation_s == 4 & (lai_m == .) & informal_s == 0 & informal == 1

}
*/


	forvalues n = 1/2 {

		* Linear projection

		* Those who come from INACTIVITY
		mat score predila_n  = b_1_`n'  if occupation == 0 & sectorg_s == 1 & sample_`n' == 1, replace
		mat score predila_n  = b_2_`n'  if occupation == 0 & sectorg_s == 2 & sample_`n' == 1, replace
		mat score predila_n  = b_3_`n'  if occupation == 0 & sectorg_s == 3 & sample_`n' == 1, replace
		mat score predila_n  = b_4_`n'  if occupation == 0 & sectorg_s == 4 & sample_`n' == 1, replace
		mat score predila_n  = b_5_`n'  if occupation == 0 & sectorg_s == 5 & sample_`n' == 1, replace
		mat score predila_n  = b_6_`n'  if occupation == 0 & sectorg_s == 6 & sample_`n' == 1, replace

		* Those who come from UNEMPLOYMENT
		mat score predila_n  = b_1_`n'  if occupation == 10 & sectorg_s == 1 & sample_`n' == 1, replace
		mat score predila_n  = b_2_`n'  if occupation == 10 & sectorg_s == 2 & sample_`n' == 1, replace
		mat score predila_n  = b_3_`n'  if occupation == 10 & sectorg_s == 3 & sample_`n' == 1, replace
		mat score predila_n  = b_4_`n'  if occupation == 10 & sectorg_s == 4 & sample_`n' == 1, replace
		mat score predila_n  = b_5_`n'  if occupation == 10 & sectorg_s == 5 & sample_`n' == 1, replace
		mat score predila_n  = b_6_`n'  if occupation == 10 & sectorg_s == 6 & sample_`n' == 1, replace

		* Those who come from Agriculture s0
		mat score predila_n  = b_2_`n'  if sectorg == 1 & sectorg_s == 2 & sample_`n' == 1, replace
		mat score predila_n  = b_3_`n'  if sectorg == 1 & sectorg_s == 3 & sample_`n' == 1, replace
		mat score predila_n  = b_4_`n'  if sectorg == 1 & sectorg_s == 4 & sample_`n' == 1, replace
		mat score predila_n  = b_5_`n'  if sectorg == 1 & sectorg_s == 5 & sample_`n' == 1, replace
		mat score predila_n  = b_6_`n'  if sectorg == 1 & sectorg_s == 6 & sample_`n' == 1, replace

	* Those who come from Agriculture s1
	   mat score predila_n  = b_1_`n'  if sectorg == 2 & sectorg_s == 1 & sample_`n' == 1, replace
	   mat score predila_n  = b_3_`n'  if sectorg == 2 & sectorg_s == 3 & sample_`n' == 1, replace
	   mat score predila_n  = b_4_`n'  if sectorg == 2 & sectorg_s == 4 & sample_`n' == 1, replace
	   mat score predila_n  = b_5_`n'  if sectorg == 2 & sectorg_s == 5 & sample_`n' == 1, replace
	   mat score predila_n  = b_6_`n'  if sectorg == 2 & sectorg_s == 6 & sample_`n' == 1, replace
	 
		* Those who come from Industry s0
		mat score predila_n  = b_1_`n'  if sectorg == 3 & sectorg_s == 1 & sample_`n' == 1, replace
		mat score predila_n  = b_2_`n'  if sectorg == 3 & sectorg_s == 2 & sample_`n' == 1, replace
		mat score predila_n  = b_4_`n'  if sectorg == 3 & sectorg_s == 4 & sample_`n' == 1, replace
		mat score predila_n  = b_5_`n'  if sectorg == 3 & sectorg_s == 5 & sample_`n' == 1, replace
		mat score predila_n  = b_6_`n'  if sectorg == 3 & sectorg_s == 6 & sample_`n' == 1, replace

		* Those who come from Industry s1
		mat score predila_n  = b_1_`n'  if sectorg == 4 & sectorg_s == 1 & sample_`n' == 1, replace
		mat score predila_n  = b_2_`n'  if sectorg == 4 & sectorg_s == 2 & sample_`n' == 1, replace
		mat score predila_n  = b_3_`n'  if sectorg == 4 & sectorg_s == 3 & sample_`n' == 1, replace
		mat score predila_n  = b_5_`n'  if sectorg == 4 & sectorg_s == 5 & sample_`n' == 1, replace
		mat score predila_n  = b_6_`n'  if sectorg == 4 & sectorg_s == 6 & sample_`n' == 1, replace

		* Those who come from Services s0
		mat score predila_n  = b_1_`n'  if occupation == 5 & sectorg_s == 1 & sample_`n' == 1, replace
		mat score predila_n  = b_2_`n'  if occupation == 5 & sectorg_s == 2 & sample_`n' == 1, replace
		mat score predila_n  = b_3_`n'  if occupation == 5 & sectorg_s == 3 & sample_`n' == 1, replace
		mat score predila_n  = b_4_`n'  if occupation == 5 & sectorg_s == 4 & sample_`n' == 1, replace
		mat score predila_n  = b_6_`n'  if occupation == 5 & sectorg_s == 6 & sample_`n' == 1, replace

	* Those who come from Services s1
	   mat score predila_n  = b_1_`n'  if occupation == 6 & sectorg_s == 1 & sample_`n' == 1, replace
	   mat score predila_n  = b_2_`n'  if occupation == 6 & sectorg_s == 2 & sample_`n' == 1, replace
	   mat score predila_n  = b_3_`n'  if occupation == 6 & sectorg_s == 3 & sample_`n' == 1, replace
	   mat score predila_n  = b_4_`n'  if occupation == 6 & sectorg_s == 4 & sample_`n' == 1, replace
	   mat score predila_n  = b_5_`n'  if occupation == 6 & sectorg_s == 5 & sample_`n' == 1, replace

		* Residuals   
		replace   predila_n = predila_n + invnorm(aleat_ila)* sigma_1_`n' if sectorg_s == 1 & sample_`n' == 1 
		replace   predila_n = predila_n + invnorm(aleat_ila)* sigma_2_`n' if sectorg_s == 2 & sample_`n' == 1
		replace   predila_n = predila_n + invnorm(aleat_ila)* sigma_3_`n' if sectorg_s == 3 & sample_`n' == 1
		replace   predila_n = predila_n + invnorm(aleat_ila)* sigma_4_`n' if sectorg_s == 4 & sample_`n' == 1
		replace   predila_n = predila_n + invnorm(aleat_ila)* sigma_5_`n' if sectorg_s == 5 & sample_`n' == 1
		replace   predila_n = predila_n + invnorm(aleat_ila)* sigma_6_`n' if sectorg_s == 6 & sample_`n' == 1
	}

	replace predila_n = exp(predila_n)

	* those who mantain their employment status and sector
	gen     lai_m_s = .
	levelsof occupation if occupation>10, local(alloccups)
	foreach i of local alloccups {
		* Those who mantain their employment status and sector
		replace lai_m_s = lai_m if occupation == `i' & occupation_s == `i'                
		replace lai_m_s = .     if occupation == `i' & occupation_s == `i' & (lai_m == .) 
		* New employed who come from other sectors, non-employed or unemployed 
		replace lai_m_s = predila_n  if occupation_s == `i' & lai_m_s == .
	}

	* 2- New employed who come from other sectors, non-employed or unemployed 
	replace lai_m_s = predila_n  if sectorg_s == 1 & lai_m_s == .
	replace lai_m_s = predila_n  if sectorg_s == 2 & lai_m_s == .
	replace lai_m_s = predila_n  if sectorg_s == 3 & lai_m_s == .
	replace lai_m_s = predila_n  if sectorg_s == 4 & lai_m_s == .
	replace lai_m_s = predila_n  if sectorg_s == 5 & lai_m_s == .
	replace lai_m_s = predila_n  if sectorg_s == 6 & lai_m_s == .




* Summ those who do not belong to the sample
replace lai_m_s = lai_m  if lai_m_s == . &  sectorg_s!= . & sample == .
replace lai_m_s = lai_m  if lai_m_s == . &  lai_m != . & sample == .
replace lai_m_s = lai_m  if lai_m_s == . &  lai_m != . & sample == 1


* Eliminate labor income for those who pass from employed to non-employed status 
replace lai_m_s = .  if active_s  == 1 & unemplyd_s  == 1 & unemplyd == 0  & sample == 1
replace lai_m_s = .  if active_s  == 0 & lf_samp     == 1                  & sample == 1

drop predila_n aleat_ila

*===========================================================================
*                                     END
*===========================================================================