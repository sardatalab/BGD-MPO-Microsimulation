*!v2.0
*===============================================================================
* Macro-Micro Simulations
*===============================================================================
* Created on : July 24, 2024
* Last update: October 1, 2024
*===============================================================================
* Prepared by: South Asia Regional Stats Team

* Initiated by: Sergio Olivieri
* E-mail: colivieri@worldbank.org

* Modified by: Kelly Montoya, Jaime Fernandez Romero and Israel Osorio Rodarte
* For this version e-mail: iosoriorordarte@worldbank.org
*===============================================================================

*===============================================================================
* TIME
*===============================================================================
set processors 4
set type double
frame reset
program drop _all
clear mata
capture which etime
if _rc ssc install etime
etime, start
*===============================================================================

*===============================================================================
* RUNNING STEPS
*===============================================================================
{
* Step 1: Load base household survey data for simulation
	local  step1_loadhhdata  ""		// if yes, save simulation data
		global reload_dlw 	 ""		// SUBOPTION: if yes, reloads simulation databases from datalibweb

* Step 2: Calculate macro-micro inputs, (aka elasticity tool)
	local step2_macromicroinputs ""	// recalculates the macro and micro inputs needed for simulation

* Step 3: Run macro-micro simulation
	local  step3_runsim	  "yes" 	// Run simulations	
		
	* Initial and final year for sequential run
		local iniyear = 2022 // Initial year when doing sequential runs
		local finyear = 2026 // Final year when doing sequential runs

	* *local parallel
		*local parallel 	"yes"	// If "yes", the program will run simulation parallel mode

	* Parallel run set up
		* If *local parallel is set to "yes". Then n batch files will be created
		* with the name batch_`i'.do located in the working directory.
		* Select initial and final parallel years below	
			local iniparallelyear = 2022	// First batch file to be created
			local finparallelyear = 2026	// Last batch file to be created
			*local parallel_automatic "yes"  // If yes, parallel run will start automatically
											// Otherwise, call the batch file from terminal or the command prompt
}		
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

* Data directories
	cap mkdir "${path}/Data"
	gl data_root "${path}/Data"
	gl data_in   "${path}/Data/INPUT"
	gl data_out  "${path}/Data/OUTPUT"

}

*===============================================================================
* Country Parameters
*===============================================================================
{
* Globals for country and year identification
	global country BGD 			// Country to upload
	global year 2022			// household survey year to use
	global final_year 2026		// Last simulated year
	global base_year 2022		// Base year for building LAVs

* Parameters
	*gl use_saved_parameters "yes" // Not working yet
	gl re_scale "" 			// Change for "yes"/"no" re-scale using total income
	gl sector_model 3		// 
	gl random_remittances "no" // Change for "yes" or "no" on modelling
	gl baseyear 2022

}
*===============================================================================
* Parallelization - Don't modify
*===============================================================================
{
	* Parallel operationalization, do not modify
	
		scalar xrxx = 1			// Do not modify
		scalar xrxy = 1			// Do not modify
		local iniyear=2025	// Do not modify
		local finyear=2025	// Do not modify

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
				*!powershell -command " (Get-Content batch_`bi'.do) -replace 'iniyear=2025', 'iniyear=`bi'' | Out-File -encoding ASCII batch_`bi'.do "
				*!powershell -command " (Get-Content batch_`bi'.do) -replace 'finyear=2025', 'finyear=`bi'' | Out-File -encoding ASCII batch_`bi'.do "
				* Turn off parallel option
				*!powershell -command " (Get-Content batch_`bi'.do) -replace '*local parallel', '**local parallel' | Out-File -encoding ASCII batch_`bi'.do "
				
				!powershell -command " (Get-Content batch_`bi'.do) -replace 'iniyear=2025', 'iniyear=`bi'' | Out-File -encoding ASCII batch_`bi'.do ; (Get-Content batch_`bi'.do) -replace 'finyear=2025', 'finyear=`bi'' | Out-File -encoding ASCII batch_`bi'.do ; (Get-Content batch_`bi'.do) -replace '*local parallel', '**local parallel' | Out-File -encoding ASCII batch_`bi'.do"
				
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
* The process must be done before starting the macro-micro simulation.
* Here, we force it to be run only during sequential runs.
* Running it in parallel mode can create problems when the same file is being 
* saved by each parallel instance.
* This happens more often in Windows environments.
*===============================================================================
if "`step1_loadhhdata'"=="yes" & "`parallel'"=="" {
	
	* The harmonized HIES contains 160 variables and 76.8MB
	* The minimum harmonized HIES contains 74 variables and 12.5MB
	
	* 000. Load data
	do "$dofiles/001_load_data.do"
	save "$data_root/BGD_2022_HIES_v02_M_v02_A_SARMD_SIM.dta", replace
	
	
	* Minimum set of variables for simulation
	*#delimit ;
	*local minvarset  "industry3 industry3_2
	*				  occup_year occup_2_year			 
	
	* 010. Prepare variables for regressions
	do "$dofiles/010_variables.do"

	#delimit ;
	local minvarset "year countrycode subnatid1 urban
					hhid pid wgt hsize h_size
					age male edad relationharm id married h_head
					atschool educ_lev 
					active emplyd unemplyd self_emp unpaid salaried salaried2 self_emp2 unpaid2
					labor_rel labor_rel2 public_job
					sect_main sect_secu  
					occupation
					skill_edu  skill_occup	skill
					sample sample_1 sample_2
					h_inc 
					h_lai 
					h_remesas
					h_pensions
					h_capital
					h_renta_imp
					h_otherinla
					h_transfers
					h_nlai
					remitt_any
					depen
					oth_pub
					ln_lai_m
					lai_m
					tot_lai
					lai_s
					food_share nfood_share
					ipcf_ppp17
					pline_int pline_nat welfarenat welfarenom_ppp17 cpi2017 icp2017";

	#delimit cr
	keep `minvarset'	

	compress
	
		global use_saved_parameters "no"
		* 030.model labor incomes by groups
			do "$dofiles/030_occupation.do"
		* 040.model labor incomes by skills
			do "$dofiles/040_labor_income.do"
	
	
	save "$data_root/BGD_2022_HIES_v02_M_v02_A_SARMD_SIM_MIN.dta", replace

}

*===============================================================================
* Step 2: Calculates simulation parameters from macro and micro databases
* The process must be done before simulation steps.
* Here, we force it to be run only during sequential runs.
*===============================================================================
if "`step2_macromicroinputs'"=="yes" & "`parallel'"=="" {

	* 002 Update United Nations World Population Prospects
		* output A: "$data_in/UN WPP/popdata_sar_mpo.dta"
	do "$dofiles/002_import_pop_wpp_wdi.do"
	
	* 003. Process standard-MFMod parameters for Tableau
		* output B: "$data_in/POV_MOD/macrodata.dta"
		* output C: "$data_in/Tableau/AM24/MPO Check data.dta"
		* output D: "$data_in/Macro and elasticities/mfmod_bgd.dta"	
	do "$dofiles/003_sar_mpo_tableau_dashboard.do"
		
	* 004 (master) Elaticity tool based on HIES and LFS
		* 005, 006, and 007 are called within 004
		* output E: "$data_in/Macro and elasticities/input_elasticities_hies.dta"
		* output F: "$data_in/Macro and elasticities/input_elasticities_lfs.dta"
		* output G: "$data_in/Macro and elasticities/Elasticities.dta"
	do "$dofiles/004_masterelasticity.do"
	
		
	* Append all databases
	* Output A
	use "$data_in/UN WPP/popdata_sar_mpo.dta", clear
		isid country year indicator
		decode title, gen(strtitle)
		drop title
		rename strtitle title
		keep 	country year indicator value title date
		order	country year indicator value title date
	tempfile a
	save `a', replace

	* Output B
	use "$data_in/POV_MOD/macrodata.dta", clear
		*decode title, gen(strtitle)
		drop title
		rename strtitle title
		keep 	country year indicator value title date
		order 	country year indicator value title date
	tempfile b
	save `b', replace

	* Output C
	use "$data_in/Tableau/AM_24 MPO Check/MPO Check data.dta", clear
		replace indicator = lower(indicator)
		replace indicator = "ma" + indicator
		keep 	country year indicator value title date
		order	country year indicator value title date
	tempfile c
	save `c', replace
	
	* Output D
	use "$data_in/Macro and elasticities/mfmod_bgd.dta", clear
	append using "$data_in/Macro and elasticities/mfmod_bgd_base.dta"	// For July 2024 baseline
	drop ind
	tempfile d
	save `d', replace
		
	
	use `a', clear
	append using `b'
	append using `c'
	append using `d'
	
	save               "$path/input-mpo.dta", replace
	export excel using "$path/input_MASTER.xlsx", sheet("input-mpo", replace) firstrow(variables)
	
	* INFLOWS
	use if indicator=="mfbxfstremtcd" using "$data_in/Macro and elasticities/mfmod_bgd.dta", clear
	order country year value
	export excel using "$path/input_MASTER.xlsx", sheet("inflows", replace) firstrow(variables)
	
	* OUTPUT E
	use "$data_in/Tableau/AM_24 MPO Check/input-labor-hies.dta", clear
		gen date = "`c(current_date)'"
		keep 	country year indicator value title date nsectors
		order 	country year indicator value title date	nsectors
		tempfile e
		save `e', replace
	
	* OUTPUT F
	use "$data_in/Tableau/AM_24 MPO Check/input-labor-lfs.dta", clear
		gen date = "`c(current_date)'"		
		keep 	country year indicator value title date nsectors
		order 	country year indicator value title date nsectors
		tempfile f
		save `f', replace
	
	use `e', clear
	append using `f'
	
	save               "$path/input-labor", replace
	export excel using "$path/input_MASTER.xlsx", sheet("input-labor", replace) firstrow(variables)
	
	* OUTPUT G
	use "$data_in/Macro and elasticities/Elasticities.dta", clear
	save  			   "$path/input-elasticities.dta", replace
	export excel using "$path/input_MASTER.xlsx", sheet("Elasticities") sheetreplace firstrow(variables)
}
*===========================================================================
* run dofiles
*===========================================================================
if "`step3_runsim'"=="yes" {


	forval yyyy = `iniyear'/`finyear' {
		clear all
		clear mata
		clear matrix

		* Declarre simulation year
		global sim_year = `yyyy'
		
		if "`yyyy'"=="`iniyear'" global use_saved_parameters "yes"
		else 					 global use_saved_parameters "yes"

		* Use base household survey
		if ${year}==2022 use "$data_root/BGD_2022_HIES_v02_M_v02_A_SARMD_SIM_MIN.dta", clear
		
		* Globals for reading scenarios
		*gl inputs   "$path/Microsimulation_Inputs_BGD_A3_BaUAM2024.xlsm" // Country's input Excel file
		gl inputs   "$path/Microsimulation_Inputs_BGD_A3_CrisisAM2024.xlsm"
		
		* Load auxiliary simulation programs
		local files : dir "$dofiles/auxcode" files "*.*do"
		di `files'
		foreach f of local files{
			dis in yellow "`f'"
			mata: mata set matastrict off
			qui: run "$dofiles/auxcode/`f'"
		}
		
		* 020.input parameters
			do "$dofiles/020_parameters.do"
		* 030.model labor incomes by groups
			*do "$dofiles/030_occupation.do"
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
		* 140. household consumption
			do "$dofiles/140_household_consumption.do"
			
		* Quick summary
			ineqdec0 welfare_ppp17  [w=wgt]
			ineqdeco pc_con_s		[w=fexp_s]
			apoverty welfare_ppp17  [w=wgt], line(2.15)
			apoverty pc_con_s pc_con_preadj [w=fexp_s], line(2.15)
			
		drop if welfarenom==.
		save "${data_out}/basesim_`yyyy'", replace
	}
}
*===========================================================================
* Display running time	
etime
*===========================================================================
*                                     END
*===========================================================================
