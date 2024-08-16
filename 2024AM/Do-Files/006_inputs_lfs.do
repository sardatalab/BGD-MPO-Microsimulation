*!v1.1
/*========================================================================
Project:			Microsimulations Inputs from LABLAC
Institution:		World Bank - ELCPV

Author:				Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Creation Date:		07/24/2023

Last Modification:	Israel Osorio Rodarte (iosoriorodarte@worldbank.org)
Modification date: 	08/07/2024
========================================================================*/

drop _all

* NOTE: These inputs are in 2005 PPP for now since we haven´t fixed the ppp at 2017 yet.

**************************************************************************
* 	0 - SETTING
**************************************************************************

* Set up postfile for results
tempname mypost
tempfile myresults
postfile `mypost' str12(country) year str40(indicator) value str40(title) using `myresults', replace

/* Observations

*/

*************************************************************************
* 	1 - LFS DATA
*************************************************************************

foreach country in BGD { // Open loop countries
foreach year of numlist 2005 2010 2013 2015 2016 2022 { // Open loop year
foreach quarter	in q1 {	// Open loop quarters
		
	
		if "`country'" == "BGD" & `year' == 2002 continue // no weights capture use "$data_root/DLW/LFS/BGD_2002_LFS_v01_M_v01_A_SARLAB_IND.dta", clear
		if "`country'" == "BGD" & `year' == 2005 capture use "$data_root/DLW/LFS/BGD_2005_LFS_v01_M_v01_A_SARLAB_IND.dta", clear
		if "`country'" == "BGD" & `year' == 2010 capture use "$data_root/DLW/LFS/BGD_2010_LFS_v01_M_v01_A_SARLAB_IND.dta", clear
		if "`country'" == "BGD" & `year' == 2013 capture use "$data_root/DLW/LFS/BGD_2013_LFS_v01_M_v01_A_SARLAB_IND.dta", clear
		if "`country'" == "BGD" & `year' == 2015 capture use "$data_root/DLW/LFS/BGD_2015_QLFS_v01_M_v01_A_SARLAB_IND.dta", clear
		if "`country'" == "BGD" & `year' == 2016 capture use "$data_root/DLW/LFS/BGD_2016_QLFS_v01_M_v01_A_SARLAB_IND.dta", clear
		if "`country'" == "BGD" & `year' == 2022 capture use "$data_root/DLW/LFS/BGD_2022_QLFS_v01_M_v01_A_SARLAB_IND.dta", clear
	
		

	* REMINDER: Always filter for coherent households.
	*****************************************************
	qui cap keep if cohh==1
		
	
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
		replace d_s = 1 if occup>=1 & occup<=3 & lstatus==1 & sample==1
		replace d_s = 1 if occup==6 		   & lstatus==1 & sample==1
		replace d_s = 0 if ((occup==4|occup==5)|(occup>=7 & occup!=.)) & lstatus==1 & sample==1
		replace d_s = 0 if occup==. & educy<=9             & lstatus==1 & sample==1
		replace d_s = 1 if occup==. & educy>=10 & educy!=. & lstatus==1 & sample==1
		replace d_s = 0 if occup==. & educy==. 			& lstatus==1 & sample==1
	label define lbld_s 0 "Unskilled" 1 "Skilled"
	label values d_s lbld_s
	
	
	* Industry main occupation
	* activities a = {1..n}
	***************************
	gen industry_imp = .
		replace industry_imp = 1 if industrycat10==1	// agriculture
		replace industry_imp = 2 if industrycat10==5	// construction
		replace industry_imp = 3 if industrycat10==2|industrycat10==3	// rest of industry			
		replace industry_imp = 4 if industrycat10==7	// transport
		replace industry_imp = 5 if industrycat10==8	// financial
		replace industry_imp = 6 if industrycat10==4|industrycat10==6|industrycat10==9|industrycat10==10
		replace industry_imp = 6 if industrycat10==. & lstatus==1 // 7 observations
		
		* fix inconsistent industry with lstatus
		replace industry_imp = . if lstatus==2|lstatus==3
		
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
		egen double wage_total_all = rsum(wage_total wage_total_2 wage_total_o)	// Annualized wage
		replace wage_total_all = . if wage_total_all==0
		gen double ip_lcu = wage_total_all/12
		
		levelsof d_s, local(alls)
		levelsof industry_imp, local(alla)
		foreach s of local alls {
		foreach a of local alla {
		
			qui gen ip_s`s'_a`a' = ip_lcu if sample == 1 & lstatus==1 & industry_imp == `a' & d_s == `s' 
			
		}
		}
		
		qui gen ip_total  = ip_lcu if sample == 1 & lstatus==1
		qui gen ip_s1     = ip_lcu if sample == 1 & lstatus==1 & d_s == 1 
		qui gen ip_s0 	  = ip_lcu if sample == 1 & lstatus==1 & d_s == 0

	* Rename wgt
		rename weight wgt
			
	* Number of workers - formal/informal by sector
	**************************************************
		* Number of workers - formal/informal by sector
		**************************************************
		foreach s of local alls {
		foreach a of local alla {
			qui gen lstatus1_s`s'_a`a'  = (sample == 1 & lstatus==1 & industry_imp == `a' & d_s == `s')
		}
		}	
			
		* Estimations
		****************
		
		** Number of workers
		***********************

		* Total population
		sum poptotal [w=wgt]
		local poptotal = `r(sum_w)'
		post `mypost' ("`country'") (`year') ("lfpop_total")  (`poptotal') ("Population, total")

		* Population 00-14
		sum pop0014 [w=wgt]
		local pop0014 = `r(sum_w)'*`r(mean)'
		post `mypost' ("`country'") (`year') ("lfpop_0014") (`pop0014') ("Population, 00-14")
		
		* Population 15-64
		sum pop1564 [w=wgt]
		local pop1564 = `r(sum_w)'*`r(mean)'
		post `mypost' ("`country'") (`year') ("lfpop_1564") (`pop1564') ("Population, 15-64")
		
		* Population 65+
		sum pop65up [w=wgt]
		local pop65up = `r(sum_w)'*`r(mean)'
		post `mypost' ("`country'") (`year') ("lfpop_65up") (`pop65up') ("Population, 65+")
		
		* Not in the labor force
		sum lstatus [w=wgt] if lstatus == 3 & sample == 1
		local lstatus3 = `r(sum_w)'
		post `mypost' ("`country'") (`year') ("lflstatus3_1564") (`lstatus3') ("Not in Labor Force") 

		* Unemployed
		sum lstatus [w=wgt] if lstatus == 2 & sample == 1 
		local lstatus2 = `r(sum_w)'
		post `mypost' ("`country'") (`year') ("lflstatus2_1564") (`lstatus2') ("Unemployed") 
		* Employment
		sum lstatus [w=wgt] if lstatus == 1 & sample == 1  
		local lstatus1 = `r(sum_w)'
		post `mypost' ("`country'") (`year') ("lflstatus1_1564") (`lstatus1') ("Employed") 
		
		* Labor Force
		sum wgt if (lstatus == 1|lstatus==2) & sample == 1
		local lstatus12 = `r(sum)'
		post `mypost' ("`country'") (`year') ("lflstatus12_1564") (`lstatus12') ("Labor Foce") 

		* Number of workers, across industries and type of workers
		foreach s of local alls {
		foreach a of local alla {
			sum lstatus1_s`s'_a`a'[w=wgt]
			
			if `r(sum_w)'> 0 local lstatus1_s`s'_a`a' = `r(sum_w)'*`r(mean)'
			if `r(sum_w)'==0 local lstatus1_s`s'_a`a' = `r(sum_w)'
			
			local laba : label lblindustry_imp `a'
			local labs : label lbld_s `s'
			
			post `mypost' ("`country'") (`year') ("lflstatus1_s`s'_a`a'") (`lstatus1_s`s'_a`a'') ("Workers `laba' `labs'") 
		}
		}
		
		** Labor income (avg)
		************************
		sum ip_total [w=wgt]
		local ip_total = `r(mean)'
		post `mypost' ("`country'") (`year') ("lfip_total") (`ip_total') ("IP All")

		foreach s of local alls {
		foreach a of local alla {
			
			sum ip_s`s'_a`a' [w=wgt] 
			if `r(sum_w)'> 0 local ip_s`s'_a`a' = `r(mean)'
			if `r(sum_w)'==0 local ip_s`s'_a`a' = .
			
			local laba : label lblindustry_imp `a'
			local labs : label lbld_s `s'			
			
			post `mypost' ("`country'") (`year') ("lfip_s`s'_a`a'") (`ip_s`s'_a`a'') ("Mean income in `laba' `labs'") 
		}
		}

		 di in red "`country' - `year' finished successfully"
		 clear

} // Close loop quarters
} // Close loop year	
} // Close loop countries


postclose `mypost'
use  `myresults', clear
compress

save "$data_in/Tableau/AM_24 MPO Check/input-labor-lfs.dta", replace
save "$data_in/Tableau/AM_24 MPO Check/version_control/input-labor-lfs `c(current_date)'.dta", replace


*************************************************************************
* 	3 - ELASTICITIES INPUTS
*************************************************************************
use "$data_in/Tableau/AM_24 MPO Check/input-labor-lfs.dta", clear

append using "$data_in/Macro and elasticities/mfmod_bgd.dta"

sort country year indicator
save "$data_in/Macro and elasticities/input_elasticities_lfs.dta", replace
