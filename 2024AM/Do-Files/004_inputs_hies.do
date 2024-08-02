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
postfile `mypost' str12(country) year str40(variable) str40(Indicator) Value using `myresults', replace


*************************************************************************
* 	1 - HIES DATA
*************************************************************************

foreach country of global countries_hies { // Open loop countries
	
	foreach year of numlist ${init_year_hies} / ${end_year_hies} { // Open loop year
		
		* Loading the data
		di in red "`country' - `year'"
		
		else if "`country'" == "BGD" & `year' < 2016 continue // We start from 2016
				
		else cap datalibweb, country("`country'") year(`year') mod(INC) clear 
		
		if !_rc di in red "`country' `year' loaded in datalib"
		if _rc {
			di in red "`country' `year' NOT loaded in datalib"
			use "$data_root/BGD_2022_HIES_v02_M_v02_A_SARMD_SIM.dta", clear
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
			replace d_s = 0 if occup_year>=4 & occup_year!=. & lstatus_year==1 & sample==1
			replace d_s = 0 if occup_year==. & educy<=9             & lstatus_year==1 & sample==1
			replace d_s = 1 if occup_year==. & educy>=10 & educy!=. & lstatus_year==1 & sample==1
			replace d_s = 0 if occup_year==. & educy==. 			& lstatus_year==1 & sample==1
		label define lbld_s 0 "Unskilled" 1 "Skilled"
		label values d_s lbld_s

		* lstatus
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
		gen double welfare_ppp17 = ((12/365)*welfarenat/cpi2017/icp2017)
		gen double ip_ppp17 = ((12/365)* ip/cpi2017/icp2017) if cohi == 1 // Labor income main activity ppp 2017
		
		
		levelsof d_s, local(alls)
		levelsof industry_imp, local(alla)
		foreach s of local alls {
		foreach a of local alla {
		
			qui gen ip_s`s'_a`a' = ip_ppp17 if sample == 1 & lstatus_year==1 & industry_imp == `a' & d_s == `s' 
			
		}
		}
		
		qui gen ip_total  = ip_ppp17 if sample == 1 & lstatus_year==1
		qui gen ip_s1     = ip_ppp17 if sample == 1 & lstatus_year==1 & d_s == 1 
		qui gen ip_s0 	  = ip_ppp17 if sample == 1 & lstatus_year==1 & d_s == 0

		
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
		post `mypost' ("`country'") (`year') ("hspop_total") ("Population, total") (`poptotal') 

		* Population 00-14
		sum pop0014 [w=wgt]
		local pop0014 = `r(sum_w)'*`r(mean)'
		post `mypost' ("`country'") (`year') ("hspop_0014") ("Population, 00-14") (`pop0014')
		
		* Population 15-64
		sum pop1564 [w=wgt]
		local pop1564 = `r(sum_w)'*`r(mean)'
		post `mypost' ("`country'") (`year') ("hspop_1564") ("Population, 15-64") (`pop1564')
		
		* Population 65+
		sum pop65up [w=wgt]
		local pop65up = `r(sum_w)'*`r(mean)'
		post `mypost' ("`country'") (`year') ("hspop_65up") ("Population, 65+") (`pop65up')
		
		* Not in the labor force
		sum lstatus_year [w=wgt] if lstatus_year == 3 & sample == 1
		local lstatus3 = `r(sum_w)'
		post `mypost' ("`country'") (`year') ("lstatus3_1564") ("Not in Labor Force") (`lstatus3')

		* Unemployed
		sum lstatus_year [w=wgt] if lstatus_year == 2 & sample == 1 
		local lstatus2 = `r(sum_w)'
		post `mypost' ("`country'") (`year') ("lstatus2_1564") ("Unemployed") (`lstatus2')

		* Employment
		sum lstatus_year [w=wgt] if lstatus_year == 1 & sample == 1  
		local lstatus1 = `r(sum_w)'
		post `mypost' ("`country'") (`year') ("lstatus1_1564") ("Employed") (`lstatus1')

		* Labor Force
		sum wgt if (lstatus_year == 1|lstatus_year==2) & sample == 1
		local lstatus12 = `r(sum)'
		post `mypost' ("`country'") (`year') ("lstatus12_1564") ("Labor Foce") (`lstatus12')

		* Number of workers, across industries and type of workers
		foreach s of local alls {
		foreach a of local alla {
			qui sum lstatus1_s`s'_a`a'[w=wgt]
			local lstatus1_s`s'_a`a' = `r(sum_w)'*`r(mean)'
			
			local laba : label lblindustry_imp `a'
			local labs : label lbld_s `s'
			
			post `mypost' ("`country'") (`year') ("lstatus1_s`s'_a`a'") ("Workers `laba' `labs'") (`lstatus1_s`s'_a`a'')
		}
		}
		
		** Labor income (avg)
		************************
		qui sum ip_total [w=wgt]
		local ip_total = `r(mean)'
		post `mypost' ("`country'") (`year') ("ip_total") ("IP All") (`ip_total')

		foreach s of local alls {
		foreach a of local alla {
			qui sum ip_s`s'_a`a' [w=wgt] 
			local ip_s`s'_a`a' = `r(mean)'
			
			local laba : label lblindustry_imp `a'
			local labs : label lbld_s `s'			
			
			post `mypost' ("`country'") (`year') ("ip_s`s'_a`a'") ("Mean income in `laba' `labs'") (`ip_s`s'_a`a'')
		}
		}

		 di in red "`country' - `year' finished successfully"
	
	} // Close loop year
	
} // Close loop countries


	postclose `mypost'
	use  `myresults', clear
	
	compress
	save "$data_in/Tableau/AM_24 MPO Check/input-labor-hies.dta", replace
	save "$data_in/Tableau/AM_24 MPO Check/version_control/input-labor-hies `c(current_date)' `c(current_time)'.dta", replace
	
	export excel using "$data_in/Macro and elasticities/Working Input Elasticities.xlsx", sheet("input-labor-hies", replace) firstrow(variables)
	export excel using "$data_in/Macro and elasticities/Working Input Elasticities.xlsx", sheet("input-labor-hies", replace) firstrow(variables)

	
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
	
	
	
sdfdsfds
/*************************************************************************
* 	3 - ELASTICITIES INPUTS
*************************************************************************

use "$path\input-labor-sedlac.dta", clear
append using `macrodata'
sort Country Year Indicator
save "$path/$input_sedlac.dta", replace
*/
