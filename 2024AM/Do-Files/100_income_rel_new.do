*!v1.0
*===========================================================================
* TITLE: 11 - Income growth by sector
*===========================================================================
* Prepared by: Sergio Olivieri
* E-mail: solivieri@worldbank.org
*===========================================================================
* Created on : Mar 17, 2020
* Last update: Oct 18, 2021 Kelly Y. Montoya. 
*===========================================================================

*===========================================================================
* Getting reduction in informal workers because of quarantine 
*===========================================================================
/*
if $t == 2 {

   replace lai_m_s = lai_m * (1 - (lai_m * ( $redu )/(lai_m * 12))) if informal_s == 1

} */
*===========================================================================
* I. Calculates the growth rate by sector of total labor income 
*    (main and secondary for everybody)
*===========================================================================

  capture drop sectorg
  clonevar sectorg = industry6


sum sectorg
loc lim = r(max)

forvalues i = 1/`lim' {
	
	//Base
	sum lai_m     [aw = wgt]  if lai_m > 0 & lai_m < . & sectorg    == `i' 
	sca sp_`i' = r(mean)

	//Scenario
	sum lai_m_s [aw = fexp_s]  if lai_m_s > 0 & lai_m_s < . & sect_main6_s== `i' 
	sca sp1_`i' = r(mean)

	if `i' == 1 { 
		mat var0 = sp_`i' 
		mat var1 = sp1_`i' 
		mat list var0
		mat list var1
	}

	if `i' != 1 {
		mat var0 = var0\sp_`i'
		mat var1 = var1\sp1_`i' 
		mat list var0
		mat list var1
	
	} 
}


*===========================================================================
* Calculates the difference between simulated and projected income growth rates by sector (This uses income projected with elasticities - input_gdp2)
*===========================================================================

sum sect_main6
loc lim2 = r(max)

mat growth_ila_rel = growth_labor_income[1..`lim2',1]

mat list growth_ila_rel 
mata:
M = st_matrix("var0")
V = st_matrix("growth_ila_rel")
C = st_matrix("var1")
G = M:*(1:+V)
H = (G:/C):-1
st_matrix("growth_ila_rel_n",H)
end

mat list growth_ila_rel_n


*===========================================================================
* Expands income labor by sector
*===========================================================================

clonevar lai_s_s = lai_s 

//Main
   replace lai_m_s = lai_m_s * (1 + growth_ila_rel_n[1,1]) if lai_m_s > 0 & lai_m_s != .   & sect_main6_s == 1 
   replace lai_m_s = lai_m_s * (1 + growth_ila_rel_n[2,1]) if lai_m_s > 0 & lai_m_s != .   & sect_main6_s == 2 
   replace lai_m_s = lai_m_s * (1 + growth_ila_rel_n[3,1]) if lai_m_s > 0 & lai_m_s != .   & sect_main6_s == 3 
   replace lai_m_s = lai_m_s * (1 + growth_ila_rel_n[4,1]) if lai_m_s > 0 & lai_m_s != .   & sect_main6_s == 4 
   replace lai_m_s = lai_m_s * (1 + growth_ila_rel_n[5,1]) if lai_m_s > 0 & lai_m_s != .   & sect_main6_s == 5 
   replace lai_m_s = lai_m_s * (1 + growth_ila_rel_n[6,1]) if lai_m_s > 0 & lai_m_s != .   & sect_main6_s == 6 
 
//Secondary 
   replace lai_s_s = lai_s_s * (1 + growth_ila_rel_n[1,1]) if lai_s_s > 0 & lai_s_s != .   & sectorg == 1 
   replace lai_s_s = lai_s_s * (1 + growth_ila_rel_n[2,1]) if lai_s_s > 0 & lai_s_s != .   & sectorg == 2 
   replace lai_s_s = lai_s_s * (1 + growth_ila_rel_n[3,1]) if lai_s_s > 0 & lai_s_s != .   & sectorg == 3 
   replace lai_s_s = lai_s_s * (1 + growth_ila_rel_n[4,1]) if lai_s_s > 0 & lai_s_s != .   & sectorg == 4 
   replace lai_s_s = lai_s_s * (1 + growth_ila_rel_n[5,1]) if lai_s_s > 0 & lai_s_s != .   & sectorg == 5 
   replace lai_s_s = lai_s_s * (1 + growth_ila_rel_n[6,1]) if lai_s_s > 0 & lai_s_s != .   & sectorg == 6 
  

