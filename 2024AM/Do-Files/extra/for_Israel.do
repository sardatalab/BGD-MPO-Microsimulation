* This variable includes those reporting income but not included in lstatus (original lstatus) 
rename  lstatus lstatus_0 
gen     lstatus = lstatus_0 if age>=15
replace lstatus = 1		if  ila!=0 & ila!=. & age>=15
 
gen labP = 0 if lstatus !=.
replace labP = 1 if lstatus == 1 | lstatus == 2

gen labF = .
replace labF = 1 if lstatus == 1 | lstatus == 2
 
replace  labF = 0 if lstatus == 3
tab lstatus, gen(aux)
 
rename aux1 emp
rename aux2 unEmp
rename aux3 inac

replace emp = . if labF == 0
replace unEmp = . if labF == 0
gen empR = 0 if age>=15
replace empR = 1 if emp == 1

label var pop "Population (15+)"
label var emp "Employed (15+)"
label var unEmp "Unemployed"
label var empR "Employment rate"
label var inac "Inactive"
label var labF "Labour force"
label var labP "Labour participation"
label var lstatus_0 "Labor status original"
label var lstatus "Labor status incl. reporting income not in lstatus original"