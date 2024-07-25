*!v1.0
*===========================================================================
* TITLE: 12  Non-labor income
*===========================================================================
* Prepared by: Sergio Olivieri
* E-mail: solivieri@worldbank.org
*===========================================================================
* Created on : Jul 11, 2022
* Last update: Jul 20, 2022
*===========================================================================
* Modified by: Kelly Y. Montoya (kmontoyamunozo@worldbank.org)
* 			   Jul 20, 2022 - Adapted the ECU version to the full project.
*===========================================================================

*===========================================================================
* A. Private transfers
*===========================================================================

* Pensions, capital, and other non-labor income
**************************************************
loc nl_incomes "remesas pensions capital transfers"
loc lim : word count `nl_incomes'
dis `lim'

forvalues i = 1/`lim' {
	
	loc x : word `i' of `nl_incomes'

	dis as text "{hline}" _newline ///
		as text " nl income = `x'" _newline ///
		as text "{hline}" _newline

	* calculates the growth rate of capital according to population growth 
	sum h_`x' [aw = wgt  ] if h_`x' > 0 & h_`x' <.
	mat var0 = r(sum) / 1000000
	sum h_`x' [aw = fexp_s] if h_`x' > 0 & h_`x' <.
	mat var1 = r(sum) / 1000000

	* calculates the difference between micro and macro data growth rates  
	mat growth_`x' = growth_nlabor[`i',1]

}

mata:
	M = st_matrix("var0")
	C = st_matrix("var1")
	V = st_matrix("growth_pensions")
	G = M:*(1:+V)
	H = (G:/C):-1
	st_matrix("growth_pensions_adjust",H)
end

mata:
	M = st_matrix("var0")
	C = st_matrix("var1")
	V = st_matrix("growth_capital")
	G = M:*(1:+V)
	H = (G:/C):-1
	st_matrix("growth_capital_adjust",H)
end

mata:
	M = st_matrix("var0")
	C = st_matrix("var1")
	V = st_matrix("growth_transfers")
	G = M:*(1:+V)
	H = (G:/C):-1
	st_matrix("growth_transfers_adjust",H)
end

local nl_incomes2 "pensions capital transfers"
foreach x of local nl_incomes2 {
	dis as text "`x'"
	* expands private tranfers according to the new growth rate 
	gen  h_`x'_s = h_`x' *(1 + growth_`x'_adjust[1,1] ) if h_`x' !=.

}


* others non-labor transfers  
gen  h_otherinla_s  = h_otherinla


* imputed rent
gen h_renta_imp_s = h_renta_imp


* Remittances
****************
clonevar hhd = h_head

capture drop region_aux
clonevar region_aux = region

levelsof region, loc(numbers)

loc reg_nw 1
foreach m of local numbers {
	
	replace region = `reg_nw' if region == `m'
	loc ++reg_nw 

}

ta region

* Dummies of regions
xi I.region, prefix(_I)
gen _Iregion_1 = (region == 1)

mtab1 region urban [aw = fexp_s] if h_head == 1 & h_remesas > 0 & h_remesas < ., sum(h_remesas) matrix(RT) med(MED) quanty(REM) total
mtab1 region urban [aw = fexp_s] if h_head == 1, sum(h_remesas) matrix(tp) quanty(TH)

*Increasing order of growth rates of remittances
mata: st_order("growth_remesas", 1, 2, "aux_rem")
loc r = rowsof(growth_remesas)
sca r = rowsof(growth_remesas)


forvalues i = 1(1)`r' {
	
	* Calculates the growth rate of remittances from abroad according to population growth
	sum h_remesas [w = wgt] if h_remesas > 0 & h_remesas < .
	sca var0 = r(sum)
	sum h_remesas [w = fexp_s] if h_remesas > 0 & h_remesas < .
	sca var1 = r(sum)
	sca mean = r(mean)
	sum h_head [w = fexp_s] 
	sca N = r(sum)
	sca Tr = scalar(var0)*(1 + aux_rem[`i',2])- scalar(var1)
	if `i' == 1 {
		mat aux_tr = Tr
		if Tr > 0 mat p = 1
		if Tr < 0 mat p = 0
	}

	if `i' >  1 {
		mat aux_tr = aux_tr\Tr
		if Tr > 0 mat p = p\1
		if Tr < 0 mat p = p\0
	}

}

* Increasing order according to transfer
mat aux_rem_1 = aux_rem,aux_tr,p
mat list aux_rem_1
mata
	h = st_matrix("aux_rem_1")
	p = st_matrix("p")
	n = colsum(p)
	m = st_numscalar("r")
	c = 0
	w = cols(h)
	j = rows(h)

	if (n == m) h = sort(h,3)
	else if (n == c) h = sort(h,-3)
    else { 
		if (n < m & n > c){
			h = sort(h,-w)
			for (i=1; i<=j; i++) {
				if (i == 1 & h[i,w]== 1) g = h[i..i,i..w]
				if (i >  1 & h[i,w]== 1) g = g\h[i..i,1..w]
			}
			g = sort(g,3)

			h = sort(h,w)
			for (i=1; i<=j; i++) {
				if (i == 1 & h[i,w]== 0) t = h[i..i,i..w]
				if (i >  1 & h[i,w]== 0) t = t\h[i..i,1..w]
			}
			t = sort(t,-3)

			h = t\g
		}
    }
	
	H = st_matrix("aux_rem_1",h)