* Check the variations
forvalues i = 1/`lim' {
	sum lai_m_s [aw = fexp_s] if lai_m_s > 0 & lai_m_s < . & sect_main6_s == `i' 
	sca sp2_`i' = r(mean)
	//sca s1_`i' = scalar(sp_`i') + scalar(ss_`i')
}
mat n =   scalar(sp2_1)/scalar(sp_1)-1
mat n = n\scalar(sp2_2)/scalar(sp_2)-1
mat n = n\scalar(sp2_3)/scalar(sp_3)-1
mat n = n\scalar(sp2_4)/scalar(sp_4)-1
mat n = n\scalar(sp2_5)/scalar(sp_5)-1
mat n = n\scalar(sp2_6)/scalar(sp_6)-1

mat diff  = growth_ila_rel - n
mat check = growth_ila_rel,n,diff
mat list check


*===========================================================================
* Re-scale all incomes by the average income 
*===========================================================================

sum	lai_m [aw = wgt] if lai_m > 0 & lai_m != . & sect_main6 != .
loc tot_ila_s = r(mean)
sum lai_m_s [aw = fexp_s] if lai_m_s > 0 & lai_m_s!=. & sect_main6_s != .
replace lai_m_s = `tot_ila_s' * (lai_m_s / r(mean)) if sect_main6_s != .

sum	lai_s [aw = wgt] if lai_s > 0 & lai_s != . & sect_main6 != .
loc tot_ila_s = r(mean)
sum lai_s_s [aw = fexp_s] if lai_s_s > 0 & lai_s_s!=. & sect_main6_s != .
replace lai_s_s = `tot_ila_s' * (lai_s_s / r(mean)) if sect_main6_s != .

loc r = rowsof(growth_labor_income)
mat growth_ila_tot = growth_labor_income[`r',1]

mat list growth_ila_tot

replace lai_m_s = lai_m_s * (1 + growth_ila_tot[1,1]) if lai_m_s > 0 & lai_m_s != . & sect_main6_s != .

replace lai_s_s = lai_s_s * (1 + growth_ila_tot[1,1]) if lai_s_s > 0 & lai_s_s != . & sect_main6_s != .

* Checking 
sum lai_m [aw = wgt] if lai_m > 0 & lai_m < . & sect_main6 != .
sca s0 = r(mean)

sum lai_m_s [aw = fexp_s] if lai_m_s > 0 & lai_m_s < . & sect_main6_s != .
sca s1 = r(mean)

di scalar(s1)/scalar(s0)-1
mat list growth_ila_tot

sum lai_s [aw = wgt] if lai_s > 0 & lai_s < . & sect_main6 != .
sca s0 = r(mean)

sum lai_s_s [aw = fexp_s] if lai_s_s > 0 & lai_s_s < . & sect_main6_s != .
sca s1 = r(mean)

di scalar(s1)/scalar(s0)-1
mat list growth_ila_tot


/*==========================================================================* TOTAL GROWTH OF LABOR INCOMES
 Expands labor incomes of main and secondary activities to make total income growth at the sectoral and total global rates (alike old model)
==========================================================================*/

*************************************************************************
*IMPORTANT: Re-scaling using sectoral GDP starts here
*************************************************************************

*===========================================================================
* Calculates the growth rate by sector of total labor income 
*    (main and secondary for everybody)
*===========================================================================

  capture drop sectorg
  clonevar sectorg = sect_main6


sum sectorg
loc lim = r(max)

forvalues i = 1/`lim' {
	sum lai_m     [aw = wgt]  if lai_m > 0 & lai_m < . & sectorg    == `i'
	sca sp_`i' = r(sum)
	sum lai_s     [aw = wgt]  if lai_s > 0 & lai_s < . & sectorg    == `i' 
	sca ss_`i' = r(sum)
	sca s0_`i' = scalar(sp_`i') + scalar(ss_`i')

	sum lai_m_s [aw = fexp_s]  if lai_m_s > 0 & lai_m_s < . & sect_main6_s== `i'
	sca sp_`i' = r(sum)
	sum lai_s_s    [aw = fexp_s] if lai_s_s   > 0 &   lai_s_s < . & sectorg   == `i' 
	sca ss_`i' = r(sum)
	sca s1_`i' = scalar(sp_`i') + scalar(ss_`i')

	if `i' == 1 { 
		mat var0 = s0_`i'
		mat var1 = s1_`i'
		mat list var0
		mat list var1
	}

	if `i' != 1 {
		mat var0 = var0\s0_`i'
		mat var1 = var1\s1_`i'
		mat list var0
		mat list var1
	}
}


*===========================================================================
* Calculates the difference between sectoral micro and macro growth data
*===========================================================================

mat growth_ila_macro = growth_macro_data[1..`lim',1]
 
