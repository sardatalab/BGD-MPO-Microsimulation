*===========================================================================
* TITLE: Prepare variables
*===========================================================================
* Prepared by: Sergio Olivieri
* E-mail: solivieri@worldbank.org
*===========================================================================
* Created on : Mar 17, 2020
* Last update: Feb 14, 2023 Kelly Y. Montoya
* 				March 1, 2023 - Cicero Braga - adjust informality for ARG
*===========================================================================

*===========================================================================
* Be careful: check by-one-bye
*===========================================================================

gen ipcf_ppp17=(12/365)*ipcf/cpi2017/icp2017

gen welfarenom_ppp17=(12/365)*welfarenom/cpi2017/icp2017

clonevar emplyd     = lstatus_year if ipcf_ppp17 != .
gen unemplyd   = (lstatus==2)  if ipcf_ppp17 != .
*gen      male       = (hombre==1)
replace male = . if male!=1

clonevar edad = age
* age sample
gen sample = 1 if inrange(edad,15,64)

clonevar id=hhid


*===========================================================================
* PPP adjustment factor
*===========================================================================


* PPP 2017 adjustment factor

	
	foreach incomevar in ila ijubi itranp itrane icap inla_otro inla renta_imp ipcf itf ip inp {
		cap drop `incomevar'_ppp17
		gen `incomevar'_ppp17=(12/365)*`incomevar'/cpi2017/icp2017
	}



if $national == 0 {
	
		*Make sure this is total family income
		clonevar  h_inc       = itf_ppp17
		clonevar lai_m        = ip_ppp17 
		clonevar lai_s        = inp_ppp17
		clonevar lai_orig     = ila_ppp17
}


*===========================================================================
* Labor market variables
*===========================================================================

* Occupation by economic sector and informal status

*Generate the three economic sectors variable
/*
if inlist(pais_ocaux,"PRY","pry")  {
	recode sector (1=1 "Agriculture") (2 3 4 =2 "Industry") (5 6 7 8 9 10 =3 "Services") , gen(sect_main)
	replace sect_main = . if ipcf_ppp17 == .
	*recode sector_s (1 2 =1 "Agriculture") (3 4 5 6 =2 "Industry") (7 8 9 10 11 12 13 14 15 16 17 =3 "Services") , gen(sect_secu) // KM: PRY doesn't have sector_s but it could be created. I leave this here in case they add it later in the harmonization.
} // PRY doesn't have available the variable sector1d from 2014 on.

else {
	recode sector1d (1 2 =1 "Agriculture") (3 4 5 6 =2 "Industry") (7 8 9 10 11 12 13 14 15 16 17 =3 "Services") , gen(sect_main)
	replace sect_main = . if ipcf_ppp17 == .
	
	if inlist(pais_ocaux,"cri","CRI","CHL","chl","MEX", "mex") {
	    gen sect_secu = .
	}
	
	else {
		recode sector1d_s (1 2 =1 "Agriculture") (3 4 5 6 =2 "Industry") (7 8 9 10 11 12 13 14 15 16 17 =3 "Services") , gen(sect_secu)
		replace sect_secu = . if ipcf_ppp17 == .
	}
}
*/

* primary activity
gen     sect_main6 = .
replace sect_main6 = 1 if  industry6 == 1 & emplyd == 1 
replace sect_main6 = 2 if  industry6 == 2 & emplyd == 1 
replace sect_main6 = 3 if  industry6 == 3 & emplyd == 1 
replace sect_main6 = 4 if  industry6 == 4 & emplyd == 1 
replace sect_main6 = 5 if  industry6 == 5 & emplyd == 1
replace sect_main6 = 6 if  industry6 == 6 & emplyd == 1 
label var sect_main6 "main economic sector" 

