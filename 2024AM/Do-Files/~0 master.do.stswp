*!v2.0
*===============================================================================
* Macro-Micro Simulations
*===============================================================================
* Created on : July 24, 2024
* Last update: July 24, 2024
*===============================================================================
* Prepared by: South Asia Regional Stats Team

* Initiated by: Sergio Olivieri
* E-mail: colivieri@worldbank.org

* Modified by: Israel Osorio Rodarte
* E-mail: iosoriorordarte@worldbank.org
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
		 gl main  "/Users/Israel/OneDrive/WBG/ETIRI/Projects/FY25/FY25 - SAR MPO AM24"
	}
	* Windows
	if c(os)=="Windows" & c(username)=="WB308767" {
		 gl main  "C:/Users/WB308767/OneDrive/WBG/ETIRI/Projects/FY25/FY25 - SAR MPO AM24"
	}
	
* Path	
	gl path "$main/BGD-MPO-Microsimulation/2024AM"
	cd "$path"
	
* Do-files path
	global dofiles     "$path/Do-files" // Do-files path

* Globals for country and year identification
	global country BGD 			// Country to upload
	global year 2022			// household survey year to use
	global final_year 2027		// Last simulated year
	global base_year 2022		// Base year for building LAVs
	
	cap mkdir "${path}/Data"
	gl data_root "${path}/Data"
	gl data_in   "${path}/Data/INPUT"
	gl data_out  "${path}/Data/OUTPUT"

* Parameters
	*gl use_saved_parameters "yes" // Not working yet
	gl re_scale "yes" 			// Change for "yes"/"no" re-scale using total income
	gl sector_model 6 			// 
	gl random_remittances "no" // Change for "yes" or "no" on modelling
	gl baseyear 2022
	
* Steps
	* Step 1: Load base household survey data for simulation
	local  step1_loadhhdata ""		// if yes, save dta for Simulation (forced for sequential mode)
		global reload_dlw 	 ""		// if yes, reloads databases from datalibweb

	* Step 2: Run elasticity tool
	local step2_macromicroinputs "yes"	// If yes, loads macro and micro inputs needed for simulation

	* Step 3: Run simulation
	local  step3_runsim	  "" 	// Run simulations	

* Initial and final year for sequential run
	local iniyear = 2027	// Initial year when doing sequential runs
	local finyear = 2027	// Final year when doing sequential runs

