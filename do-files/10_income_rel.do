*===========================================================================
* TITLE: 11 - Income growth by sector
*===========================================================================
* Prepared by: Sergio Olivieri
* E-mail: solivieri@worldbank.org
*===========================================================================
* Created on : Mar 17, 2020
* Last update: Oct 15, 2021
*===========================================================================

*===========================================================================
* Getting reduction in informal workers because of quarantine 
if $t == 2 {

   replace lai_m_s = lai_m * (1 - (lai_m * ( $redu )/(lai_m * 12))) if informal_s == 1

}
*===========================================================================
* I. Calculates the growth rate by sector of total labor income 
*    (main and secondary for everybody)
*===========================================================================

if $m != 1 {
  capture drop sectorg
  clonevar sectorg = sect_main
 
}

sum sectorg
loc lim = r(max)

//Cambiar r(sum) por r(mean), tambien considerar formalidad 

forvalues i = 1/`lim' {
	sum lai_m     [aw = pondera]  if lai_m > 0 & lai_m < . & sectorg    == `i'
	sca sp_`i' = r(sum)
	sum lai_s     [aw = pondera]  if lai_s > 0 & lai_s < . & sectorg    == `i' 
	sca ss_`i' = r(sum)
	sca s0_`i' = scalar(sp_`i') + scalar(ss_`i')

	sum lai_m_s [aw = fexp_s]  if lai_m_s > 0 & lai_m_s < . & sect_main_s== `i'
	sca sp_`i' = r(sum)
	sum lai_s    [aw = fexp_s] if lai_s   > 0 &   lai_s < . & sectorg   == `i' 
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
* Calculates the difference between micro and macro data growth rates by sector
*===========================================================================
mat growth_ila_rel = growth_macro_data[1..`lim',1]
 
mata:
M = st_matrix("var0")
V = st_matrix("growth_ila_rel")
C = st_matrix("var1")
G = M:*(1:+V)
H = (G:/C):-1
st_matrix("growth_ila_rel_n",H)
end

*===========================================================================
* Expands income labor by sector
clonevar lai_s_s = lai_s 

forvalues c = 1/`lim'	{
   replace lai_m_s = lai_m_s * (1 + growth_ila_rel_n[`c',1]) if lai_m_s > 0 & lai_m_s != . & sect_main_s == `c'
   replace lai_s_s = lai_s_s * (1 + growth_ila_rel_n[`c',1]) if lai_s_s > 0 & lai_s_s != . & sectorg     == `c' 
}

* Check the variations
forvalues i = 1/`lim' {
	sum lai_m_s [aw = fexp_s] if lai_m_s > 0 & lai_m_s < . & sect_main_s == `i'
	sca sp_`i' = r(sum)
	sum lai_s_s [aw = fexp_s] if lai_s_s > 0 & lai_s_s < . & sectorg     == `i' 
	sca ss_`i' = r(sum)
	sca s1_`i' = scalar(sp_`i') + scalar(ss_`i')
}
mat n =   scalar(s1_1)/scalar(s0_1)-1
mat n = n\scalar(s1_2)/scalar(s0_2)-1
mat n = n\scalar(s1_3)/scalar(s0_3)-1

mat diff  = growth_ila_rel - n
mat check = growth_ila_rel,n,diff
mat list check

*************************************************************************
*IMPORTANT: Re-scaling using total GDP starts here
*************************************************************************

* IV. Re-scale the incomes in order to maintain constant the total income of the economy 
sum     lai_m    [aw = pondera]   if lai_m    > 0 & lai_m != .
loc tot_ila_m = r(sum)
sum     lai_m_s [aw = fexp_s]  if lai_m_s > 0 & lai_m_s!=.
replace lai_m_s = `tot_ila_m' * (lai_m_s / r(sum)) 

sum     lai_s    [aw = pondera]     if lai_s     > 0 & lai_s != .
loc tot_ila_s = r(sum)
sum     lai_s_s [aw = fexp_s]  if lai_s_s > 0 & lai_s_s !=.
replace lai_s_s = `tot_ila_s' * (lai_s_s/ r(sum))

* Total GDP rescaling
loc r = rowsof(growth_macro_data)
mat growth_ila_tot = growth_macro_data[`r',1]

mat list growth_ila_tot

replace lai_m_s = lai_m_s * (1 + growth_ila_tot[1,1]) if lai_m_s > 0 & lai_m_s != . 
replace lai_s_s = lai_s_s * (1 + growth_ila_tot[1,1]) if lai_s_s > 0 & lai_s_s != . 

* Checking 
sum lai_m [aw = pondera] if lai_m > 0 & lai_m < . 
sca sp = r(sum)
sum lai_s [aw = pondera] if lai_s > 0 & lai_s < . 
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
