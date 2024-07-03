*!v1.0
*=============================================================================
* TITLE: 12 - Total labor income
*===========================================================================
* Prepared by: Sergio Olivieri
* E-mail: solivieri@worldbank.org
*=============================================================================
* Created on : Mar 17, 2020
* Last update: Jan 04, 2021
*=============================================================================

*=============================================================================

capture drop aux1
capture drop aux2
capture drop tot_lai_s

egen    aux1    = rsum(lai_m lai_s) , m
replace aux1 = lai_s if lai_m < 0  
replace aux1 = aux1 *-1
egen    aux2 = rsum(lai_m_s lai_s_s), m
replace aux2 = lai_s_s if lai_m_s < 0  

*egen tot_lai = rsum(lai_m lai_s), m

egen tot_lai_s = rowtotal(tot_lai aux1 aux2), missing 

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

loc r = rowsof(growth_macro_data)
mat growth_ila_tot = growth_macro_data[`r',1]
di scalar(s1)/scalar(s0)-1
mat list growth_ila_tot
drop aux1 aux2

*============================================================================*
* 									END
*============================================================================*
