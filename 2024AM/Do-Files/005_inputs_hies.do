*!v1.0
/*========================================================================
Project:			Microsimulations Inputs from HIES
Institution:		World Bank

Author:				Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Creation Date:		04/25/2022

Last Modification:	Israel Osorio-Rodarte (iosoriorodarte@worldbank.org)
Modification date: 	07/29/2024
========================================================================*/

drop _all

**************************************************************************
* 	0 - SETTING
**************************************************************************

* Set up postfile for results
tempname mypost
tempfile myresults
postfile `mypost' str12(country) year str40(indicator) value str40(title) using `myresults', replace


*************************************************************************
* 	1 - HIES DATA
*************************************************************************

foreach country in BGD { // Open loop countries
	
	foreach year of numlist 2016 2022 { // Open loop year
		
		* Loading the data
		di in red "`country' - `year'"
				
		if "`country'" == "BGD" & `year' == 2016 {
			use "$data_root/DLW/HIES/BGD_2016_HIES_v01_M_v07_A_SARMD_IND.dta", clear
			merge 1:1 idh idp using "$data_root/DLW/HIES/BGD_2016_HIES_v01_M_v07_A_SARMD_INC.dta"
			drop _merge
			merge 1:1 pid using "$data_root/DLW/HIES/BGD_2016_HIES_v01_M_v07_A_SARMD_LBR.dta"
			drop _merge
		}
		if "`country'" == "BGD" & `year' == 2022 {
			use "$data_root/DLW/HIES/BGD_2022_HIES_v02_M_v02_A_SARMD_IND.dta", clear
			merge 1:1 idh idp using "$data_root/DLW/HIES/BGD_2022_HIES_v02_M_v02_A_SARMD_INC.dta"
			drop _merge
			merge 1:1 pid using "$data_root/DLW/HIES/BGD_2022_HIES_v02_M_v02_A_SARMD_LBR.dta"
			drop _merge
		}

	
		* Filter for coherent households.
		*****************************************************
		gen byte cohh = (welfare>0)
		qui cap keep if cohh==1 & ipcf!=.
		qui cap keep if ipcf!=.
		
		* Filter for coherent labor individuals.
		*****************************************************
		* Excluding the negative values and one outlier at the very top
		gen byte cohi = (ip>0 & ip!=. & ip<9100000)
		
		* Defining sample 
		********************
		cap drop sample
		qui gen sample    = (age >= 15 & age <= 64)
		gen byte poptotal = 1
		gen byte pop0014  = (age >= 0  & age <= 14)
		gen byte pop1564  = (age >= 15 & age <= 64)
		gen byte pop65up  = (age >= 65 & age != . )
		
		* Two types of workers s0 and s1
		*********************************		
		qui cap drop d_s
		qui gen d_s = .
			replace d_s = 1 if occup_year>=1 & occup_year<=3 & lstatus_year==1 & sample==1
			replace d_s = 1 if occup_year==6          		 & lstatus_year==1 & sample==1
			replace d_s = 0 if ((occup_year==4|occup_year==5)|(occup_year>=7 & occup_year!=.)) & lstatus_year==1 & sample==1
			replace d_s = 0 if occup_year==. & educy<=9             & lstatus_year==1 & sample==1
			replace d_s = 1 if occup_year==. & educy>=10 & educy!=. & lstatus_year==1 & sample==1
			replace d_s = 0 if occup_year==. & educy==. 			& lstatus_year==1 & sample==1
		label define lbld_s 0 "Unskilled" 1 "Skilled"
		label values d_s lbld_s

		* Use lstatus to fix inconsistent lstatus_year
		replace lstatus_year = 2 if lstatus==2 & lstatus_year==. & sample==1
		replace lstatus_year = 3 if lstatus==3 & lstatus_year==. & sample==1
		replace lstatus_year = 3 if lstatus_year==. 		     & sample==1
		
		* Industry main occupation
		* activities a = {1..n}
		***************************
		gen industry_imp = .
			replace industry_imp = 1 if industrycat10_year==1	// agriculture
			replace industry_imp = 2 if industrycat10_year==5	// construction
			replace industry_imp = 3 if industrycat10_year==2|industrycat10_year==3	// rest of industry			
			replace industry_imp = 4 if industrycat10_year==7	// transport
			replace industry_imp = 5 if industrycat10_year==8	// financial
			replace industry_imp = 6 if industrycat10_year==4|industrycat10_year==6|industrycat10_year==9|industrycat10_year==10
			replace industry_imp = 6 if industrycat10_year==. & lstatus_year==1 // 7 observations
			#delimit ;
			label define lblindustry_imp 
				1 "Agriculture"
				2 "Construction"
				3 "Rest of Industry"
				4 "Transport"
				5 "Finance"
				6 "Rest of Services";
			#delimit cr
			label values industry_imp lblindustry_imp
		
		* Labor income - s0/s1 by sector and total
		*******************************************************
		*gen double ip_ppp17 = ((12/365)* ip/cpi2017/icp2017) if cohi == 1 // Labor income main activity ppp 2017, daily
		gen double ip_lcu   =  (12/365)*ip					 if cohi == 1 // Labor income main activity in LCU, daily
		
		levelsof d_s, local(alls)
		levelsof industry_imp, local(alla)
		foreach s of local alls {
		foreach a of local alla {
		
			qui gen ip_s`s'_a`a' = ip_lcu if sample == 1 & lstatus_year==1 & industry_imp == `a' & d_s == `s' 
			
		}
		}
		
		qui gen ip_total  = ip_lcu if sample == 1 & lstatus_year==1
		qui gen ip_s1     = ip_lcu if sample == 1 & lstatus_year==1 & d_s == 1 
		qui gen ip_s0 	  = ip_lcu if sample == 1 & lstatus_year==1 & d_s == 0

		
		* Number of workers - formal/informal by sector
		**************************************************
		foreach s of local alls {
		foreach a of local alla {
			qui gen lstatus1_s`s'_a`a'  = (sample == 1 & lstatus_year==1 & industry_imp == `a' & d_s == `s')
		}
		}
		
		* Estimations
		****************
		
		** Number of workers
		***********************

		* Total population
		sum poptotal [w=wgt]
		local poptotal = `r(sum_w)'
		post `mypost' ("`country'") (`year') ("hspop_total")  (`poptotal') ("Population, total")

		* Population 00-14
		sum pop0014 [w=wgt]
		local pop0014 = `r(sum_w)'*`r(mean)'
		post `mypost' ("`country'") (`year') ("hspop_0014") (`pop0014') ("Population, 00-14")
		
		* Population 15-64
		sum pop1564 [w=wgt]
		local pop1564 = `r(sum_w)'*`r(mean)'
		post `mypost' ("`country'") (`year') ("hspop_1564") (`pop1564') ("Population, 15-64")
		
		* Population 65+
		sum pop65up [w=wgt]
		local pop65up = `r(sum_w)'*`r(mean)'
		post `mypost' ("`country'") (`year') ("hspop_65up") (`pop65up') ("Population, 65+")
		
		* Not in the labor force
		sum lstatus_year [w=wgt] if lstatus_year == 3 & sample == 1
		local lstatus3 = `r(sum_w)'
		post `mypost' ("`country'") (`year') ("hslstatus3_1564") (`lstatus3') ("Not in Labor Force") 

		* Unemployed
		sum lstatus_year [w=wgt] if lstatus_year == 2 & sample == 1 
		local lstatus2 = `r(sum_w)'
		post `mypost' ("`country'") (`year') ("hslstatus2_1564") (`lstatus2') ("Unemployed") 
		* Employment
		sum lstatus_year [w=wgt] if lstatus_year == 1 & sample == 1  
		local lstatus1 = `r(sum_w)'
		post `mypost' ("`country'") (`year') ("hslstatus1_1564") (`lstatus1') ("Employed") 
		
		* Labor Force
		sum wgt if (lstatus_year == 1|lstatus_year==2) & sample == 1
		local lstatus12 = `r(sum)'
		post `mypost' ("`country'") (`year') ("hslstatus12_1564") (`lstatus12') ("Labor Foce") 

		* Number of workers, across industries and type of workers
		foreach s of local alls {
		foreach a of local alla {
			qui sum lstatus1_s`s'_a`a'[w=wgt]
			local lstatus1_s`s'_a`a' = `r(sum_w)'*`r(mean)'
			
			local laba : label lblindustry_imp `a'
			local labs : label lbld_s `s'
			
			post `mypost' ("`country'") (`year') ("hslstatus1_s`s'_a`a'") (`lstatus1_s`s'_a`a'') ("Workers `laba' `labs'") 
		}
		}
		
		** Labor income (avg)
		************************
		qui sum ip_total [w=wgt]
		local ip_total = `r(mean)'
		post `mypost' ("`country'") (`year') ("hsip_total") (`ip_total') ("IP All")

		foreach s of local alls {
		foreach a of local alla {
			qui sum ip_s`s'_a`a' [w=wgt] 
			local ip_s`s'_a`a' = `r(mean)'
			
			local laba : label lblindustry_imp `a'
			local labs : label lbld_s `s'			
			
			post `mypost' ("`country'") (`year') ("hsip_s`s'_a`a'") (`ip_s`s'_a`a'') ("Mean income in `laba' `labs'") 
		}
		}

		 di in red "`country' - `year' finished successfully"
	
	} // Close loop year
	
} // Close loop countries


	postclose `mypost'
	use  `myresults', clear
	
	
	
	compress
	save "$data_in/Tableau/AM_24 MPO Check/input-labor-hies.dta", replace
	save "$data_in/Tableau/AM_24 MPO Check/version_control/input-labor-hies `c(current_date)'.dta", replace
	
	
	*export excel using "$data_in/Macro and elasticities/Working Input Elasticities.xlsx", sheet("input-labor-hies", replace) firstrow(variables)
	*export excel using "$data_in/Macro and elasticities/Working Input Elasticities.xlsx", sheet("input-labor-hies", replace) firstrow(variables)

	/*
	use "$data_in/Tableau/AM_24 MPO Check/input-labor-hies.dta", clear 
	
	* mnemonic
	rename variable mnemonic

	* indicatorid
	gen indicatorid=.
		replace indicatorid = 201 if mnemonic=="hspop_0014"
		replace indicatorid = 202 if mnemonic=="hspop_1564"
		replace indicatorid = 203 if mnemonic=="hspop_65up"
		replace indicatorid = 204 if mnemonic=="hspop_total"
		
		replace indicatorid = 205 if mnemonic=="lstatus1_1564"
		replace indicatorid = 206 if mnemonic=="lstatus2_1564"
		replace indicatorid = 207 if mnemonic=="lstatus3_1564"		
		replace indicatorid = 208 if mnemonic=="lstatus12_1564"
		
		replace indicatorid = 209 if mnemonic=="lstatus1_s0_a1"
		replace indicatorid = 210 if mnemonic=="lstatus1_s0_a2"
		replace indicatorid = 211 if mnemonic=="lstatus1_s0_a3"
		replace indicatorid = 212 if mnemonic=="lstatus1_s0_a4"
		replace indicatorid = 213 if mnemonic=="lstatus1_s0_a5"
		replace indicatorid = 214 if mnemonic=="lstatus1_s0_a6"
		replace indicatorid = 215 if mnemonic=="lstatus1_s1_a1"
		replace indicatorid = 216 if mnemonic=="lstatus1_s1_a2"
		replace indicatorid = 217 if mnemonic=="lstatus1_s1_a3"
		replace indicatorid = 218 if mnemonic=="lstatus1_s1_a4"
		replace indicatorid = 219 if mnemonic=="lstatus1_s1_a5"
		replace indicatorid = 220 if mnemonic=="lstatus1_s1_a6"
		
		replace indicatorid = 221 if mnemonic=="ip_s0_a1"
		replace indicatorid = 222 if mnemonic=="ip_s0_a2"
		replace indicatorid = 223 if mnemonic=="ip_s0_a3"
		replace indicatorid = 224 if mnemonic=="ip_s0_a4"
		replace indicatorid = 225 if mnemonic=="ip_s0_a5"
		replace indicatorid = 226 if mnemonic=="ip_s0_a6"
		replace indicatorid = 227 if mnemonic=="ip_s1_a1"
		replace indicatorid = 228 if mnemonic=="ip_s1_a2"
		replace indicatorid = 229 if mnemonic=="ip_s1_a3"
		replace indicatorid = 230 if mnemonic=="ip_s1_a4"
		replace indicatorid = 231 if mnemonic=="ip_s1_a5"
		replace indicatorid = 232 if mnemonic=="ip_s1_a6"
		replace indicatorid = 233 if mnemonic=="ip_total"
		
	* varlabel
	rename Indicator varlabel
	
	* title
	gen title = ""
	replace title = "Population" if substr(mnemonic,1,2)=="hs"
	replace title = "Labor" 	 if substr(mnemonic,1,2)=="ls"
	replace title = "Income" 	 if substr(mnemonic,1,2)=="ip"
	
	* value and subtitle
	rename Value value
	replace value = value/10^6    if substr(mnemonic,1,2)=="hs"
	replace value = value/10^6    if substr(mnemonic,1,2)=="ls"
	gen subtitle = ""
	replace subtitle = "millions" if substr(mnemonic,1,2)=="hs"
	replace subtitle = "millions" if substr(mnemonic,1,2)=="ls"
	replace subtitle = "daily, PPP$"
	
	* topicid
	indicatorid topicid topicname sectorid sectorname
	
*/
/*************************************************************************
* 	3 - ELASTICITIES INPUTS
*************************************************************************/

*************************************************************************
* 	3 - ELASTICITIES INPUTS
*************************************************************************

use "$data_in/Tableau/AM_24 MPO Check/input-labor-hies.dta", clear

append using "$data_in/Macro and elasticities/mfmod_bgd.dta"

sort country year indicator
save "$data_in/Macro and elasticities/input_elasticities_hies.dta", replace


*use "$path\input-labor-sedlac.dta", clear
*append using `macrodata'
*sort country year indicator
*save "$data_in/Macro and elasticities/input_elasticities_lfs.dta", replace
