
/*========================================================================
Project:			Microsimulations Inputs from LABLAC
Institution:		World Bank - ELCPV

Author:				Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Creation Date:		07/24/2023

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date: 	07/25/2023
========================================================================*/

drop _all

* NOTE: These inputs are in 2005 PPP for now since we haven´t fixed the ppp at 2017 yet.

**************************************************************************
* 	0 - SETTING
**************************************************************************

* Set up postfile for results
tempname mypost
tempfile myresults
postfile `mypost' str12(Country) Year str40(Indicator) Value using `myresults', replace

/* Observations
ARG 2016q02 is in ppp05
BRA doesn´t have the variables to construct informality
CHL only has labor income for q04
COL 2022 doesn´t have income
CRI doesn´t have variables for sector
MEX 2020q03 needs revision.
PER doesn´t have djubila
PRY doesn´t have sector 
*/

*************************************************************************
* 	1 - LABLAC DATA
*************************************************************************

foreach country of local countries_lablac { // Open loop countries
foreach year of numlist ${init_year_lablac} / ${end_year_lablac} { // Open loop year
foreach quarter	of local quarters {	// Open loop quarters
		
	* Loading the data
	
	if "`country'" == "ARG" & `year' == 2016 & "`quarter'" == "q02" continue
	if "`country'" == "CHL" & "`quarter'" != "q04" continue
	if "`country'" == "COL" & `year' == 2022 continue
	if "`country'" == "MEX" & `year' == 2020 & "`quarter'" == "q03" continue
	
	else capture datalib, country(`country') year(`year') period(`quarter') type(lablac) noppp clear
			
	if _rc==0 di in red "`country' `year' `quarter' loaded in datalib"
	else {
		di in red "`country' `year' `quarter' NOT loaded in datalib"
		continue
	}
		
	
	* REMINDER: Always filter for coherent households.
	*****************************************************
	qui cap keep if cohh==1
		
	
	* Defining sample 
	********************
	cap drop sample
	qui gen sample = edad > 14 & edad < 65 

		
	* Informality
	****************
		
	*Important!!! check this definition for all countries
		
	qui cap drop d_informal
	qui gen d_informal = .
		
	** BOL, CHL, COL, CRI, DOM, ECU, SLV, GTM, HND, NIC, PAN, PRY, PER, URY - Workers who do NOT receive a pension
	if inlist("`country'","BOL","CHL","COL","CRI","DOM","ECU","SLV") {
		qui replace d_informal = djubila == 0 if djubila != .
		qui replace d_informal = . if sample != 1 | ocupado != 1 | !inrange(relab,1,4)
	}
	
	if inlist("`country'","GTM","HND","NIC","PAN","PRY","PER","URY") | ("`country'"=="BRA" & `year' < 2012) {
		qui replace d_informal = djubila == 0 if djubila != .
		qui replace d_informal = . if sample != 1 | ocupado != 1 | !inrange(relab,1,4)
	}
	
	** MEX - Workers who do NOT receive health insurance benefits
	if "`country'" == "MEX" {
		qui replace d_informal = dsegsale == 0 if dsegsale != .
		qui replace d_informal = . if sample != 1 | ocupado != 1 | !inrange(relab,1,4)
	}
		
	** ARG, HTI - Workers who do NOT receive a pension. For non-salaried: workers who have NOT completed tertiary education
	if inlist("`country'","ARG","arg","HTI","hti") {
		qui replace d_informal =  djubila == 0 if djubila != .
		qui replace d_informal = 0 if d_informal == . & inlist(relab,1,3,4)
		qui replace d_informal = 1 if inlist(relab,1,3,4) & nivel != 6
		qui replace d_informal = . if sample != 1 | ocupado != 1 | !inrange(relab,1,4)
	} 
	
	** BRA - Definition from BRA PE (based on dofiles for transfers)	
	if inlist("`country'","bra", "BRA") & `year' >= 2012 {
		cap drop formalbr
		qui gen formalbr = 0 if vd4002 == 1
		qui replace formalbr = 1 if vd4009 == 1 | vd4009 == 3 | vd4009 == 5 | vd4009 == 7 
		qui replace formalbr = 1 if  ( vd4009 == 8 | vd4009 == 9 ) & /*v4019 == 1 &*/ vd4012 == 1 
		qui replace d_informal = formalbr == 0 if djubila != .
		qui replace d_informal = . if sample != 1 | ocupado != 1 | !inrange(relab,1,4)
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
	*qui gen ip_ppp17 = ip * (17 / ipc_lablac) / (ppp17 * conversion) if cohi == 1 // Labor income main activity ppp 2017
		
	qui gen ip_formal_ag = ip_ppp17 if sample == 1 & ocupado == 1 & sector_3 == 1 & d_informal == 0 
	qui gen ip_informal_ag = ip_ppp17 if sample == 1 & ocupado == 1 & sector_3 == 1 & d_informal == 1 
	qui gen ip_formal_ind = ip_ppp17 if sample == 1 & ocupado == 1 & sector_3 == 2 & d_informal == 0 
	qui gen ip_informal_ind = ip_ppp17 if sample == 1 & ocupado == 1 & sector_3 == 2 & d_informal == 1 
	qui gen ip_formal_ser = ip_ppp17 if sample == 1 & ocupado == 1 & sector_3 == 3 & d_informal == 0 
	qui gen ip_informal_ser = ip_ppp17 if sample == 1 & ocupado == 1 & sector_3 == 3 & d_informal == 1
	qui gen ip_total = ip_ppp17 if sample == 1 & ocupado == 1 
	qui gen ip_formal = ip_ppp17 if sample == 1 & ocupado == 1 & d_informal == 0 
	qui gen ip_informal = ip_ppp17 if sample == 1 & ocupado == 1 & d_informal == 1

			
	* Number of workers - formal/informal by sector
	**************************************************
	qui gen ocupado_formal_ag = (sample == 1 & ocupado == 1 & sector_3 == 1 & d_informal == 0)
	qui gen ocupado_informal_ag = (sample == 1 & ocupado == 1 & sector_3 == 1 & d_informal == 1 )
	qui gen ocupado_formal_ind = (sample == 1 & ocupado == 1 & sector_3 == 2 & d_informal == 0 )
	qui gen ocupado_informal_ind = (sample == 1 & ocupado == 1 & sector_3 == 2 & d_informal == 1 )
	qui gen ocupado_formal_ser =  (sample == 1 & ocupado == 1 & sector_3 == 3 & d_informal == 0)
	qui gen ocupado_informal_ser = (sample == 1 & ocupado == 1 & sector_3 == 3 & d_informal == 1)
	
			
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
	qui sum ocupado_formal_ag [w=pondera] if ocupado_formal_ag==1
	local ocuformag3 = `r(sum_w)'
	post `mypost' ("`country'") (`year') ("Formal workers agriculture") (`ocuformag3')
				
	qui sum ocupado_informal_ag [w=pondera] if ocupado_informal_ag==1
	local ocuinfag3 = `r(sum_w)'
	post `mypost' ("`country'") (`year') ("Informal workers agriculture") (`ocuinfag3')

	* Industry		
	qui sum ocupado_formal_ind [w=pondera] if ocupado_formal_ind==1
	local ocuformind3 = `r(sum_w)'
	post `mypost' ("`country'") (`year') ("Formal workers industry") (`ocuformind3')
					
	qui sum ocupado_informal_ind [w=pondera] if  ocupado_informal_ind==1
	local ocuinfind3 = `r(sum_w)'
	post `mypost' ("`country'") (`year') ("Informal workers industry") (`ocuinfind3')

	* Services	
	qui sum ocupado_formal_ser [w=pondera] if ocupado_formal_ser==1
	local ocuformser3 = `r(sum_w)'
	post `mypost' ("`country'") (`year') ("Formal workers services") (`ocuformser3')

	qui sum ocupado_informal_ser [w=pondera] if ocupado_informal_ser==1
	local ocuinfser3 = `r(sum_w)'
	post `mypost' ("`country'") (`year') ("Informal workers services") (`ocuinfser3')


	** Labor income (avg)
	************************
	qui sum ip_total [w=pondera]
	local ocutot = `r(mean)'
	post `mypost' ("`country'") (`year') ("Avg. income") (`ocutot')

	qui sum ip_formal [w=pondera] 
	local ocuform = `r(mean)'
	post `mypost' ("`country'") (`year') ("Avg. formal income") (`ocuform')

	qui sum ip_informal [w=pondera] 
	local ocuinf = `r(mean)'
	post `mypost' ("`country'") (`year') ("Avg. informal income") (`ocuinf')

	qui sum ip_formal_ag [w=pondera] 
	local ocuformag = `r(mean)'
	post `mypost' ("`country'") (`year') ("Avg. formal income agriculture") (`ocuformag')

	qui sum ip_informal_ag [w=pondera] 
	local ocuinfag = `r(mean)'
	post `mypost' ("`country'") (`year') ("Avg. informal income agriculture") (`ocuinfag')
		
	qui sum ip_formal_ind [w=pondera] 
	local ocuformind = `r(mean)'
	post `mypost' ("`country'") (`year') ("Avg. formal income industry") (`ocuformind')

	qui sum ip_informal_ind [w=pondera] 
	local ocuinfind = `r(mean)'
	post `mypost' ("`country'") (`year') ("Avg. informal income industry") (`ocuinfind')

	qui sum ip_formal_ser [w=pondera] 
	local ocuformser = `r(mean)'
	post `mypost' ("`country'") (`year') ("Avg. formal income services") (`ocuformser')

	qui sum ip_informal_ser [w=pondera] 
	local ocuinfser = `r(mean)'
	post `mypost' ("`country'") (`year') ("Avg. informal income services") (`ocuinfser')

	di in red "`country' - `year' finished successfully"

} // Close loop quarters
} // Close loop year	
} // Close loop countries


postclose `mypost'
use  `myresults', clear
compress
collapse Value, by(Country Year Indicator)
save "$path\input-labor-lablac.dta", replace
save "$path\inputs_version_control\input-labor-lablac_${version}.dta", replace


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

use "$path\input-labor-lablac.dta", clear
append using `macrodata'
sort Country Year Indicator
save "$path/$input_lablac.dta", replace

