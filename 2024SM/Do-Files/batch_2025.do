*!v1.0
*===============================================================================
* TITLE: MPO micro-simulations
*===============================================================================
* Created on : Mar 17, 2020
* Last update: Jul 02, 2024
*===============================================================================
* Prepared by: Sergio Olivieri
* E-mail: solivieri@worldbank.org

* Modified by Israel Osorio-Rodarte
* E-mail: iosoriorodarte@worldbank.org

* Modified by Kelly Y. Montoya: Based on the LAC Data Lab microsimulation
*===============================================================================

*===============================================================================
* TIME
*===============================================================================
capture which etime
if _rc ssc install etime
etime, start
*===============================================================================

*===============================================================================
* PATHS - Modify according to your local route
*===============================================================================
{
* Main
	* MacOSX and Unix
	if (c(os)=="MacOSX"|c(os)=="Unix") & c(username)=="Israel" {
		 gl main  "/Users/Israel/OneDrive/WBG/ETIRI/Projects/FY24/FY24 5 SAS - Bangladesh/main"
	}
	* Windows
	if c(os)=="Windows" & c(username)=="WB308767" {
		 gl main  "C:/Users/WB308767/OneDrive/WBG/ETIRI/Projects/FY24/FY24 5 SAS - Bangladesh/main"
	}

* Path	
	gl path "$main/BGD-MPO-Microsimulation/2024SM"
	
* Do-files path
	gl thedo     "$path/Do-files" // Do-files path

* Globals for country and year identification
	gl country BGD 			// Country to upload
	gl year 2022			// Year to upload - Base year dataset
	gl final_year 2027		// Change for last simulated year
	
	cap mkdir "${path}/Data"
	gl data_root "${path}/Data"
	gl data_in   "${path}/Data/INPUT"
	gl data_out  "${path}/Data/OUTPUT"

* Parameters
	*gl use_saved_parameters "yes" // Not working yet
	gl re_scale "yes" // Change for "yes"/"no" re-scale using total income
	gl sector_model 6 // 
	gl random_remittances "no" // Change for "yes" or "no" on modelling
	gl baseyear 2022

* Databases
	gl reload_dlw 	 ""		// if yes, updates databases from datalibweb
	local loadhhdata ""		// if yes, save dta for Simulation (better in sequential mode)
	local runsim	 "yes" 	// Run simulations
}
*===============================================================================
* Sequential or parallel set-up
*===============================================================================
{
	
* Initial and final year for sequential run
	local iniyear = 2022	// Initial year when doing sequential runs
	local finyear = 2027	// Final year when doing sequential runs

* Parallel run set up
	* If *local parallel is set to "yes". Then n batch files will be created
	* with the name batch_`i'.do located in the working directory.
	* The iniyear and finyear locals above will be modified.

	*local parallel 	"yes"	// If "yes", the program will run in parallel mode
	
		local iniparallelyear = 2022	// First batch file to be created
		local finparallelyear = 2027	// Last batch file to be created
		*local parallel_automatic "yes"  // If yes, parallel run will start automatically
										// Otherwise, call from terminal
		
	* Parallel operationalization, do not modify
	
		scalar xrxx = 1			// Do not modify
		scalar xrxy = 1			// Do not modify
		local iniyear=2025	// Do not modify
		local finyear=2025	// Do not modify

		* Create batch files in MacOSX with sed function
		if "`parallel'"=="yes" & (c(os)=="MacOSX"|c(os)=="Unix") {
			cd "$thedo"
			
			* Create myscript.sh
			cap erase myscript.sh
			cap file close myscript
			file open myscript using myscript.sh, write
			
			* Create n batch_`bi'.do files
			forval bi = `iniparallelyear'/`finparallelyear' {
				
				* Copy batch file
				!cp "0 master.do" "batch_`bi'.do"
				* Replace xrxx and xryy with initial and final years
				!sed -i '' "s/iniyear=2025/iniyear=`bi'/g" batch_`bi'.do
				!sed -i '' "s/finyear=2025/finyear=`bi'/g" batch_`bi'.do
				* Turn off parallel option
				!sed -i '' "s/local[[:space:]]parallel/**local parallel/g" batch_`bi'.do
				
				* Append line to myscript.sh
				file write myscript "/usr/local/bin/stata-mp -b do batch_`bi' &" _n
			}
			
			* Close myscript.sh file
			file close myscript
			!chmod u+rx myscript.sh
			if "`parallel_automatic'"=="yes" {
				!./myscript.sh
			}
			etime
			exit
		}
		
		* Create batch files in Windows with powershell
		if "`parallel'"=="yes" & c(os)=="Windows" {
			cd "$thedo"
			
			* Create myscript.sh
			cap erase myscript.bat
			cap file close myscript
			file open myscript using myscript.bat, write
			
			* Create n batch_`bi'.do files
			forval bi = `iniparallelyear'/`finparallelyear' {
								
				* Copy batch file
				!copy "0 master.do" "batch_`bi'.do"
				* Replace _fake xrxx and xryy with initial and final years
				!powershell -command " (Get-Content batch_`bi'.do) -replace 'iniyear=2025', 'iniyear=`bi'' | Out-File -encoding ASCII batch_`bi'.do "
				!powershell -command " (Get-Content batch_`bi'.do) -replace 'finyear=2025', 'finyear=`bi'' | Out-File -encoding ASCII batch_`bi'.do "
				* Turn off parallel option
				!powershell -command " (Get-Content batch_`bi'.do) -replace '*local parallel', '**local parallel' | Out-File -encoding ASCII batch_`bi'.do "
				
				* Append line to myscript.sh
				if `bi'==`iniparallelyear' file write myscript `"   "`c(sysdir_stata)'/StataMP-64" /e /i do batch_`bi'.do "'
				else                       file write myscript `" | "`c(sysdir_stata)'/StataMP-64" /e /i do batch_`bi'.do "'
			}
			
			* Close myscript.sh file
			file close myscript	
			if "`parallel_automatic'"=="yes" { 
				!myscript.bat
			}
			etime
			exit	
		}
}

