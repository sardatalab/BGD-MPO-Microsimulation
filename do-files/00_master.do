*!v1.0
*===========================================================================
* TITLE: MPO micro-simulations
*===========================================================================
* Created on : Mar 17, 2020
* Last update: Jul 02, 2024
*==========================================================================
* Prepared by: Sergio Olivieri
* E-mail: solivieri@worldbank.org

* Modified by Israel Osorio-Rodarte
* E-mail: iosoriorodarte@worldbank.org

* Modified by Kelly Y. Montoya: Based on the LAC Data Lab microsimulation
*===========================================================================

*===========================================================================
* TIME
*===========================================================================
capture which etime
if _rc ssc install etime
etime, start
*===========================================================================

*===========================================================================
* PATHS - Modify according to your local route
*===========================================================================

* Main path
	* MacOSX and Unix
	if (c(os)=="MacOSX"|c(os)=="Unix") & c(username)=="Israel" {
		 gl path  "/Users/Israel/OneDrive/WBG/ETIRI/Projects/FY24/FY24 5 SAS - Bangladesh/main/BGD-MPO-Microsimulation"
	}
	* Windows
	if c(os)=="Windows" & c(username)=="WB308767" {
		 gl path  "C:/Users/WB308767/OneDrive - WBG/ETIRI/Projects/FY24/FY24 5 SAS - Bangladesh/main/BGD-MPO-Microsimulation"
	}

* Do-files path
	gl thedo     "$path/do-files" // Do-files path

* Globals for country and year identification
	gl country BGD 			// Country to upload
	gl year 2022			// Year to upload - Base year dataset
	gl final_year `yyyy'	// Change for last simulated year

* Globals for country-specific paths
	gl inputs   "${path}/inputs/Inputs elasticities `yyyy'.xlsx" // Country's input Excel file
	
	cap mkdir "${path}/Data"
	gl data_out "${path}/Data"

* Parameters
	*gl use_saved_parameters "yes" // Not working yet
	global re_scale "yes" // Change for "yes"/"no" re-scale using total income
	global sector_model 6 // 
	global random_remittances "no" // Change for "yes" or "no" on modelling
	global baseyear 2022

*===========================================================================
* Sequential or parallel set-up
*===========================================================================

* Initial and final year for sequential run
	local iniyear = 2022	// Initial year when doing sequential runs
	local finyear = 2027	// Final year when doing sequential runs

* If local parallel (below) is set to "yes". Then n batch files are created
* with the name batch_`i'.do located in the working directory.
* The iniyear and finyear locals above are replaced with those in line 91 and 92
* To run: copy and past the routine lines above in terminal or command prompt.

local parallel 	"yes"
		local iniparallelyear = 2022	// First batch file to be created
		local finparallelyear = 2027	// Last batch file to be created
		scalar xrxx = 1			// Do not modify
		scalar xrxy = 1			// Do not modify
		local _fakeiniyear=xrxx	// Do not modify
		local _fakefinyear=xrxy	// Do not modify

	
	if "`parallel'"=="yes" & "`c(os)'"=="MacOSX" {
		cd "$thedo"
		
		* Create myscript.sh
		cap erase myscript.sh
		cap file close myscript
		file open myscript using myscript.sh, write
		
		forval bi = `iniparallelyear'/`finparallelyear' {
			
			* Copy batch file
			!cp "00_master.do" "batch_`bi'.do"
			* Replace xrxx and xryy with initial and final years
			!sed -i '' "s/_fakeiniyear=xrxx/iniyear=`bi'/g" batch_`bi'.do
			!sed -i '' "s/_fakefinyear=xrxy/finyear=`bi'/g" batch_`bi'.do
			* Turn off parallel option
			!sed -i '' "s/local[[:space:]]parallel/*local parallel/g" batch_`bi'.do
			
			* Append line to myscript.sh
			file write myscript "stata-mp -b do batch_`bi' &" _n
		}
		
		* Close file
		file close myscript	
		etime
		exit
	}

	if "`parallel'"=="yes" & "`c(os)'"=="Windows" {
		cd "$thedo"
		
		* Create myscript.sh
		cap erase myscript.bat
		cap file close myscript
		file open myscript using myscript.bat, write

		forval bi = `iniparallelyear'/`finparallelyear' {
			
			
			* Copy batch file
			!copy "00_master.do" "batch_`bi'.do"
			* Replace _fake xrxx and xryy with initial and final years
			!powershell -command " (Get-Content batch_`bi'.do) -replace '_fakeiniyear=xrxx', 'iniyear=`bi'' | Out-File -encoding ASCII batch_`bi'.do "
			!powershell -command " (Get-Content batch_`bi'.do) -replace '_fakefinyear=xrxy', 'finyear=`bi'' | Out-File -encoding ASCII batch_`bi'.do "
			* Turn off parallel option
			!powershell -command " (Get-Content batch_`bi'.do) -replace 'local parallel', '*local parallel' | Out-File -encoding ASCII batch_`bi'.do "
			
			* Append line to myscript.sh
			if `bi'==`iniparallelyear' file write myscript `"   "`c(sysdir_stata)'/StataMP-64" /e /i do batch_`bi'.do "'
			else                       file write myscript `" | "`c(sysdir_stata)'/StataMP-64" /e /i do batch_`bi'.do "'
		}
	
		file close myscript	
		!myscript.bat
		etime
		exit	
	}	


