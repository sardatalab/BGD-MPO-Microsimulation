*!v1.0 July 25, 2024
*===============================================================================
* This do-file reads information from MFMod and sends to 
* a series of databases called MPO 
*===============================================================================
clear
set more off

********************************************************************************
* Set initial parameters
********************************************************************************


**************************************
* Location to save Tableau Dashboards
**************************************

	 global rpath "$data_in/Tableau"	               

*******************
* Steps to perform 
*******************

local dostep1 ""	

*********************
* Application folder
*********************
global application "AM_24"
global wpath "${qpath}"
global cpath "${rpath}/${application} MPO Check"

********************************************************************************
* Step 1: Read household surveys
********************************************************************************
if "`dostep1'"=="yes" {

if c(os)=="Windows" {

	* Get list of csv files with "n" suffix
	* n suffix means new data
	local csvfiles : dir "$wpath" files "*n.csv", respectcase
	noi di `csvfiles'

	* Loop for all csv files
	local j = 1
	foreach file of local csvfiles {
		insheet using "$wpath/`file'", names clear
		
		rename v1 year
		drop if year==.
		
		* Replace NULL for zeros
		foreach var of varlist _all {
			if "`var'"!="year" {
				cap replace `var' = "" if `var'=="NULL"
				rename `var' value`var'
			}
		}
		
		destring _all, replace 
		reshape long value, i(year) j(variable) string
		
		if `j'==1 {
			tempfile csvdata
			save `csvdata', replace
		}
		else {
			append using `csvdata'
			save `csvdata', replace
		}
		local j = `j'+1
	}

	* Format csv files
	use `csvdata', clear

		gen country  = upper(substr(variable,1,3))
		gen mne      = upper(substr(variable,4,30))
		gen length = length(mne)
		gen mnemonic = substr(mne,1,length)
		gen type = "N"
			drop variable mne length

	gen ml = length(mnemonic)
	replace mnemonic = substr(mnemonic,1,ml-2)

	* Create variable labels
	gen varlabel=""
	replace varlabel = "Potential Output Growth (constant 2010 U.S. dollars)" if mnemonic=="PGDP"
	replace varlabel = "GDP growth (constant 2010 LCU, percentage change)" if mnemonic=="GDPZ"
	replace varlabel = "Inflation (consumer price index 2000 = 100, percentage change)" if mnemonic=="CPIZ"
	replace varlabel = "Output gap (percentage of potential output)" if mnemonic=="GAP_"
	replace varlabel = "Current account balance (percentage share of nominal GDP)" if mnemonic=="CAB_"
	replace varlabel = "General government balance (% of nominal GDP)" if mnemonic=="DEFICIT_"
	replace varlabel = "General government gross debt (% of nominal GDP)" if mnemonic=="DEBT_"
	replace varlabel = "Private consumption growth (constant 2010 LCU, percentae change)" if mnemonic=="CONZ"
	replace varlabel = "Government consumption growth (constant 2010 LCU, percentage change)" if mnemonic=="GOVZ"
	replace varlabel = "Fixed investment growth (constant 2010 LCU, percentage change)" if mnemonic=="INVZ"
	replace varlabel = "Exports growth (constant 2010 LCU, percentage change)" if mnemonic=="EXPZ"
	replace varlabel = "Imports growth (constant 2010 LCU, percentage change)" if mnemonic=="IMPZ"
	replace varlabel = "Private consumption growth (percentage share of real GDP)" if mnemonic=="R_CON"
	replace varlabel = "Government consumption growth (percentage share of real GDP)" if mnemonic=="R_GOV"
	replace varlabel = "Fixed investment growth (percentage share of real GDP)" if mnemonic=="R_INV"
	replace varlabel = "Fixed investment (percentage share of real GDP)" if mnemonic=="R_STKB"
	replace varlabel = "Exports growth (percentage share of real GDP)" if mnemonic=="R_EXPZ"
	replace varlabel = "Imports growth (percentage share of real GDP)" if mnemonic=="R_IMPZ"
	replace varlabel = "Statistical discrepancy (percentage share of real GDP)" if mnemonic=="R_DISC"
	replace varlabel = "GDP deflator (baseyear = 2010, percentage change)" if mnemonic=="GDPZX"
	replace varlabel = "Private consumption deflator (baseyear = 2010, percentage change)" if mnemonic=="CONZX"
	replace varlabel = "Government consumption deflator (baseyear = 2010, percentage change)" if mnemonic=="GOVZX"
	replace varlabel = "Fixed investment deflator (baseyear = 2010, percentage change)" if mnemonic=="INVZX"
	replace varlabel = "Exports deflator (baseyear = 2010, percentage change)" if mnemonic=="EXPZX"
	replace varlabel = "Imports deflator (baseyear = 2010, percentage change)" if mnemonic=="IMPZX"
	replace varlabel = "GDP at factor cost growth (constant 2010 LCU, percentage change)" if mnemonic=="GDPFC"
	replace varlabel = "Taxes growth (constant 2010 LCU, percentage change)" if mnemonic=="TAXFC"
	replace varlabel = "Agricultural growth (constant 2010 LCU, percentage change)" if mnemonic=="AGRFC"
	replace varlabel = "Industry growth (constant 2010 LCU, percentage change)" if mnemonic=="INDFC"
	replace varlabel = "Services growth (constant 2010 LCU, percentage change)" if mnemonic=="SRVFC"
	replace varlabel = "Taxes (percentage share of real GDP at factor cost)" if mnemonic=="R_TAXFC"
	replace varlabel = "Agriculture (percentage share of real GDP at factor cost)" if mnemonic=="R_AGRFC"
	replace varlabel = "Industry (percentage share of real GDP at factor cost)" if mnemonic=="R_INDFC"
	replace varlabel = "Services (percentage share of real GDP at factor cost)" if mnemonic=="R_SRVFC"
	replace varlabel = "GDP at factor cost deflator (baseyear = 2010, percentage change)" if mnemonic=="GDPFCX"
	replace varlabel = "Tax deflator (baseyear = 2010, percentage change)" if mnemonic=="TAXFCX"
	replace varlabel = "Agriculture deflator (baseyear = 2010, percentage change)" if mnemonic=="AGRFCX"
	replace varlabel = "Industry deflator (baseyear = 2010 percentage change)" if mnemonic=="INDFCX"
	replace varlabel = "Services deflator (baseyear = 2010, percentage change)" if mnemonic=="SRVFCX"
	replace varlabel = "Labor force growth (percentae change %)" if mnemonic=="LABZ"
	replace varlabel = "Total factor productivity growth (percentage change %)" if mnemonic=="TFPZ"
	replace varlabel = "Capital stock growth (percentage change %)" if mnemonic=="STKZ"
	replace varlabel = "Potential GDP growth (constant 2010 LCU, percentage change)" if mnemonic=="PGDPZ"
	replace varlabel = "Labor force (contribution, percentage points %p)" if mnemonic=="C_LABZ"
	replace varlabel = "Total factor productiity (contribution, percentage points %p)" if mnemonic=="C_TFPZ"
	replace varlabel = "Capital stock (contribution, percentage points %p)" if mnemonic=="C_STKZ"
	replace varlabel = "Potential GDP growth (constant 2010 LCU, percentage change)" if mnemonic=="C_PGDPZ"
	replace varlabel = "Capital and financial account balance (percentage share of nominal GDP)" if mnemonic=="CAF_"
	replace varlabel = "Financial account balance, excl. R.A. (percentage share of nominal GDP)" if mnemonic=="FINX_"
	replace varlabel = "Reserve asset changes [R.A.] (percentage share of nominal GDP)" if mnemonic=="RACG_"
	replace varlabel = "Net errors and omissions (percentage share of nominal GDP)" if mnemonic=="NEOM_"
	replace varlabel = "Capital account balance (percentage share of nominal GDP)" if mnemonic=="CAP_"
	replace varlabel = "Financial account balance (percentage share of nominal GDP)" if mnemonic=="FINT_"
	replace varlabel = "Foreign direct investment balance (percentage share of nominal GDP)" if mnemonic=="FDI_"
	replace varlabel = "Portfolio investment balance, equity (percentage share of nominal GDP)" if mnemonic=="PFE_"
	replace varlabel = "Portfolio investment balance, debt (percentae share of nominal GDP)" if mnemonic=="PFD_"
	replace varlabel = "Other investment balance (percentage share of nominal GDP)" if mnemonic=="OTHR_"
	replace varlabel = "Export market (percentage change %)" if mnemonic=="XMKT"
	replace varlabel = "Nominal exchange rate (local currency per USD)" if mnemonic=="PANUSATLS"
	replace varlabel = "Nominal effective exchange rate (2010 = 100)" if mnemonic=="NEER"
	replace varlabel = "Real effective exchange rate (2010 = 100)" if mnemonic=="REER"
		
	split varlabel, p(" (")

	rename varlabel1 title
	rename varlabel2 subtitle
	replace subtitle = "(" +  subtitle

	save "${cpath}/MPO Check data All countries.dta", replace

}