*===============================================================================
* Load and save household survey
*===============================================================================
if "`loadhhdata'"=="yes" {
	
	local code="$country"
	local year0=$baseyear
	local cpiversion="09"	
	
	* Download CPI from datalibweb, in Windows
	if "`c(os)'"=="Windows" {
		if "$reload_dlw"=="yes" {
			cap datalibweb, country(Support) year(2005) type(GMDRAW) surveyid(Support_2005_CPI_v`cpiversion'_M) filename(Final_CPI_PPP_to_be_used.dta)
			if _rc {
				noi di ""
				noi di as error "Note: Downloading data from datalibweb failed. Verify connection"
				exit
			}
			else save "$data_in/datalib_support_2005_GMDRAW.dta", replace
		}
		if "$reload_dlw"=="" {
			cap use "$data_in/datalib_support_2005_GMDRAW.dta", clear
			if _rc {
				noi di as error "CPI data not found. Download it using datalibweb in Windows"
				exit
			}	
		}
	}
	
	* Read CPI in MacOSX
	if (c(os)=="MacOSX"|c(os)=="Unix") {
		noi di ""
		noi di as text "Note: MacOSX/Unix, datalibweb skipped. CPI data should exist alreay in the Data/ folder"
		
		cap use "$data_in/datalib_support_2005_GMDRAW.dta", clear
		if _rc {
			noi di as error "CPI data not found. Download it using datalibweb in Windows"
			exit
		}
	}
	
	* Save CPI temporary file
	keep if code=="`code'" & year==`year0'
	keep code year cpi2017 icp2017
	rename code countrycode
	tempfile dlwcpi
	save `dlwcpi', replace

	* 0. load data
	do "$thedo/00_load_data.do"

	drop cpi2017
	merge m:1 countrycode year using `dlwcpi'
	keep if _merge==3
	drop _merge
	save "$data_root/BGD_2022_HIES_v02_M_v02_A_SARMD_SIM.dta", replace
}
*===========================================================================
* run dofiles
*===========================================================================
if "`runsim'"=="yes" {

	forval yyyy = `iniyear'/`finyear' {
		clear all
		clear mata
		clear matrix

		* Load auxiliary simulation programs
		local files : dir "$thedo/auxcode" files "*.do"
		di `files'
		foreach f of local files{
			dis in yellow "`f'"
			qui: run "$thedo/auxcode/`f'"
		}

		* Use base household survey
		if ${year}==2022 use "$data_root/BGD_2022_HIES_v02_M_v02_A_SARMD_SIM.dta", clear
		
		* Globals for reading scenarios
		gl inputs   "$data_in/Macro and elasticities/Inputs elasticities `yyyy'.xlsx" // Country's input Excel file

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

		* Quick summary
			ineqdec0 pc_inc_s  [w=fexp_s]
			
		drop if welfarenom==.
		save "${data_out}/basesim_${model}", replace
	}
}
*===========================================================================
* Display running time	
etime
*===========================================================================
*                                     END
*===========================================================================