* secondary activity
gen     sect_secu6 = .
replace sect_secu6 = 1 if  industry6_2 == 1 & emplyd == 1 
replace sect_secu6 = 2 if  industry6_2 == 2 & emplyd == 1 
replace sect_secu6 = 3 if  industry6_2 == 3 & emplyd == 1 
replace sect_secu6 = 4 if  industry6_2 == 4 & emplyd == 1 
replace sect_secu6 = 5 if  industry6_2 == 5 & emplyd == 1
replace sect_secu6 = 6 if  industry6_2 == 6 & emplyd == 1
label var sect_secu6  "secondary economic sector" 

label def sectors         ///
1 "Agriculture"   ///
2 "Industry" ///
3 "Construction"   ///
4 "Services" ///
5 "Transport"   ///
6 "Finance", replace
label values sect_main6 sect_secu6 sectors

* labor relationship
gen salaried = empstat_year==1 if emplyd==1
gen self_emp = empstat_year==4 if emplyd==1 
gen unpaid = empstat_year==2 if emplyd==1
gen salaried2 = empstat_2_year==1 if emplyd==1
gen self_emp2  = empstat_2_year==4 if emplyd==1
gen unpaid2    = empstat_2_year==2 if emplyd==1

* primary activity
gen     labor_rel = 1 if salaried == 1
replace labor_rel = 2 if self_emp == 1
replace labor_rel = 3 if unpaid   == 1
replace labor_rel = 4 if unemplyd == 1
label var labor_rel "labor relation-primary job"

* secondary activity
gen     labor_rel2 = 1 if salaried2 == 1
replace labor_rel2 = 2 if self_emp2 == 1
replace labor_rel2 = 3 if unpaid2   == 1
label var labor_rel2 "labor relation-secondary job"

label def lab_rel ///
1 "salaried"   ///
2 "self-employd" ///
3 "unpaid" ///
4 "unemployed" ,replace
label values labor_rel labor_rel2 lab_rel

* public job_status
/* IMPORTANT: This isn't accounting for not salaried public workers
 grupo_lab = 3  is  relab==2 & empresa==3
*/
gen     public_job = 0 if emplyd ==1
replace public_job = 1 if emplyd == 1 & ocusec_year==1

note: by definiton the public job is part of formal services sector

replace industry6  = 4 if !inlist(industry6, 4) & public_job ==1 & industry6!= .
replace sect_main6 = 4 if !inlist(sect_main6,4) & public_job ==1 & sect_main6 != .

*===========================================================================
* Checking income variables
*===========================================================================

* labor incomes
egen    tot_lai = rowtotal(lai_m lai_s), missing
replace tot_lai = lai_s if lai_m < 0
replace tot_lai = . if lai_orig == .
if abs(tot_lai - lai_orig) > 1 & abs(tot_lai - lai_orig) != . di in red "WARNING: Please check variables definition. tot_lai is different from lai_orig."
drop lai_orig

* total household labor incomes
egen     h_lai  = sum(tot_lai) , by(hhid) missing

* Household size
clonevar h_size= hsize

* Non-labor incomes
	gen capital_ppp17  = icap_ppp17
	gen pensions_ppp17 = ijubi_ppp17
	gen otherinla_ppp17 = inla_otro_ppp17
	gen remesas_ppp17  = itranp_ppp17
	gen transfers_ppp17 = itrane_ppp17

if $national == 0 { 
		note: includes imputed rent
		replace renta_imp_ppp17 = renta_imp_ppp17 / h_size
		local var "remesas_ppp17 pensions_ppp17 capital_ppp17 renta_imp_ppp17 otherinla_ppp17 transfers_ppp17"
		foreach x of local var {
		egen     h_`x' = sum(`x') , by(hhid) missing
		replace  h_`x' = . if h_`x' == 0	
		}
} 

rename h_capital_ppp h_capital 
rename h_pensions_ppp h_pensions
rename h_remesas_ppp h_remesas 
rename h_otherinla_ppp h_otherinla
rename h_transfers_ppp h_transfers
rename h_renta_imp_ppp h_renta_imp