mata:
M = st_matrix("var0")
V = st_matrix("growth_ila_macro")
C = st_matrix("var1")
G = M:*(1:+V)
H = (G:/C):-1
st_matrix("growth_ila_macro_n",H)
end


*===========================================================================
* Expands income labor by sector
*===========================================================================

forvalues c = 1/`lim'	{
   replace lai_m_s = lai_m_s * (1 + growth_ila_macro_n[`c',1]) if lai_m_s > 0 & lai_m_s != . & sect_main6_s == `c'
   replace lai_s_s = lai_s_s * (1 + growth_ila_macro_n[`c',1]) if lai_s_s > 0 & lai_s_s != . & sectorg     == `c' 
}

* Check the variations
forvalues i = 1/`lim' {
	sum lai_m_s [aw = fexp_s] if lai_m_s > 0 & lai_m_s < . & sect_main6_s == `i'
	sca sp_`i' = r(sum)
	sum lai_s_s [aw = fexp_s] if lai_s_s > 0 & lai_s_s < . & sectorg     == `i' 
	sca ss_`i' = r(sum)
	sca s1_`i' = scalar(sp_`i') + scalar(ss_`i')
}
mat n =   scalar(s1_1)/scalar(s0_1)-1
mat n = n\scalar(s1_2)/scalar(s0_2)-1
mat n = n\scalar(s1_3)/scalar(s0_3)-1
mat n = n\scalar(s1_4)/scalar(s0_4)-1
mat n = n\scalar(s1_5)/scalar(s0_5)-1
mat n = n\scalar(s1_6)/scalar(s0_6)-1

mat diff  = growth_ila_macro - n
mat check = growth_ila_macro,n,diff
mat list check


*************************************************************************
*IMPORTANT: Re-scaling using total GDP starts here
*************************************************************************

* IV. Re-scale the incomes in order to maintain constant the total income of the economy 
sum     lai_m    [aw = wgt]   if lai_m    > 0 & lai_m != .
loc tot_ila_s = r(sum)
sum     lai_m_s [aw = fexp_s]  if lai_m_s > 0 & lai_m_s!=.
replace lai_m_s = `tot_ila_s' * (lai_m_s / r(sum)) 

sum     lai_s    [aw = wgt]     if lai_s     > 0 & lai_s != .
loc tot_ila_s = r(sum)
sum     lai_s_s [aw = fexp_s]  if lai_s_s > 0 & lai_s_s !=.
replace lai_s_s = `tot_ila_s' * (lai_s_s/ r(sum))

* Ajuste por ingreso total
loc r = rowsof(growth_macro_data)
mat growth_ila_tot = growth_macro_data[`r',1]

mat list growth_ila_tot

replace lai_m_s = lai_m_s * (1 + growth_ila_tot[1,1]) if lai_m_s > 0 & lai_m_s != .
replace lai_s_s = lai_s_s * (1 + growth_ila_tot[1,1]) if lai_s_s > 0 & lai_s_s != .

* Checking 
sum lai_m [aw = wgt] if lai_m > 0 & lai_m < . 
sca sp = r(sum)
sum lai_s [aw = wgt] if lai_s > 0 & lai_s < . 
sca ss = r(sum)
sca s0 = scalar(sp) + scalar(ss)

sum lai_m_s [aw = fexp_s] if lai_m_s > 0 & lai_m_s < . 
sca sp = r(sum)
sum lai_s_s [aw = fexp_s] if lai_s_s > 0 & lai_s_s < . 
sca ss = r(sum)
sca s1 = scalar(sp) + scalar(ss)

di scalar(s1)/scalar(s0)-1
mat list growth_ila_tot


*===========================================================================
*                                     END
*===========================================================================
