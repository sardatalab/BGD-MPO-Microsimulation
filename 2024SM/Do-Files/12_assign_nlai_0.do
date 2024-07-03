*!v1.0
*=============================================================================
* TITLE: 12  Non-labor income
*===========================================================================
* Prepared by: Sergio Olivieri
* E-mail: solivieri@worldbank.org
*=============================================================================
* Created on : Jul 11, 2022
* Last update: Jul 18, 2022
*=============================================================================
* Modified by: Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
*			   Jul 18, 2022 - Adapted the ECU version to the full project.
*=============================================================================


*=============================================================================
* A. Private transfers
*=============================================================================

loc nl_incomes "remesas pensions capital transfers"
loc lim : word count `nl_incomes'
dis `lim'

forvalues i = 1/`lim' {
loc x : word `i' of `nl_incomes'

dis as text "{hline}" _newline ///
	as text " nl income = `x'" _newline ///
    as text "{hline}" _newline

*  1. calculates the growth rate of capital according to population growth 
sum h_`x' [aw = wgt  ] if h_`x' > 0 & h_`x' <.
mat var0 = r(sum) / 1000000
sum h_`x' [aw = fexp_s] if h_`x' > 0 & h_`x' <.
mat var1 = r(sum) / 1000000

* 2. calculates the difference between micro and macro data growth rates  
mat growth_`x' = growth_nlabor[`i',1]

}

mata:
M = st_matrix("var0")
C = st_matrix("var1")
V = st_matrix("growth_remesas")
G = M:*(1:+V)
H = (G:/C):-1
st_matrix("growth_remesas_adjust",H)
end

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


foreach x of local nl_incomes {
    dis as text "`x'"
* 3. expands private tranfers according to the new growth rate 
gen  h_`x'_s = h_`x' *(1 + growth_`x'_adjust[1,1] ) if h_`x' !=.

}

* others non-labor transfers  
gen  h_otherinla_s  = h_otherinla
//gen h_privtrans_s = h_privtrans


* imputed rent
gen h_renta_imp_s = h_renta_imp

*=============================================================================
*                                     END
*=============================================================================