* Local parallel
	local parallel 	""	// If "yes", the program will run in parallel mode
	
}
*===============================================================================
* Sub-options for parallel run, if enabled
*===============================================================================
{
	
* Parallel run set up
	* If local parallel is set to "yes". Then n batch files will be created
	* with the name batch_`i'.do located in the working directory.
	* The iniyear and finyear locals above will be modified.	
		local iniparallelyear = 2022	// First batch file to be created
		local finparallelyear = 2027	// Last batch file to be created
		local parallel_automatic "yes"  // If yes, parallel run will start automatically
										// Otherwise, call from terminal
		
	* Parallel operationalization, do not modify
	
		scalar xrxx = 1			// Do not modify
		scalar xrxy = 1			// Do not modify
		local _fakeiniyear=xrxx	// Do not modify
		local _fakefinyear=xrxy	// Do not modify

		* Create batch files in MacOSX with sed function
		if "`parallel'"=="yes" & (c(os)=="MacOSX"|c(os)=="Unix") {
			cd "$dofiles"
			
			* Create myscript.sh
			cap erase myscript.sh
			cap file close myscript
			file open myscript using myscript.sh, write
			
			* Create n batch_`bi'.do files
			forval bi = `iniparallelyear'/`finparallelyear' {
				
				* Copy batch file
				!cp "0 master.do" "batch_`bi'.do"
				* Replace xrxx and xryy with initial and final years
				!sed -i '' "s/_fakeiniyear=xrxx/iniyear=`bi'/g" batch_`bi'.do
				!sed -i '' "s/_fakefinyear=xrxy/finyear=`bi'/g" batch_`bi'.do
				* Turn off parallel option
				!sed -i '' "s/local[[:space:]]parallel/*local parallel/g" batch_`bi'.do
				
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
			cd "$dofiles"
			
			* Create myscript.sh
			cap erase myscript.bat
			cap file close myscript
			file open myscript using myscript.bat, write
			
			* Create n batch_`bi'.do files
			forval bi = `iniparallelyear'/`finparallelyear' {
								
				* Copy batch file
				!copy "0 master.do" "batch_`bi'.do"
				* Replace _fake xrxx and xryy with initial and final years
				!powershell -command " (Get-Content batch_`bi'.do) -replace '_fakeiniyear=xrxx', 'iniyear=`bi'' | Out-File -encoding ASCII batch_`bi'.do "
				!powershell -command " (Get-Content batch_`bi'.do) -replace '_fakefinyear=xrxy', 'finyear=`bi'' | Out-File -encoding ASCII batch_`bi'.do "
				* Turn off parallel option
				!powershell -command " (Get-Content batch_`bi'.do) -replace 'local parallel', '*local parallel' | Out-File -encoding ASCII batch_`bi'.do "
				
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
* Step 1: Load and save household survey for simulation
* The process must be done before simulation steps.
* Here, we force it to be run only during sequential runs.
* Running it in parallel mode can create problems when the same file is being 
* saved by each parallel instance.
* This happens more often in Windows environments.
*===============================================================================
if "`step1_loadhhdata'"=="yes" & "`parallel'"=="" {
	
	* 000. Load data
	do "$dofiles/000_load_data.do"
	save "$data_root/BGD_2022_HIES_v02_M_v02_A_SARMD_SIM.dta", replace

}

*===============================================================================
* Step 2: Calculates simulation parameters from macro and micro databases
* The process must be done before simulation steps.
* Here, we force it to be run only during sequential runs.
*===============================================================================
if "`step2_macromicroinputs'"=="yes" & "`parallel'"=="" {
	
	* 001. Process standard-MFMod parameters for Tableau
	*do "$dofiles/001_sar_mpo_tableau_dashboard.do"
	
	* 002. Process custom-made MFMod parameters for Tableau
	*do "$dofiles/002_sar_mpo_tableau_dashboard.do" // does not exist yet
	
	* 003. Elaticity tool based on HEIS and LFS
	do "$dofiles/003_masterelasticity.do"
}
*===========================================================================
* run dofiles
*===========================================================================
if "`runsim'"=="yes" {

	forval yyyy = `iniyear'/`finyear' {
		clear all
		clear mata
		clear matrix

		* Declarre simulation year
		global sim_year = `yyyy'
		
		* Load auxiliary simulation programs
		local files : dir "$dofiles/auxcode" files "*.do"
		di `files'
		foreach f of local files{
			dis in yellow "`f'"
			qui: run "$dofiles/auxcode/`f'"
		}

		* Use base household survey
		if ${year}==2022 use "$data_root/BGD_2022_HIES_v02_M_v02_A_SARMD_SIM.dta", clear
		
		* Globals for reading scenarios
		gl inputs   "$data_in/Macro and elasticities/Inputs elasticities `yyyy'.xlsx" // Country's input Excel file

		* 010.input parameters
			do "$dofiles/010_parameters.do"
		* 020.prepare variables
			do "$dofiles/020_variables.do"
		* 030.model labor incomes by groups
			do "$dofiles/030_occupation.do"
		* 040.model labor incomes by skills
			do "$dofiles/040_labor_income.do"
		* 050.modeling population growth
			do "$dofiles/050_population.do"
		* 060.modeling labor activity rate
			do "$dofiles/060_activity.do"
		* 070.modeling unemployment rate
			do "$dofiles/070_unemployment.do"
		* 080.modeling changes in employment by sectors
			do "$dofiles/080_struct_emp.do"
		* 090.modeling labor income by sector
			do "$dofiles/090_asign_labor_income.do"	
		* 100.income growth by sector
			if "$re_scale" == "yes" do "$dofiles/100_income_rel_new.do"
			if "$re_scale" == ""    do "$dofiles/101_income_rel_new_no_rescaling.do"
		* 110. total labor incomes
			do "$dofiles/110_total_income.do"	
		* 120. total non-labor incomes
			if "$random_remittances" == "no"  do "$dofiles/120_assign_nlai.do"
			if "$random_remittances" == "yes" do "$dofiles/121_assign_nlai.do"
		* 130. household income
			do "$dofiles/130_household_income.do"

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