*===========================================================================
* Microsimulation master loop
*===========================================================================

forval yyyy = `iniyear'/`finyear' {

clear all
clear mata
clear matrix
set more off


*===========================================================================
* select household survey
*===========================================================================

*Open datalib data ppp
local code="$country"
local year0=$baseyear
local cpiversion="09"	
cap datalibweb, country(Support) year(2005) type(GMDRAW) surveyid(Support_2005_CPI_v`cpiversion'_M) filename(Final_CPI_PPP_to_be_used.dta)
if _rc {
	use "${path}/Data/datalib_support_2005_GMDRAW.dta", clear
}
else {
	save"${path}/Data/datalib_support_2005_GMDRAW.dta", replace
}

keep if code=="`code'" & year==`year0'
keep code year cpi2017 icp2017
rename code countrycode
tempfile dlwcpi
save `dlwcpi', replace


* 0. load data
	do "$thedo/0_load_data.do"

	drop cpi2017
	merge m:1 countrycode year using `dlwcpi'
	keep if _merge==3
	drop _merge
	save "$path/Data/HIES 2022/BGD_2022_HIES_v02_M_v02_A_SARMD_SIM.dta", replace
	
*===========================================================================
* run programs
*===========================================================================

local files : dir "$thedo/programs" files "*.do"
foreach f of local files{
	dis in yellow "`f'"
	qui: run "$thedo/programs//`f'"
}

*===========================================================================
* run dofiles
*===========================================================================

* 1.input parameters
	do "$thedo/01_parameters.do"
* 2.prepare variables
	do "$thedo/02_variables.do"
* 3.model labor incomes by groups
	do "$thedo/03_occupation.do"
* 4.model labor incomes by skills
	do "$thedo/04_labor_income.do"
* 5.modeling population growth
	do "$thedo/05_population.do"
* 6.modeling labor activity rate
	do "$thedo/06_activity.do"
* 7.modeling unemployment rate
	do "$thedo/07_unemployment.do"
* 8.modeling changes in employment by sectors
	do "$thedo/08_struct_emp.do"
* 9.modeling labor income by sector
	do "$thedo/09_asign_labor_income.do"	
* 10.income growth by sector
	do "$thedo/$do_income.do"
* 11. total labor incomes
	do "$thedo/11_total_income.do"	
* 12. total non-labor incomes
	do "$thedo/12_assign_nlai.do"
* 13. household income
	do "$thedo/13_household_income.do"

drop if welfarenom==.
save "${data_out}/basesim_${model}", replace
*stop
/*
* 14. poverty line adjustment
	run "$thedo/14_prices_consump.do"
* 15. compensation - emergency bonus
    run "$thedo/15_transfers_emergency_bonus.do"
* 16. aumento cobertura BDH
   // do "$thedo/16_transfers_bdh.do"
* 17. results
	run "$thedo/17_labels.do"
* 18. export results back to the Excel	
    run "$thedo/18_results.do"
* Mitigation Measures
	if inlist("${country}","CHL") & "${model}"=="2021" run "$thedo/${country}_mm2021.do"
	if inlist("${country}","CHL","PAN","ECU","PER","PRY") & !inlist("${model}","2021") run "$thedo/${country}_mm.do"
	if "${country}"=="BRA" {
		if inlist("${model}","2022","2023") run "$thedo/${country}_mm${model}.do"
		else run "$thedo/${country}_mm.do"
	}
	if "${country}"=="MEX" & "${model}"!="2019" run "$thedo/${country}_mm.do"
*/

*===========================================================================
* quick summary
*===========================================================================

*sum poor* vuln midd upper [w=fexp_s] if pc_inc_s!=.
ineqdec0 pc_inc_s  [w=fexp_s]
*	ainequal pc_inc_s [w=fexp_s], all

}


*===========================================================================
* Display running time	
etime
*===========================================================================
*                                     END
*===========================================================================
