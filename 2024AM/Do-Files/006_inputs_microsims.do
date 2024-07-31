
/*========================================================================
Project:			Microsimulations Inputs from simulated data
Institution:		World Bank - ELCPV

Author:				Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Creation Date:		07/24/2023

Last Modification:	Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Modification date:  07/28/2023 
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
* 	1 - DATA
*************************************************************************

* IMPORTANT!! there is microsimulated data in datalib, it should be excluded from this dofile and incorporated in the database using do file 02.

local files : dir "$data" files "*.dta", respectcase
foreach file of local files { // Open loop files
	
	
		* Loading the data
		
		qui use "${data}/`file'", clear
		
		* Country and year
		*********************
		local country = substr("`file'",1,3)
		local year = substr("`file'",5,4)
		
		di in red "File `country' - `year' uploaded successfully"
		
		* REMINDER: Always filter for coherent households.
		*****************************************************
		qui cap keep if cohh==1 & pc_inc_s !=.
		
		* Defining sample 
		********************
		cap drop sample
		qui gen sample = edad > 14 & edad < 65 
		
		* PEA
		********
		ren pea pea_orig
		qui gen pea = occupation_s != 0 if occupation_s != . & sample == 1
		
		* Worker
		***********
		ren ocupado ocupado_orig
		qui gen ocupado = inrange(occupation_s,2,7) if occupation_s != . & sample == 1
		
		* Unemployed
		***************
		ren desocupa desocupa_orig
		qui gen desocupa = occupation_s == 1 if occupation_s != . & sample == 1
		
		* Informality
		****************
		qui cap drop d_informal
		qui gen d_informal = .
		qui replace d_informal = inlist(occupation_s,3,5,7) if !inlist(occupation_s,0,1,.) & sample == 1

		* Sector main occupation
		***************************
		qui gen sector_3 = 1 if inlist(occupation_s,2,3) & !inlist(occupation_s,0,1,.) & sample == 1
		qui replace sector_3 = 2 if inlist(occupation_s,4,5) & !inlist(occupation_s,0,1,.) & sample == 1
		qui replace sector_3 = 3 if inlist(occupation_s,6,7) & !inlist(occupation_s,0,1,.) & sample == 1
	
		* Labor income - formal/informal by sector and total
		*******************************************************
		qui gen ip_formal_ag = lai_m_s if sample == 1 & ocupado == 1 & sector_3 == 1 & d_informal == 0 
		qui gen ip_informal_ag = lai_m_s if sample == 1 & ocupado == 1 & sector_3 == 1 & d_informal == 1 
		qui gen ip_formal_ind = lai_m_s if sample == 1 & ocupado == 1 & sector_3 == 2 & d_informal == 0 
		qui gen ip_informal_ind = lai_m_s if sample == 1 & ocupado == 1 & sector_3 == 2 & d_informal == 1 
		qui gen ip_formal_ser = lai_m_s if sample == 1 & ocupado == 1 & sector_3 == 3 & d_informal == 0 
		qui gen ip_informal_ser = lai_m_s if sample == 1 & ocupado == 1 & sector_3 == 3 & d_informal == 1
		qui gen ip_total = lai_m_s if sample == 1 & ocupado == 1 
		qui gen ip_formal = lai_m_s if sample == 1 & ocupado == 1 & d_informal == 0 
		qui gen ip_informal = lai_m_s if sample == 1 & ocupado == 1 & d_informal == 1
		
		* Number of workers - formal/informal by sector
		**************************************************
		qui gen ocupado_formal_ag = (sample == 1 & sector_3 == 1 & d_informal == 0)
		qui gen ocupado_informal_ag = (sample == 1 & sector_3 == 1 & d_informal == 1 )
		qui gen ocupado_formal_ind = (sample == 1 & sector_3 == 2 & d_informal == 0 )
		qui gen ocupado_informal_ind = (sample == 1 & sector_3 == 2 & d_informal == 1 )
		qui gen ocupado_formal_ser =  (sample == 1 & sector_3 == 3 & d_informal == 0)
		qui gen ocupado_informal_ser = (sample == 1 & sector_3 == 3 & d_informal == 1)
		
		
		* Estimations
		****************
		
		** Number of workers
		***********************

		* Total population
		qui sum pea [w=fexp_s] if sample == 1
		local pea = `r(sum_w)'
		post `mypost' ("`country'") (`year') ("Total population") (`pea')
 
		* Active population
		qui sum pea [w=fexp_s] if pea == 1 & sample == 1
		local active = `r(sum_w)'
		post `mypost' ("`country'") (`year') ("Active population") (`active')

		* Inactive population
		qui sum pea [w=fexp_s] if pea == 0 & sample == 1 
		local inactive = `r(sum_w)'
		post `mypost' ("`country'") (`year') ("Inactive population") (`inactive')

		* Workers
		qui sum ocupado [w=fexp_s] if ocupado == 1 & sample == 1  
		local employed = `r(sum_w)'
		post `mypost' ("`country'") (`year') ("Working population") (`employed')

		* Unemployed
		qui sum desocupa  [w=fexp_s] if desocupa == 1 & sample == 1 
		local unemployed = `r(sum_w)'
		post `mypost' ("`country'") (`year') ("Unemployed population") (`unemployed')

		* Agriculture
		qui sum ocupado_formal_ag [w=fexp_s] if ocupado_formal_ag==1
		local ocuformag3 = `r(sum_w)'
		post `mypost' ("`country'") (`year') ("Formal workers agriculture") (`ocuformag3')
						
		qui sum ocupado_informal_ag [w=fexp_s] if ocupado_informal_ag==1
		local ocuinfag3 = `r(sum_w)'
		post `mypost' ("`country'") (`year') ("Informal workers agriculture") (`ocuinfag3')

		* Industry		
		qui sum ocupado_formal_ind [w=fexp_s] if ocupado_formal_ind==1
		local ocuformind3 = `r(sum_w)'
		post `mypost' ("`country'") (`year') ("Formal workers industry") (`ocuformind3')
					
		qui sum ocupado_informal_ind [w=fexp_s] if  ocupado_informal_ind==1
		local ocuinfind3 = `r(sum_w)'
		post `mypost' ("`country'") (`year') ("Informal workers industry") (`ocuinfind3')

		* Services	
		qui sum ocupado_formal_ser [w=fexp_s] if ocupado_formal_ser==1
		local ocuformser3 = `r(sum_w)'
		post `mypost' ("`country'") (`year') ("Formal workers services") (`ocuformser3')

		qui sum ocupado_informal_ser [w=fexp_s] if ocupado_informal_ser==1
		local ocuinfser3 = `r(sum_w)'
		post `mypost' ("`country'") (`year') ("Informal workers services") (`ocuinfser3')

		
		** Labor income (avg)
		************************
		qui sum ip_total [w=fexp_s]
		local ocutot = `r(mean)'
		post `mypost' ("`country'") (`year') ("Avg. income") (`ocutot')

		qui sum ip_formal [w=fexp_s] 
		local ocuform = `r(mean)'
		post `mypost' ("`country'") (`year') ("Avg. formal income") (`ocuform')

		qui sum ip_informal [w=fexp_s] 
		local ocuinf = `r(mean)'
		post `mypost' ("`country'") (`year') ("Avg. informal income") (`ocuinf')

		qui sum ip_formal_ag [w=fexp_s] 
		local ocuformag = `r(mean)'
		post `mypost' ("`country'") (`year') ("Avg. formal income agriculture") (`ocuformag')

		qui sum ip_informal_ag [w=fexp_s] 
		local ocuinfag = `r(mean)'
		post `mypost' ("`country'") (`year') ("Avg. informal income agriculture") (`ocuinfag')
				
		qui sum ip_formal_ind [w=fexp_s] 
		local ocuformind = `r(mean)'
		post `mypost' ("`country'") (`year') ("Avg. formal income industry") (`ocuformind')
			
		qui sum ip_informal_ind [w=fexp_s] 
		local ocuinfind = `r(mean)'
		post `mypost' ("`country'") (`year') ("Avg. informal income industry") (`ocuinfind')
		
		qui sum ip_formal_ser [w=fexp_s] 
		local ocuformser = `r(mean)'
		post `mypost' ("`country'") (`year') ("Avg. formal income services") (`ocuformser')

		qui sum ip_informal_ser [w=fexp_s] 
		local ocuinfser = `r(mean)'
		post `mypost' ("`country'") (`year') ("Avg. informal income services") (`ocuinfser')


		 di in red "`country' - `year' finished successfully"

} // Close loop files


postclose `mypost'
use  `myresults', clear
compress
qui save "$path\input-labor-microsimulated.dta", replace
qui save "$path\inputs_version_control\input-labor-microsimulated_${version}.dta", replace
export excel using "$path_mpo/$outfile", sheet("input-labor-microsimulated") sheetreplace firstrow(variables)
export excel using "$path_share/$outfile", sheet("input-labor-microsimulated") sheetreplace firstrow(variables)
