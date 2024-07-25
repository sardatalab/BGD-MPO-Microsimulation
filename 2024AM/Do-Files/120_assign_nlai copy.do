*!v1.0
*=============================================================================
* TITLE: 12  Non-labor income
*===========================================================================
* Prepared by: Sergio Olivieri
* E-mail: solivieri@worldbank.org
*=============================================================================
* Created on : Mar 17, 2020
* Last update: Jul 18, 2022
*=============================================================================
* Modified by: Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
* Modification: 04/29/2022 - Correction of h_nlai_s
*				07/18/2022 - Modification on remittances modelling
*=============================================================================


*=============================================================================
* A. Private transfers
*=============================================================================

* Remittances are increased only to those who are receiving, and they increse at the remittances grow rate

if "${random_remittances}" == "no" {
	do "${thedo}/120_assign_nlai_0.do"
}

if "${random_remittances}" == "yes" {
	do "${thedo}/120_assign_nlai_1.do"
}



*=============================================================================
* C. Total non-labor income
*=============================================================================
//egen h_nlai_s = rowtotal(h_remesas_s h_pensions_s h_capital_s h_privtrans_s h_transfers_s h_cct_s h_renta_imp_s h_otherinla_s) if jefe == 1, missing

*gen h_nlai_s = rowtotal(h_remesas_s h_pensions_s h_capital_s h_renta_imp_s h_otherinla_s h_transfers_s) if jefe == 1, missing

* KM: I made this adjustment to non-labor income
egen aux_nlai_s = rowtotal(h_remesas_s h_pensions_s h_capital_s h_renta_imp_s h_otherinla_s h_transfers_s) if h_head == 1, missing

bysort id: egen h_nlai_s = sum(aux_nlai_s) if h_head != ., m

*gen h_nlai_s = nlai_s / h_size

*drop nlai_s

*=============================================================================
*                                     END
*=============================================================================
