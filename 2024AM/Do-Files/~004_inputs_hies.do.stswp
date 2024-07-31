*!v1.0
/*========================================================================
Project:			Microsimulations Inputs from HEIS
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
postfile `mypost' str12(Country) Year str40(Indicator) Value using `myresults', replace


*************************************************************************
* 	1 - HEIS DATA
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
			
		* REMINDER: Always filter for coherent households.
		*****************************************************
		gen byte cohh = (welfare>0)
		qui cap keep if cohh==1 & ipcf!=.
		qui cap keep if ipcf!=.
		
		
		* Defining sample 
		********************
		cap drop sample
		qui gen sample = (lstatus_year==1 & age >= 15 & age < 64) 
		
		* Two types of workers s0 and s1
		*********************************		
		qui cap drop d_s0
		qui gen d_s0 = .
		
		** BGD
		if inlist("`country'","BGD") {
			qui replace d_s0 = 1 if occup_year>=4 & occup_year!=. & lstatus_year==1
			qui replace d_s0 = 0 if occup_year>=1 & occup_year<=3 & lstatus_year==1
		} 
		
}
		
		
		* Sector main occupation
		***************************
		
		*Important!!! check this definition for all countries - some do not have sector1d but sector
		
		if "`country'" == "PRY" {
			qui recode sector (1=1 "Agriculture") (2 3 4 =2 "Industry") (5 6 7 8 9 10 =3 "Services") , gen(sector_3)
		} // This is new. PRY doesn't have available the variable sector1d from 2014 on.
		else {
			qui recode sector1d (1 2 =1 "Agriculture") (3 4 5 6 =2 "Industry") (7 8 9 10 11 12 13 14 15 16 17 =3 "Services"), gen(sector_3)
		}
		

		* Labor income - formal/informal by sector and total
		*******************************************************
		qui gen ip_ppp17 = ip * (ipc17_sedlac / ipc_sedlac) / (ppp17 * conversion) if cohi == 1 // Labor income main activity ppp 2017
		
		qui gen ip_s1_ag = ip_ppp17 if sample == 1 & ocupado == 1 & sector_3 == 1 & d_s0 == 0 
		qui gen ip_s0_ag = ip_ppp17 if sample == 1 & ocupado == 1 & sector_3 == 1 & d_s0 == 1 
		qui gen ip_s1_ind = ip_ppp17 if sample == 1 & ocupado == 1 & sector_3 == 2 & d_s0 == 0 
		qui gen ip_s0_ind = ip_ppp17 if sample == 1 & ocupado == 1 & sector_3 == 2 & d_s0 == 1 
		qui gen ip_s1_ser = ip_ppp17 if sample == 1 & ocupado == 1 & sector_3 == 3 & d_s0 == 0 
		qui gen ip_s0_ser = ip_ppp17 if sample == 1 & ocupado == 1 & sector_3 == 3 & d_s0 == 1
		qui gen ip_total = ip_ppp17 if sample == 1 & ocupado == 1 
		qui gen ip_s1 = ip_ppp17 if sample == 1 & ocupado == 1 & d_s0 == 0 
		qui gen ip_s0 = ip_ppp17 if sample == 1 & ocupado == 1 & d_s0 == 1

		
		* Number of workers - formal/informal by sector
		**************************************************
		qui gen ocupado_s1_ag = (sample == 1 & ocupado == 1 & sector_3 == 1 & d_s0 == 0)
		qui gen ocupado_s0_ag = (sample == 1 & ocupado == 1 & sector_3 == 1 & d_s0 == 1 )
		qui gen ocupado_s1_ind = (sample == 1 & ocupado == 1 & sector_3 == 2 & d_s0 == 0 )
		qui gen ocupado_s0_ind = (sample == 1 & ocupado == 1 & sector_3 == 2 & d_s0 == 1 )
		qui gen ocupado_s1_ser =  (sample == 1 & ocupado == 1 & sector_3 == 3 & d_s0 == 0)
		qui gen ocupado_s0_ser = (sample == 1 & ocupado == 1 & sector_3 == 3 & d_s0 == 1)
		
		
		* Estimations
		****************
		
		** Number of workers
		***********************

		* Total population
		qui sum pea [w=pondera] if sample == 1
		local pea = `r(sum_w)'
		post `mypost' ("`country'") (`year') ("Total population") (`pea')
 
		* Active population
		qui sum pea [w=pondera] if pea == 1 & sample == 1
		local active = `r(sum_w)'
		post `mypost' ("`country'") (`year') ("Active population") (`active')

		* Inactive population
		qui sum pea [w=pondera] if pea == 0 & sample == 1 
		local inactive = `r(sum_w)'
		post `mypost' ("`country'") (`year') ("Inactive population") (`inactive')

		* Workers
		qui sum ocupado [w=pondera] if ocupado == 1 & sample == 1  
		local employed = `r(sum_w)'
		post `mypost' ("`country'") (`year') ("Working population") (`employed')

		* Unemployed
		qui sum desocupa  [w=pondera] if desocupa == 1 & sample == 1 
		local unemployed = `r(sum_w)'
		post `mypost' ("`country'") (`year') ("Unemployed population") (`unemployed')

		* Agriculture
		qui sum ocupado_s1_ag [w=pondera] if ocupado_s1_ag==1
		local ocuformag3 = `r(sum_w)'
		post `mypost' ("`country'") (`year') ("Formal workers agriculture") (`ocuformag3')
						
		qui sum ocupado_s0_ag [w=pondera] if ocupado_s0_ag==1
		local ocuinfag3 = `r(sum_w)'
		post `mypost' ("`country'") (`year') ("Informal workers agriculture") (`ocuinfag3')

		* Industry		
		qui sum ocupado_s1_ind [w=pondera] if ocupado_s1_ind==1
		local ocuformind3 = `r(sum_w)'
		post `mypost' ("`country'") (`year') ("Formal workers industry") (`ocuformind3')
					
		qui sum ocupado_s0_ind [w=pondera] if  ocupado_s0_ind==1
		local ocuinfind3 = `r(sum_w)'
		post `mypost' ("`country'") (`year') ("Informal workers industry") (`ocuinfind3')

		* Services	
		qui sum ocupado_s1_ser [w=pondera] if ocupado_s1_ser==1
		local ocuformser3 = `r(sum_w)'
		post `mypost' ("`country'") (`year') ("Formal workers services") (`ocuformser3')

		qui sum ocupado_s0_ser [w=pondera] if ocupado_s0_ser==1
		local ocuinfser3 = `r(sum_w)'
		post `mypost' ("`country'") (`year') ("Informal workers services") (`ocuinfser3')

		
		** Labor income (avg)
		************************
		qui sum ip_total [w=pondera]
		local ocutot = `r(mean)'
		post `mypost' ("`country'") (`year') ("Avg. income") (`ocutot')

		qui sum ip_s1 [w=pondera] 
		local ocuform = `r(mean)'
		post `mypost' ("`country'") (`year') ("Avg. formal income") (`ocuform')

		qui sum ip_s0 [w=pondera] 
		local ocuinf = `r(mean)'
		post `mypost' ("`country'") (`year') ("Avg. informal income") (`ocuinf')

		qui sum ip_s1_ag [w=pondera] 
		local ocuformag = `r(mean)'
		post `mypost' ("`country'") (`year') ("Avg. formal income agriculture") (`ocuformag')

		qui sum ip_s0_ag [w=pondera] 
		local ocuinfag = `r(mean)'
		post `mypost' ("`country'") (`year') ("Avg. informal income agriculture") (`ocuinfag')
				
		qui sum ip_s1_ind [w=pondera] 
		local ocuformind = `r(mean)'
		post `mypost' ("`country'") (`year') ("Avg. formal income industry") (`ocuformind')
			
		qui sum ip_s0_ind [w=pondera] 
		local ocuinfind = `r(mean)'
		post `mypost' ("`country'") (`year') ("Avg. informal income industry") (`ocuinfind')
		
		qui sum ip_s1_ser [w=pondera] 
		local ocuformser = `r(mean)'
		post `mypost' ("`country'") (`year') ("Avg. formal income services") (`ocuformser')

		qui sum ip_s0_ser [w=pondera] 
		local ocuinfser = `r(mean)'
		post `mypost' ("`country'") (`year') ("Avg. informal income services") (`ocuinfser')


		 di in red "`country' - `year' finished successfully"
	
	} // Close loop year
	
} // Close loop countries


postclose `mypost'
use  `myresults', clear
compress
save "$path\input-labor-sedlac.dta", replace
save "$path\inputs_version_control\input-labor-sedlac_${version}.dta", replace
export excel using "$path_mpo/$outfile", sheet("input-labor-sedlac") sheetreplace firstrow(variables)
export excel using "$path_share/$outfile", sheet("input-labor-sedlac") sheetreplace firstrow(variables)

*************************************************************************
* 	2 - MPO DATA
*************************************************************************

* Loading the MPO data
use "$povmod", clear

* Keep only countries of interest
keep if inlist(countrycode,"ARG","BOL","BRA","CHL","COL","CRI","DOM") | inlist(countrycode,"ECU","SLV","HND","MEX","NIC","PER","PRY") | inlist(countrycode,"PAN","URY","GTM")

* Keep last version
tab date
gen date1=date(date,"MDY")
egen datem= max(date1)
keep if date1 == datem
tab date

* Keep variables of interes
keep year countrycode gdpconstant agriconstant indusconstant servconstant

ren *constant Value*

reshape long Value, i(country year) j(Indicator) string
ren (countrycode year) (Country Year)

order Country Year Indicator Value
sort Country Year Indicator Value

tempfile macrodata
save `macrodata', replace


*************************************************************************
* 	3 - ELASTICITIES INPUTS
*************************************************************************

use "$path\input-labor-sedlac.dta", clear
append using `macrodata'
sort Country Year Indicator
save "$path/$input_sedlac.dta", replace