end


mat list aux_rem_1

forvalues i = 1(1)`r' {

	if `i' == 1 {

		* Calculates the growth rate of remittances from abroad according to population growth
		sum h_remesas [aw = wgt]  if h_remesas > 0 & h_remesas <.
		sca var0 = r(sum)
		sum h_remesas [aw = fexp_s] if h_remesas > 0 & h_remesas <.
		sca var1 = r(sum)
		sca mean = r(mean)
		sum h_head [aw = fexp_s] 
		sca N = r(sum)
		sca Tr = scalar(var0)*(1 + aux_rem_1[`i',2])- scalar(var1)
		di in ye "the difference is =>    " scalar(Tr)


		if scalar(Tr) > 0 {

			* Calculates the % of households which will receives the mean remittance over the gap of those who are receiving 
			mata: st_transf("Tr","MED","RT","REM","TH")

			capture drop aux2
			capture drop aux3
			gen aux2 = .		
			gen aux3 = .
		   
			qui tab region
			loc e = r(r)

			** Rural households by region	
			forvalues x = 1/`e' {
				gsort -_Iregion_`x' urban h_head hhid
				capture drop aux1
				gen double aux1 = sum(fexp_s)/N_r[`x',1] if h_head == 1
				replace aux2 = tr_r[`x',1] if aux1 <= SH_r[`x',1] & aux2 == .
			}

			** Urban households by region	
			forvalues x = 1/`e' {
				gsort -_Iregion_`x' -urban h_head hhid
				capture drop aux1
				gen double aux1 = sum(fexp_s)/N_u[`x',1] if h_head == 1
				replace aux2 = tr_u[`x',1] if aux1 <= SH_u[`x',1] & aux2 == .
			}

			* Generate the variable by growth rate
			loc w = aux_rem_1[`i',1]
			egen    h_remesas_`w' = rsum(h_remesas aux2)
			replace h_remesas_`w' = . if h_remesas == . & aux2 == .

			* Correction & check
			sum h_remesas [w = wgt] if h_remesas > 0 & h_remesas <.
			sca var0 = r(sum)
			sum h_remesas_`w'[w = fexp_s] if h_remesas_`w' > 0 & h_remesas_`w' <.
			sca var1 = r(sum)
			sca g_in = aux_rem_1[`i',2]
			mata: st_corr2("var0","var1","g_in")
			replace h_remesas_`w' = h_remesas_`w' *(1 + growth_inla_n[1,1]) if h_remesas_`w' > 0 & h_remesas_`w' <.

			sum h_remesas_`w' [aw = fexp_s] if h_remesas_`w' > 0 & h_remesas_`w' <.
			sca var1 = r(sum)
			sca Trr = scalar(var0)*(1 + aux_rem_1[`i',2])- scalar(var1)
			di in ye "the difference is =>    " scalar(Trr)
		} /*( close if Tr > 0 )*/ 
	  
	  
		if scalar(Tr) < 0 {

			* Calculates the growth rate of remittances from abroad according to population growth
			sum h_remesas [aw = wgt] if h_remesas > 0 & h_remesas <.
			sca var0 = r(sum)
			sum h_remesas [aw = fexp_s] if h_remesas > 0 & h_remesas <.
			sca var1 = r(sum)

			* Calculates the difference between micro and macro data growth rates 
			sca g_in = aux_rem_1[`i',2]
			mata: st_corr2("var0","var1","g_in")

			* Expands remittances according to the new growth rate only to those who had it
			loc w = aux_rem_1[`i',1]
			gen     h_remesas_`w' = h_remesas
			replace h_remesas_`w' = h_remesas_`w' *(1 + growth_inla_n[1,1]) if h_remesas_`w' > 0 & h_remesas_`w' <.
				
			* Check
			sum h_remesas [aw = wgt] if h_remesas > 0 & h_remesas < .
			sca var0 = r(sum)
			sum h_remesas_`w' [aw = fexp_s] if h_remesas_`w' > 0 & h_remesas_`w' < .
			sca var1 = r(sum)
			sca Trr = scalar(var0)*(1 + aux_rem_1[`i',2])- scalar(var1)
			di in ye "the difference is =>    " scalar(Trr)
	  
		}  /*( close if Tr < 0 )*/ 
		
	} /*( close if i == 1 )*/



	if `i' >= 2 {

		loc j = aux_rem_1[`i'-1,1]

		* Calculates the growth rate of remittances from abroad according to population growth & previous remittances growth
		sum h_remesas [aw = wgt] if h_remesas > 0 & h_remesas < .
		sca var0 = r(sum)
		sum h_remesas_`j' [aw = fexp_s] if h_remesas_`j' > 0 & h_remesas_`j' < .
		sca var1 = r(sum)
		sca mean = r(mean)
		sum hhd [aw = fexp_s] 
		sca N = r(sum)
		sca Tr = scalar(var0)*(1 + aux_rem_1[`i',2])- scalar(var1)
		di in ye "the difference is =>    " scalar(Tr)


		if scalar(Tr) > 0 {
		
			* Calculates the % of households which will receives the mean remittance over the gap of those who are receiving 
			mata: st_transf("Tr","MED","RT","REM","TH")
			 
			capture drop aux2
			capture drop aux3
			gen aux2 = .		
			gen aux3 = .
			
			qui tab `region'
			loc e = r(r)
			
			** Rural households by region	
			forvalues x = 1/`e' {
				gsort -_I`region'_`x' urban hhd hid
				capture drop aux1
				gen double aux1 = sum(fexp_s)/N_r[`x',1] if hhd == 1
				replace aux2 = tr_r[`x',1] if aux1 <= SH_r[`x',1] & aux2 == .
			}
			
			** Urban households by region	
			forvalues x = 1/`e' {
				gsort -_I`region'_`x' -urban hhd hid
				capture drop aux1
				gen double aux1 = sum(fexp_s)/N_u[`x',1] if hhd == 1
				replace aux2 = tr_u[`x',1] if aux1 <= SH_u[`x',1] & aux2 == .
			}
			
			* Generate the variable by growth rate
			loc w = aux_rem_1[`i',1]
			egen    h_remesas_`w' = rsum(h_remesas_`j' aux2)
			replace h_remesas_`w' = . if h_remesas_`j' == . & aux2 == .
			
			* Correction & check
			sum h_remesas [aw = wgt] if h_remesas > 0 & h_remesas <.
			sca var0 = r(sum)
			sum h_remesas_`w'[aw = fexp_s] if h_remesas_`w' > 0 & h_remesas_`w' <.
			sca var1 = r(sum)
			sca g_in = aux_rem_1[`i',2]
			mata: st_corr2("var0","var1","g_in")
			replace h_remesas_`w' = h_remesas_`w' *(1 + growth_inla_n[1,1]) if h_remesas_`w' > 0 & h_remesas_`w' <.
			
			sum h_remesas_`w' [aw = fexp_s] if h_remesas_`w' > 0 & h_remesas_`w' <.
			sca var1 = r(sum)
			sca Trr = scalar(var0)*(1+aux_rem_1[`i',2])- scalar(var1)
			di in ye "the difference is =>    " scalar(Trr)
			 
		} /*( close if Tr > 0 )*/ 
		   
	   
		if scalar(Tr) < 0 {

			* Calculates the growth rate of remittances from abroad according to population growth
			sum h_remesas [aw = wgt] if h_remesas > 0 & h_remesas <.
			sca var0 = r(sum)
			sum h_remesas [aw = fexp_s] if h_remesas > 0 & h_remesas <.
			sca var1 = r(sum)
			 
			* Calculates the difference between micro and macro data growth rates 
			sca g_in = aux_rem_1[`i',2]
			mata: st_corr2("var0","var1","g_in")
			
			* Expands remittances according to the new growth rate only to those who have it in 2006
			loc w = aux_rem_1[`i',1]
			gen     h_remesas_`w' = h_remesas
			replace h_remesas_`w' = h_remesas_`w' *(1 + growth_inla_n[1,1]) if h_remesas_`w' > 0 & h_remesas_`w' <.
				
			* Check
			sum h_remesas [aw = wgt] if h_remesas > 0 & h_remesas < .
			sca var0 = r(sum)
			sum h_remesas_`w' [aw = fexp_s] if h_remesas_`w' > 0 & h_remesas_`w' < .
			sca var1 = r(sum)
			sca Trr = scalar(var0)*(1 + aux_rem_1[`i',2])- scalar(var1)
			di in ye "the difference is =>    " scalar(Trr)
	   
		} /*( close if Tr < 0 )*/ 
	  
	}/*( close if i >= 2 )*/
	
}/*( close forvalues )*/

* Identifies the variable for the scenario we are running
mata
	k = st_matrix("aux_rem")
	r = st_matrix("growth_remesas")
	t = k[.,2]:/r
	y = k[.,1],t
	j = rows(y)
	for (i = 1; i <= j; i++) {
		if (i == 1 & y[i,2] != 1) n = 0
		if (i == 1 & y[i,2] == 1) n = 1
		if (i != 1 & y[i,2] != 1) n = n\0
		if (i != 1 & y[i,2] == 1) n = n\1
	}
	y = y,n
	j = cols(y)
	y = sort(y,-j)
	st_numscalar("v", y[1..1,1..1])
end

loc m = scalar(v)
clonevar h_remesas_s = h_remesas_`m'

drop region
rename region_aux region
ta region

*===========================================================================
*                                     END
*===========================================================================