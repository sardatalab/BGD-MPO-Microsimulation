*!v1.0
*=============================================================================
* TITLE: 14 - Household consumption
*===========================================================================
* Prepared by: Israel Osorio-Rodarte
* E-mail: iosoriorodarte@worldbank.org
*=============================================================================
* Created on : Sep 06, 2024
* Last update: Sep 06, 2024
*=============================================================================
* Modified by: 
* Modification: 
*=============================================================================

	* Quick summary
	local yyyy = 2022
	use "${data_out}/basesim_`yyyy'", clear
	
	foreach pl in 2.15 3.65 6.85 {
		
		if `pl'==2.15 local pliney "0215"
		if `pl'==3.65 local pliney "0365"
		if `pl'==6.85 local pliney "0685"
		
		apoverty welfare_ppp17  [w=wgt], line(`pl')
			scalar povbase`pliney'_`yyyy' = r(head_1)
		
		apoverty pc_con_s [w=fexp_s], line(`pl')
			scalar povsim`pliney'_`yyyy' = r(head_1)
	}
	
	
			ineqdec0 welfare_ppp17  [w=wgt]
			ineqdeco pc_con_s		[w=fexp_s]

	
	
*=============================================================================
*                                     END
*=============================================================================

	
	