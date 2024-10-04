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
	foreach pl in 2.15 3.65 6.85 {
		apoverty welfare_ppp17  [w=wgt], line(2.15)
		
		apoverty pc_con_s pc_con_preadj [w=fexp_s], line(2.15)	
	}
			ineqdec0 welfare_ppp17  [w=wgt]
			ineqdeco pc_con_s		[w=fexp_s]

	
	
*=============================================================================
*                                     END
*=============================================================================

	
	