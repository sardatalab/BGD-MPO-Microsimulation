*!v1.0
*===========================================================================
* TITLE: 08 - Simulating changes in the employment structure
*===========================================================================
* Prepared by: Sergio Olivieri
* E-mail: solivieri@worldbank.org
*===========================================================================
* Created on : Mar 17, 2020
* Last update: Jan 04, 2021
* 			   Aug 10, 2022 Kelly Y. Montoya Changed estructure sectoral matrix line 293.
* 			   Aug 11, 2022 Kelly Y. Montoya Changed informality simulation and added checks for estructure and informality.
*===========================================================================

note: those with public jobs do not change between sectors

*===========================================================================
* I. MISCELLANEOUS TASKS  
*===========================================================================

* public sector fixed
clonevar public   = public_job

* number of sectors
clonevar sectorg = sect_main6

sum sectorg
loc lim = r(max)

* employment structure 
mat sector     = J(`lim',1,.)
mat sect_prv   = J(`lim',1,.)
mat sect_pub   = J(`lim',1,.)

mat sector_s   = J(`lim',1,.)
mat sect_prv_s = J(`lim',1,.)
mat sect_pub_s = J(`lim',1,.)

forvalues a = 1/`lim' {
	
	* base year 
	sum wgt if sample == 1 & emplyd == 1 & sectorg == `a' 
	mat sector[`a',1]   = r(sum)

	sum wgt if sample == 1 & emplyd == 1 & sectorg == `a' & public == 0 
	mat sect_prv[`a',1]   = r(sum)
	
	sum wgt if sample == 1 & emplyd == 1 & sectorg == `a' & public == 1
	mat sect_pub[`a',1]   = r(sum)
	
	* simulated
	sum fexp_s if sample == 1 & emplyd_s == 1 & sectorg == `a' 
	mat sector_s[`a',1] = r(sum)

	sum fexp_s if sample == 1 & emplyd_s == 1 & sectorg == `a' & public == 0 
	mat sect_prv_s[`a',1] = r(sum)

	sum fexp_s if sample == 1 & emplyd_s == 1 & sectorg == `a' & public == 1 
	mat sect_pub_s[`a',1] = r(sum)
}

* employment matrix goals 
loc row_tot = rowsof(growth_labor)
mat growth_estru = growth_labor[3..`row_tot',1]

mata: st_mat("growth_estru", "sector", 1,`lim')
mat sector = sector , sector_mata
mata: st_gr("sector_s", "shares_mata")

* re-weighting the shares 
sum fexp_s if emplyd_s == 1 & sample == 1
ret li
mata: st_repond_1("shares_mata", "growth_estru", 2, `r(sum)', "sector_rep")

* sector dummies: identifying employed individuals who already have sector and those who do not
forvalues s = 1/`lim' {
	gen d_act`s'     = cond(sectorg == `s',1,0) if sample == 1 & emplyd_s == 1
	gen d_act`s'_sim = d_act`s'		     
}

order d_act*_sim

* This is only for those who belongs to the employment in both moments
egen    changed = rsum(d_act1_sim - d_act`lim'_sim) if emplyd_s == 1 & emplyd == 1 & sample  == 1
tab     changed


*===========================================================================
*II. SECTORS WHICH REDUCED THEIR EMPLOYMENT LEVELS
*===========================================================================
* Mata rutine which orders sectors in ascending way 
mata: st_order("growth_estru_n", 1, 2, "aux")

dis in red "SECTORS WHICH REDUCED THEIR EMPLOYMENT LEVELS"

forvalues r = 1/`lim' {
	
	*drop jobs from decreasing sectors 
	if aux[`r',2] < 0 {

		*identifies the sector		
		loc s = aux[`r',1] 
		dis in red "economic sector `s'"
		
		*orders the population according to: activity, probability, hhd id and ind id 
		loc p = `s' + 1
		clonevar P`s' = U`p'_1 
		replace  P`s' = U`p'_2 if P`s' == .
		
		gsort  -d_act`s'_sim -P`s' id -public
		capture drop aux
		gen     aux = sum(fexp_s) if emplyd_s == 1 & emplyd == 1 & d_act`s'_sim == 1 						     
		replace d_act`s'_sim = 0  if emplyd_s == 1 & emplyd == 1 & d_act`s'_sim == 1 & (aux > sector_rep[`s',1] ) 
		
		drop aux changed
		egen    changed = rsum(d_act1_sim - d_act`lim'_sim) if emplyd_s == 1 & emplyd == 1 & sample  == 1 
	}
}

*===========================================================================
*II. SECTORS WHICH INCREASE THEIR EMPLOYMENT LEVELS
*===========================================================================
* Mata routine which orders sectors in descending way
mata: st_order("growth_estru_n", 1, -2, "aux")

* Employed ranking(t): 1- employed(t-1) and changed sector; 2- unemployed(t-1); 3- inactives(t-1)
gen     rank$t =.
replace rank$t = 1 if emplyd_s == 1 & emplyd  == 1 & changed == 0
replace rank$t = 2 if emplyd_s == 1 & unemplyd == 1 
replace rank$t = 3 if emplyd_s == 1 & lf_samp  == 0

dis in red "SECTORS WHICH INCREASED THEIR EMPLOYMENT LEVELS"

forvalues r = 1/`lim'	{

	* Asign a job to increasing sectors
	if aux[`r',2]>=0	{
	
		* Identifies the sector		
		loc s = aux[`r',1] 
		dis in red "economic sector `s'"

		loc p = `s' + 1
		clonevar P`s' = U`p'_1 
		replace  P`s' = U`p'_2 if P`s' == .
		
		gsort -d_act`s'_sim rank$t -P`s' id 

		gen aux = sum(fexp_s)	    if (d_act`s'_sim == 1 | rank$t != .) 							   
		replace d_act`s'_sim = 1	if  d_act`s'_sim == 0 & rank$t != .  & (aux <= sector_rep[`s',1]) 

		drop changed aux
		egen    changed = rsum(d_act1_sim - d_act`lim'_sim) if emplyd_s == 1 & sample  == 1
		sum     changed
				
		replace rank$t = . if changed == 1 & emplyd_s == 1 & emplyd  == 1
		replace rank$t = . if changed == 1 & emplyd_s == 1 & unemplyd == 1
		replace rank$t = . if changed == 1 & emplyd_s == 1 & lf_samp  == 0 
	}
}


*===========================================================================
*III. Allocate sectors for those who were not assigned (by growth rate and share employment)
*===========================================================================
*mata: st_repond("sector","growth_estru" , 2, 1, "sector_shr", "share")
sum rank$t
loc mm = r(N)
dis in red "`mm'"

while (`mm' > 0) {
	forvalues r = 1/`lim'	{
	
		loc s = aux[`r',1] 

		if growth_estru[`s',1]>0	{
	
			loc p = shares_mata[`s',2]
		
			di in red "this is p: " "`p'"
		
			gsort -d_act`s'_sim -P`s' id 
			sum fexp_s				     if emplyd_s == 1 & changed == 0 
			gen aux = sum(fexp_s)/r(sum) if emplyd_s == 1 & changed == 0 
			replace d_act`s'_sim = 1	 if emplyd_s == 1 & changed == 0 & rank$t !=. & (aux <= `p') 
		
			drop changed aux
			egen changed = rsum(d_act1_sim - d_act`lim'_sim) if emplyd_s ==1
			sum  changed

			replace rank$t =. if changed == 1 & emplyd_s == 1 & emplyd == 1
			replace rank$t =. if changed == 1 & emplyd_s == 1 & unemplyd ==1
			replace rank$t =. if changed == 1 & emplyd_s == 1 & lf_samp == 0
		}
		
		if growth_estru[`s',1]<0	{
	
			loc p = shares_mata[`s',2]
		
			di in red "this is p: " "`p'"
		
			gsort -d_act`s'_sim -P`s' id 
			sum fexp_s				        if emplyd_s == 1 & changed == 0 
			gen aux = sum(fexp_s)/r(sum)	if emplyd_s == 1 & changed == 0 
			replace d_act`s'_sim = 1		if emplyd_s == 1 & changed == 0 & rank$t !=. & (aux <= `p') 
		
			drop changed aux
			egen changed = rsum(d_act1_sim - d_act`lim'_sim)	if emplyd_s ==1
			sum  changed

			replace rank$t =. if changed == 1 & emplyd_s == 1 & emplyd == 1
			replace rank$t =. if changed == 1 & emplyd_s == 1 & unemplyd ==1
			replace rank$t =. if changed == 1 & emplyd_s == 1 & lf_samp == 0
		}
	}
	
	sum rank$t
	loc mm = r(N)
	di in red "there are `mm' observations left"
	if `mm' < 16 loc mm = 0	
	note: adjust in case it doesn´t converge, increase the 16. 
}

drop changed rank$t

*===========================================================================
* Creates new activity
*===========================================================================
gen act$t = .
forvalues s = 1/`lim'	{
	replace act$t = `s' if d_act`s'_sim == 1 &  act$t == .
	}
drop d_act*


* new main labor sector	
	gen	      sect_main_s = .
	replace   sect_main_s =  1 if act$t == 1
	replace   sect_main_s =  2 if act$t == 2 
	replace   sect_main_s =  3 if act$t == 3
	replace   sect_main_s =  4 if act$t == 4
	replace   sect_main_s =  5 if act$t == 5
	replace   sect_main_s =  6 if act$t == 6
	replace   sect_main_s = sectorg if sect_main_s== . & sample == . & emplyd_s == 1
	label var sect_main_s "economic sector simulated"
	
	rename sect_main_s sect_main6_s
	*recode sect_main6_s (1 2 = 1) (3 4 = 2) (5 6 = 3), gen(sect_main_s)
	*label values sect_main_s sector
	*ADD labels!
	
	
* new occupation status
	gen     occupation_s = .
	replace occupation_s = 0 if  active_s     == 0 & sample == 1
	replace occupation_s = 1 if  unemplyd_s   == 1 & sample == 1
	replace occupation_s = 2 if  sect_main6_s == 1 & sample == 1
	replace occupation_s = 3 if  sect_main6_s == 2 & sample == 1
	replace occupation_s = 4 if  sect_main6_s == 3 & sample == 1
	replace occupation_s = 5 if  sect_main6_s == 4 & sample == 1
	replace occupation_s = 6 if  sect_main6_s == 5 & sample == 1
	replace occupation_s = 7 if  sect_main6_s == 6 & sample == 1

	label var    occupation_s "occupation status - simulated"
	label values occupation_s occup



*===========================================================================
* Creates the structure sectoral matrix
*===========================================================================
mat sector   = J(`lim',1,.)
mat sector_s = J(`lim',1,.)

forvalues a = 1/`lim' {
	sum wgt if sample == 1 & emplyd == 1 & sectorg == `a'
	mat sector[`a',1]   = r(sum)
 
	if $m == 1 {
		sum fexp_s if sample == 1 & emplyd_s == 1 & sect_main_s== `a'
		mat sector_s[`a',1] = r(sum)
	}
	
	if $m != 1 {
		sum fexp_s if sample == 1 & emplyd_s == 1 & sect_main6_s== `a'
		mat sector_s[`a',1] = r(sum)
	}
}

mat growth_estru = growth_labor[3..`row_tot',1]
mata: st_mat("growth_estru", "sector", 1,`lim')
mat sector = sector , sector_mata

mat list sector
mat list sector_s 

* including those out of sample
replace unemplyd_s   = unemplyd if sample == .
replace emplyd_s     = emplyd   if sample == .
replace active_s     = lf_samp  if sample == .
replace sect_main6_s = sectorg  if sect_main6_s== . & sample == . & emplyd_s == 1

* check new sectoral structure 
clonevar sectorg_s = sect_main6_s 

forvalues a = 1/`lim' {
	
	capt drop aux
	gen aux = sectorg == `a' if sample == 1 & sectorg != .
	sum aux [w = wgt] if lf_samp == 1
	scalar v0 = r(mean)
		
	capt drop aux
	gen aux = sectorg_s == `a' if sample == 1 & sectorg_s != .
	sum aux [w = fexp_s] if active_s == 1
	scalar v1 = r(mean)
	
	if abs( round((scalar(v1)/scalar(v0)-1),.005) - round(growth_estru[`a',1],.005) ) > 0.01 {
		di in red "WARNING: New sectoral estructure doesn´t match growth rates."
		break
	}	
}

drop aux*

/*

*===========================================================================
* Informality rates by economic sector
*===========================================================================

* Creating a new informal variable
cap drop informal_s

if $m == 1 {
	
	gen      informal_s = informal if emplyd_s == 1

	* random numbers
	capture drop aleat_inf
	set seed 12345678
	gen aleat_inf = uniform() if sample == 1 

	* in and out of informality
	sum sect_main
	loc lim = r(max)

	* Creates the structure sectoral matrix - targets
	mat informal      = J(`lim',1,.)

	forvalues a = 1/`lim' {
		sum informal [w = wgt] if lf_samp == 1 & emplyd == 1 & sect_main == `a' 
		mat informal[`a',1] = r(mean)*(1 + growth_informal[`a',1])
	}

	* Allocate individuals according to their probability of being employed
	gsort  sect_main_s -informal_s aleat_inf id 

	forvalues i = 1/`lim' {
      
		qui sum fexp_s if active_s == 1 & sect_main_s == `i'
		gen double aux = sum(fexp_s)/r(sum) if emplyd_s == 1 & sect_main_s == `i'
		replace informal_s = 1 if aux <= (informal[`i',1] + epsfloat()) & emplyd_s == 1 & sect_main_s == `i'
		replace informal_s = 0 if aux >  (informal[`i',1] + epsfloat()) & emplyd_s == 1 & sect_main_s == `i'
		drop aux*

	}
}

if $m != 1 {
	
	gen  	informal_s = 1 if (sect_main6_s == 2 | sect_main6_s== 4 | sect_main6_s== 6) & emplyd_s == 1
	
	replace informal_s = 0 if (sect_main6_s == 1 | sect_main6_s== 3 | sect_main6_s== 5) & emplyd_s == 1
}


* Check new informal rates
sum sect_main
loc lim_inf = r(max)
forvalues a = 1/`lim_inf' {
		
	capt drop aux
	gen aux = informal / lf_samp if sample == 1
	sum aux [w = wgt] if lf_samp == 1 & sect_main == `a'
	scalar v0 = r(mean)
		
	capt drop aux
	gen aux = informal_s / active_s if sample == 1
	sum aux [w = fexp_s] if active_s == 1 & sect_main_s == `a' 
	scalar v1 = r(mean)
	
	if abs( round((scalar(v1)/scalar(v0)-1),.005) - round(growth_informal[`a',1],.005) ) > 0.01 {
		di in red "WARNING: New informal workers in sector `a' doesn´t match growth rate."
	}
		

}

* Bringing back those who do not belong to the sample
replace informal_s = informal if sample == . & informal_s == .

*===========================================================================
*                                     END
*===========================================================================

*/