if (c(os)=="MacOSX"|c(os)=="Unix") {
	noi di ""
	noi di as text `"Note: MacOSX/Unix, reading MFMOD Check. Data should exist alreay in the "$data_in/DLW" folder"'
}

}


********************************************************************************
* Step 2: 
********************************************************************************
if "`dostep2'"=="yes" {
	

		
	save           "$cpath/MPO Check data.dta", replace

	* Splitting the databases for faster load	
	preserve
		*drop country wbcountry_name wbccode wbregion_name wblending
		*drop mnemonic  varlabel title subtitle
		compress
		outsheet using "$cpath/MPO Check data.csv", comma replace
	restore
	
	preserve
		contract countryid country wbcountry_name wbccode wbregion_name wblending 
		order    countryid country wbcountry_name wbccode wbregion_name wblending 
		sort     countryid
		drop _freq
		outsheet using "$cpath/MPO Country Names.csv", comma replace
	restore
	
	preserve
		contract indicatorid mnemonic  varlabel title subtitle
		order    indicatorid mnemonic  varlabel title subtitle
		sort     indicatorid mnemonic  varlabel title subtitle
		drop _freq
		outsheet using "$cpath/MPO Indicator Names.csv", comma replace
	restore
	
	preserve
		gen byte topicid = .	
			replace topicid = 2 if mnemonic=="AGRFC" //	Agricultural growth (constant 2010 LCU, percentage change)
			replace topicid = 2 if mnemonic=="R_AGRFC" //	Agriculture (percentage share of real GDP at factor cost)
			replace topicid = 2 if mnemonic=="INDFC" //	Industry growth (constant 2010 LCU, percentage change)
			replace topicid = 2 if mnemonic=="R_INDFC" //	Industry (percentage share of real GDP at factor cost)
			replace topicid = 2 if mnemonic=="R_SRVFC" //	Services (percentage share of real GDP at factor cost)	
			replace topicid = 2 if mnemonic=="SRVFC" //	Services growth (constant 2010 LCU, percentage change)	
		gen topicname = ""
			replace topicname = "Sectoral" if topicid==2
	
		gen sectorid = . 
			replace sectorid = 10 if mnemonic=="AGRFC" //	Agricultural growth (constant 2010 LCU, percentage change)
			replace sectorid = 10 if mnemonic=="R_AGRFC" //	Agriculture (percentage share of real GDP at factor cost)
			replace sectorid = 20 if mnemonic=="INDFC" //	Industry growth (constant 2010 LCU, percentage change)
			replace sectorid = 20 if mnemonic=="R_INDFC" //	Industry (percentage share of real GDP at factor cost)
			replace sectorid = 30 if mnemonic=="R_SRVFC" //	Services (percentage share of real GDP at factor cost)	
			replace sectorid = 30 if mnemonic=="SRVFC" //	Services growth (constant 2010 LCU, percentage change)				
		gen sectorname = ""
			replace sectorname = "Agriculture" 	if sectorid==10
			replace sectorname = "Industry" 	if sectorid==20
			replace sectorname = "Services"		if sectorid==30
	
		contract topicid topicname indicatorid sectorid sectorname
		drop _freq
		drop if topicid==.
		outsheet using "$cpath/MPO Topics.csv", comma replace
	restore

	
	
}











