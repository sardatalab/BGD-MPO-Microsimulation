*=============================================================================
* TITLE: 14 - Household income
*===========================================================================
* Prepared by: Sergio Olivieri
* E-mail: solivieri@worldbank.org
*=============================================================================
* Created on : Mar 17, 2020
* Last update: Jan 04, 2021
*=============================================================================
* Modified by: Kelly Y. Montoya
* Modification: 04/29/2022 - Correcting household non-labor income
*				07/26/2022 - Corrected household labor income
*				08/30/2022 - Corrected missing household labor income
*=============================================================================

note: total individual incomes before food price adjustment 
*=============================================================================

* Labor
* Observed 
gen     h_lai_obs = h_lai * -1
replace h_lai_obs = . if h_lai_obs == 0 
* Counterfactual
*egen     h_lai_s = sum(tot_lai_s) , by(hhid)
egen     h_lai_s = sum(tot_lai_s) if h_head != ., by(hhid) m // KM: I corrected this.
*replace  h_lai_s = .  if h_lai_s == 0

* KM: I modified this part
* Non-labor
* Observed
bysort id: egen aux_nlai = sum(h_nlai), m
cap drop h_nlai
gen h_nlai = aux_nlai
drop aux_nlai

gen     h_nlai_obs = h_nlai * -1
replace h_nlai_obs = . if h_nlai_obs == 0 
* Counterfactual
*replace  h_nlai_s = .  if h_nlai_s == 0

* Total
egen     h_inc_s = rowtotal(h_inc h_lai_obs h_lai_s h_nlai_obs h_nlai_s) if h_head != ., missing 

replace  h_inc_s = 0 if h_inc_s < 0
*replace  h_inc_s = . if h_inc_s == 0
replace  h_inc_s = . if h_inc == .

* per capita household income - total
gen       pc_inc_s = h_inc_s/ h_size
label var pc_inc_s "per capita income - $scenario" 


*=============================================================================
*                                     END
*=============================================================================