* household income
egen mm = rowtotal(h_lai h_remesas h_pensions h_capital h_renta_imp h_otherinla h_transfers), missing

gen  resid = h_inc - mm
replace resid = 0 if resid < 0
drop mm

egen h_nlai = rowtotal(h_remesas h_pensions h_capital h_renta_imp h_otherinla h_transfers resid), missing

* at household level 
local var "h_remesas h_pensions h_capital h_renta_imp h_otherinla h_nlai h_transfers resid"

foreach x of local var {
replace  `x' = . if relationharm != 1
}
replace h_nlai   = . if h_nlai == 0


/*==========================================================================
* II. INDEPENDENT VARIABLES
*=========================================================================== 
	gender:			    male 
	experience:		    age
	experience2:		age2
	education dummies:	none and infantil
						primary
						secundary
						superior
	household head:		h_head
	marital status:		married
	regional dummies:   region	
	remittances:		    remitt_any
	other memb public job:	oth_pub
	dependency:		        depen
	others perception:	    perce
========================================================================= */
	
* education level (aggregate primary and none)
//replace educ_lev = 1 if educ_lev  ==0 
	
gen educ_level = educat7
replace educ_lev = 1 if educ_lev ==0

* marital status
gen married = (marital==1)

* household head
gen h_head = (relationharm==1)

* remittances domestic or abroad
cap drop aux*
//gen	       aux  = 1 if (remesas > 0 & remesas !=.)

gen aux  = 1 if (remesas_ppp17 >0 & remesas_ppp17!=.)
replace	   aux  = 0 if  aux ==. 
egen       remitt_any = max(aux), by(hhid)
label var  remitt_any "[=1] if household receives remittances"

* other member with public salaried job
cap drop aux*
egen aux       = total(public_job), by(hhid)
gen     oth_pub = sign(aux - public_job)
replace oth_pub = sign(aux) if missing(public_job)
lab var oth_pub "[=1] if other member with public job"

* dependency ratio
cap drop aux*
cap drop depen
egen aux = total((age < 15 | age > 64)), by(hhid)
gen       depen = aux/h_size 
label var depen "potential dependency"

* log main labor income
gen ln_lai_m = ln(lai_m)

*===========================================================================
* I. DEPENDENT VARIABLES
*===========================================================================

*check here definition of active (12 months or 7 days)

gen active = lstatus_year
replace active = 1 if lstatus==2
replace active = 0 if active != 1

gen     occupation = .
replace occupation = 0 if  active     == 0          	
replace occupation = 1 if  unemplyd   == 1	    	  	
replace occupation = 2 if  sect_main6 == 1
replace occupation = 3 if  sect_main6 == 2
replace occupation = 4 if  sect_main6 == 3
replace occupation = 5 if  sect_main6 == 4
replace occupation = 6 if  sect_main6 == 5
replace occupation = 7 if  sect_main6 == 6
label var occupation "occupation status"

label define occup ///
0 "inactive" /// 
1 "unempl"   ///
2 "agric"  /// 
3 "ind" ///
4 "cons" ///
5 "serv" ///
6 "transp"  ///
7 "fin", replace 
label values occupation occup
	
*===========================================================================
* Setting up sample 
*===========================================================================

//local var "ln_lai_m sect_main6 sect_main sect_secu6 sect_secu occupation"

local var "ln_lai_m sect_main6 industry6 occupation"

foreach x of varlist `var' {
    replace `x' = . if sample != 1
}

* education variables
gen     sample_1 = 1 if educ_lev <  4 &  sample == 1 
lab var sample_1 "low educated"
gen     sample_2 = 1 if educ_lev >= 4 &  sample == 1 
lab var sample_2 "high educated"

gen     skill = 1 if sample_1 == 1
replace skill = 2 if sample_2 == 1



*===========================================================================
*                                     END
*===========================================================================