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

*********************************
* Location of raw csv files with 
* historical and forecast data
*********************************
global qpath "S:/MFM/MFMOD/AM24/data/fcst_check/AM24"
* For SM24, the location is: S:/MFM/MFMOD/SM24/data/fcst_check/SM24
* "//rsb-vtest/c$/wamp/apps/isimulate/trunk/web/MFMod_support/consistency_widget"
* \\rsb-vtest\c$\wamp\apps\isimulate\trunk\web\MFMod_support\consistency_widget

**************************************
* Location to save Tableau Dashboards
**************************************
if "`c(os)'"=="Windows" {
	 global rpath "C:/Users/WB308767/OneDrive/WBG/ETIRI/Projects/FY25/FY25 - SAR MPO AM24/BGD-MPO-Microsimulation/2024AM/Data/INPUT/Tableau"
	               
}
else {
	global rpath "/Users/Israel/OneDrive/WBG/ETIRI/Projects/FY25/FY25 - SAR MPO AM24/BGD-MPO-Microsimulation/2024AM/Data/INPUT/Tableau"
}

*******************
* Steps to perform 
*******************

local dostep1 ""	// Download data from MFMod/iSimulate Platform
local dostep2 "yes"	// Create aggregates and export CSV data for Tableau

*********************
* Application folder
*********************
global application "AM_24"
global wpath "${qpath}"
global cpath "${rpath}/${application} MPO Check"

********************************************************************************
* Step 1: Download data from MFMod/iSimualte platform
********************************************************************************
if "`dostep1'"=="yes" {

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


********************************************************************************
if "`dostep2'"=="yes" {
	
	* Import World Bank country names from World Bank data
	
	import excel using ///
	"https://datacatalogfiles.worldbank.org/ddh-published/0037712/DR0090755/CLASS.xlsx", ///
	clear firstrow
		cap drop F
		rename Economy wbcountry_name
		rename Code wbccode
		rename Region wbregion_name
		rename Incomegroup wbincome_name
		rename Lending wblending
		drop if wbregion_name == ""
		
		foreach var of varlist wbcountry_name - wblending {
			replace `var' = "" if `var' == ""
		}
		
		clonevar country = wbccode
		replace country = "ROM" if country=="ROU"
		tempfile wbccodes
	save `wbccodes', replace
	
	* Merge with MPO check data
	use "$cpath/MPO Check data All countries.dta", clear
		merge m:1 country using `wbccodes'
		keep if _merge==1 | _merge==3
		drop _merge
		
	replace wbcountry_name = "Low & Middle Income"	if country=="DEV"
	replace wbregion_name = "Low & Middle Income"	if country=="DEV"
	replace wbincome_name = "Low & Middle Income"	if country=="DEV"
	replace wblending = ""							if country=="DEV"
	*replace wbother = ""							if country=="DEV"
	
	replace wbcountry_name = "High Income"	if country=="HIY"
	replace wbregion_name = "High Income"	if country=="HIY"
	replace wbincome_name = "High Income"	if country=="HIY"
	replace wblending = ""							if country=="HIY"
	*replace wbother = ""							if country=="HIY"

	replace wbcountry_name = "World"	if country=="WLT"
	replace wbregion_name = "World"		if country=="WLT"
	replace wbincome_name = "World"		if country=="WLT"
	replace wblending = ""							if country=="WLT"
	*replace wbother = ""							if country=="WLT"
	
	gen category = ""
	replace category = "MPO Dashboard"
	
	replace wbregion = "East Asia & Pacific"		if country=="EAP"
	replace wbregion = "Europe & Central Asia"		if country=="ECA"
	replace wbregion = "Latin America & Caribbean"	if country=="LAC"
	replace wbregion = "Middle East & North Africa"	if country=="MNA"
	replace wbregion = "South Asia"					if country=="SAS"
	replace wbregion = "Sub-Saharan Africa" 		if country=="SSA"
	
	drop if country=="CAE"
	* Special aggregations for the case of ECA
	replace wbcountry_name = " Regional Aggregate: Europe and Central Asia" if country=="CAT"
	replace wbcountry_name = "    Sub-region: European Union and Western Balkans" if country=="WEU"
	replace wbcountry_name = "    Sub-region: Western Europe" if country=="EUW"
	replace wbcountry_name = "    Sub-region: Southern Europe" if country=="EUS"
	replace wbcountry_name = "    Sub-region: Central Europe" if country=="EHC"
	replace wbcountry_name = "    Sub-region: Northern Europe" if country=="NTE"
	replace wbcountry_name = "    Sub-region: Western Balkans" if country=="WBK"
	replace wbcountry_name = "    Sub-region: Eastern Europe and Central Asia" if country=="CAE"
	replace wbcountry_name = "    Sub-region: South Caucasus" if country=="SCC"
	replace wbcountry_name = "    Sub-region: Central Asia" if country=="CAC"
	replace wbcountry_name = "    Sub-region: Other Eastern Europe" if country=="EUO"
	
	* Special country names
	replace wbcountry_name = "Kosovo" if country=="KSV"
	
	egen countryid = group(country)
	
	/*
	gen ecakeep = . 
	foreach cty in ALB ARM AZE BLR BIH BGR HRV GEO KAZ KSV KGZ LVA MKD MDA MNE	///
	               POL ROM RUS SRB TJK TUR TKM UKR UZB ///
				   /*CAT WEU EUW EUS EHC NTE WBK CAE SCC CAC EUO*/ {
		di "`cty'"
		replace ecakeep = 1 if country=="`cty'"
		di ""
	}
	
	keep if ecakeep == 1
	drop ecakeep
	*/
	gen saskeep = . 
	foreach cty in AFG BGD BTN IND LKA MDV NPL PAK {
		di "`cty'"
		replace saskeep = 1 if country=="`cty'"
		di ""
	}
	
	gen mnemonickeep = . 
	foreach mne in CAB_ CPIZ DEBT_ DEFICIT_ FDI_ GAP_ GDPZ CONZ AGRFC INDFC SRVFC INVZ GOVZ EXPZ IMPZ TFPZ ///
	               R_CON R_AGRFC R_INDFC R_SRVFC R_INVZ R_GOVZ LABZ C_LABZ C_TFPZ R_EXPZ R_IMPZ REER PANUSATLS CPIZ TAXFC R_TAXFC {
		di "`mne'"
		replace mnemonickeep = 1 if mnemonic=="`mne'"
		di ""
	}
	
	keep if mnemonickeep == 1
	drop mnemonickeep 
	
	* Colors
	gen color = . 
	/*
	gen region = 0
	foreach cty in EUW EUS EHC NTE SSC CAC CAE WEU CAT {
		replace region = 1 if country=="`cty'"
	}

	levelsof country if region==0, local(ctystocolor)

	local c = 1
	foreach cty of local ctystocolor {
		replace color = `c' if country=="`cty'" 
		local c = `c' + 1
		if `c' == 8 local c = 1
	}
	
	replace color = 8 if region==1
	drop region
	drop if year<2005
	*/
	drop category 
	keep if saskeep==1
	drop saskeep
	drop type
	drop ml
	egen indicatorid = group(mnemonic)
	replace subtitle = subinstr(subtitle,"(","",2)
	replace subtitle = subinstr(subtitle,")","",2)
		
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
	
	/*
	if mnemonic=="CAB_" ///	Current account balance (percentage share of nominal GDP)
	if mnemonic=="CONZ" ///	Private consumption growth (constant 2010 LCU, percentae change)
	if mnemonic=="CPIZ" ///	Inflation (consumer price index 2000 = 100, percentage change)
	if mnemonic=="C_LABZ" ///	Labor force (contribution, percentage points %p)
	if mnemonic=="C_TFPZ" ///	Total factor productiity (contribution, percentage points %p)
	if mnemonic=="DEBT_" ///	General government gross debt (% of nominal GDP)
	if mnemonic=="DEFICIT_" ///	General government balance (% of nominal GDP)
	if mnemonic=="EXPZ" ///	Exports growth (constant 2010 LCU, percentage change)
	if mnemonic=="FDI_" ///	Foreign direct investment balance (percentage share of nominal GDP)
	if mnemonic=="GAP_" ///	Output gap (percentage of potential output)
	if mnemonic=="GDPZ" ///	GDP growth (constant 2010 LCU, percentage change)
	if mnemonic=="GOVZ" ///	Government consumption growth (constant 2010 LCU, percentage change)
	if mnemonic=="IMPZ" ///	Imports growth (constant 2010 LCU, percentage change)
	if mnemonic=="INVZ" ///	Fixed investment growth (constant 2010 LCU, percentage change)
	if mnemonic=="LABZ" ///	Labor force growth (percentae change %)
	if mnemonic=="PANUSATLS" ///	Nominal exchange rate (local currency per USD)
	if mnemonic=="REER" ///	Real effective exchange rate (2010 = 100)
	if mnemonic=="R_CON" ///	Private consumption growth (percentage share of real GDP)
	if mnemonic=="R_EXPZ" ///	Exports growth (percentage share of real GDP)
	if mnemonic=="R_IMPZ" ///	Imports growth (percentage share of real GDP)
	if mnemonic=="R_TAXFC" ///	Taxes (percentage share of real GDP at factor cost)
	if mnemonic=="TAXFC" ///	Taxes growth (constant 2010 LCU, percentage change)
	if mnemonic=="TFPZ" ///	Total factor productivity growth (percentage change %)
	*/
	
	
	
}


********************************************************************************
* Appendix: List of variables used for Consistency Check 
********************************************************************************

***** CONSISTENCY CHECK *****

* GDP growth (constant 2010 LCU, percentage change)
* Inflation
* Output gap (percentage of potential output)
* Current account balance (percentage share of nominal GDP)
* General government balance (% of nominal GDP)
* General government gross debt (% of nominal GDP)


***** EXPENDITURE COMPONENTS *****

* GDP growth (constant 2010 LCU, percentage change)
* Private consumption growth (constant 2010 LCU, percentae change)
* Government consumption growth (constant 2010 LCU, percentage change)
* Fixed investment growth (constant 2010 LCU, percentage change)
* Exports growth (constant 2010 LCU, percentage change)
* Imports growth (constant 2010 LCU, percentage change)


***** EXPENDITURE SHARES TO GDP *****

* GDP growth (constant 2010 LCU, percentage change)
* Private consumption growth (percentage share of real GDP)
* Government consumption growth (percentage share of real GDP)
* Fixed investment growth (percentage share of real GDP)
* Fixed investment (percentage share of real GDP)
* Exports growth (percentage share of real GDP)
* Imports growth (percentage share of real GDP)
* Statistical discrepancy (percentage share of real GDP)


***** EXPENDITURE PRICES *****

* CPI inflation (2010 = 100, percentage change)
* GDP deflator (baseyear = 2010, percentage change)
* Private consumption deflator (baseyear = 2010, percentage change)
* Exports deflator (baseyear = 2010, percentage change)
* Government consumption deflator (baseyear = 2010, percentage change)
* Fixed investment deflator (baseyear = 2010, percentage change)
* Imports deflator (baseyear = 2010, percentage change)


***** SECTORAL PRODUCTION *****

* GDP at factor cost growth (constant 2010 LCU, percentage change)
* Taxes growth (constant 2010 LCU, percentage change)
* Agricultural growth (constant 2010 LCU, percentage change)
* Industry growth (constant 2010 LCU, percentage change)
* Services growth (constant 2010 LCU, percentage change)


***** SECTORAL SHARES *****

* GDP, market prices vs factor costs (growth, annual percentage change)
* GDP at factor costs growth (constant 2010 LCU, percentage change)
* Taxes (percentage share of real GDP at factor cost)
* Agriculture (percentage share of real GDP at factor cost)
* Industry (percentage share of real GDP at factor cost)
* Services (percentage share of real GDP at factor cost)


***** SECTORAL PRICES *****

* CPI inflation (2010 = 100, percentage change)
* GDP at factor cost deflator (baseyear = 2010, percentage change)
* Tax deflator (baseyear = 2010, percentage change)
* Agriculture deflator (baseyear = 2010, percentage change)
* Industry deflator (baseyear = 2010 percentage change)
* Services deflator (baseyear = 2010, percentage change)


***** POTENTIAL GDP *****

* Labor force growth (percentae change %)
* Total factor productivity growth (percentage change %)
* Capital stock growth (percentage change %)
* Potential GDP growth (constant 2010 LCU, percentage change)


***** POTENTIAL GDP growth decomposition *****

* Labor force (contribution, percentage points %p)
* Total factor productiity (contribution, percentage points %p)
* Capital stock (contribution, percentage points %p)
* Potential GDP growth (constant 2010 LCU, percentage change)


***** CURRENT ACCOUNT BALANCE / CAPITAL FLOWS *****

* Current account balance (percentage share of nominal GDP)
* Capital and financial account balance (percentage share of nominal GDP)
* Financial account balance, excl. R.A. (percentage share of nominal GDP)
* Reserve asset changes (R.A.) (percentage share of nominal GDP)
* Net errors and omissions (percentage share of nominal GDP)
* Capital account balance (percentage share of nominal GDP)
* Financial account balance (percentage share of nominal GDP)
* Foreign direct investment balance (percentage share of nominal GDP)
* Portfolio investment balance, equity (percentage share of nominal GDP)
* Portfolio investment balance, debt (percentae share of nominal GDP)
* Other investment balance (percentage share of nominal GDP)


***** EXTERNAL CONDITIONS *****

* Export market (percentage change %)
* Nominal exchange rate (local currency per USD)
* Nominal effective exchange rate (2010 = 100)
* Real effective exchange rate (2010 = 100)

/********************************************************************************
* Appendix II. Categories used for Consitency checks
********************************************************************************

***** CONSISTENCY CHECK *****
preserve
replace category = "Consistency check" if varlabel=="Potential Output Growth (constant 2010 U.S. dollars)"
replace category = "Consistency check" if varlabel=="GDP growth (constant 2010 LCU, percentage change)"
replace category = "Consistency check" if varlabel=="Inflation (consumer price index 2000 = 100, percentage change)"
replace category = "Consistency check" if varlabel=="Output gap (percentage of potential output)"
replace category = "Consistency check" if varlabel=="Current account balance (percentage share of nominal GDP)"
replace category = "Consistency check" if varlabel=="General government balance (% of nominal GDP)"
replace category = "Consistency check" if varlabel=="General government gross debt (% of nominal GDP)"
keep if category!=""
	tempfile out
	save `out', replace
restore

***** EXPENDITURE COMPONENTS *****
preserve
replace category = "Expenditure components" if varlabel=="GDP growth (constant 2010 LCU, percentage change)"
replace category = "Expenditure components" if varlabel=="Private consumption growth (constant 2010 LCU, percentae change)"
replace category = "Expenditure components" if varlabel=="Government consumption growth (constant 2010 LCU, percentage change)"
replace category = "Expenditure components" if varlabel=="Fixed investment growth (constant 2010 LCU, percentage change)"
replace category = "Expenditure components" if varlabel=="Exports growth (constant 2010 LCU, percentage change)"
replace category = "Expenditure components" if varlabel=="Imports growth (constant 2010 LCU, percentage change)"
keep if category!=""
	append using `out'
	save `out', replace
restore

***** EXPENDITURE SHARES TO GDP *****
preserve
replace category = "Expenditure shares to GDP" if varlabel=="GDP growth (constant 2010 LCU, percentage change)"
replace category = "Expenditure shares to GDP" if varlabel=="Private consumption growth (percentage share of real GDP)"
replace category = "Expenditure shares to GDP" if varlabel=="Government consumption growth (percentage share of real GDP)"
replace category = "Expenditure shares to GDP" if varlabel=="Fixed investment growth (percentage share of real GDP)"
replace category = "Expenditure shares to GDP" if varlabel=="Fixed investment (percentage share of real GDP)"
replace category = "Expenditure shares to GDP" if varlabel=="Exports growth (percentage share of real GDP)"
replace category = "Expenditure shares to GDP" if varlabel=="Imports growth (percentage share of real GDP)"
replace category = "Expenditure shares to GDP" if varlabel=="Statistical discrepancy (percentage share of real GDP)"
keep if category!=""
	append using `out'
	save `out', replace
restore

***** EXPENDITURE PRICES *****
preserve
replace category = "Expenditure prices" if varlabel=="CPI inflation (2010 = 100, percentage change)"
replace category = "Expenditure prices" if varlabel=="GDP deflator (baseyear = 2010, percentage change)"
replace category = "Expenditure prices" if varlabel=="Private consumption deflator (baseyear = 2010, percentage change)"
replace category = "Expenditure prices" if varlabel=="Exports deflator (baseyear = 2010, percentage change)"
replace category = "Expenditure prices" if varlabel=="Government consumption deflator (baseyear = 2010, percentage change)"
replace category = "Expenditure prices" if varlabel=="Fixed investment deflator (baseyear = 2010, percentage change)"
replace category = "Expenditure prices" if varlabel=="Imports deflator (baseyear = 2010, percentage change)"
keep if category!=""
	append using `out'
	save `out', replace
restore

***** SECTORAL PRODUCTION *****
preserve
replace category = "Sectoral production" if varlabel=="GDP at factor cost growth (constant 2010 LCU, percentage change)"
replace category = "Sectoral production" if varlabel=="Taxes growth (constant 2010 LCU, percentage change)"
replace category = "Sectoral production" if varlabel=="Agricultural growth (constant 2010 LCU, percentage change)"
replace category = "Sectoral production" if varlabel=="Industry growth (constant 2010 LCU, percentage change)"
replace category = "Sectoral production" if varlabel=="Services growth (constant 2010 LCU, percentage change)"
keep if category!=""
	append using `out'
	save `out', replace
restore

***** SECTORAL SHARES *****
preserve
replace category = "Sectoral shares" if varlabel=="GDP, market prices vs factor costs (growth, annual percentage change)"
replace category = "Sectoral shares" if varlabel=="GDP at factor costs growth (constant 2010 LCU, percentage change)"
replace category = "Sectoral shares" if varlabel=="Taxes (percentage share of real GDP at factor cost)"
replace category = "Sectoral shares" if varlabel=="Agriculture (percentage share of real GDP at factor cost)"
replace category = "Sectoral shares" if varlabel=="Industry (percentage share of real GDP at factor cost)"
replace category = "Sectoral shares" if varlabel=="Services (percentage share of real GDP at factor cost)"
keep if category!=""
	append using `out'
	save `out', replace
restore

***** SECTORAL PRICES *****
preserve
replace category = "Sectoral prices" if varlabel=="CPI inflation (2010 = 100, percentage change)"
replace category = "Sectoral prices" if varlabel=="GDP at factor cost deflator (baseyear = 2010, percentage change)"
replace category = "Sectoral prices" if varlabel=="Tax deflator (baseyear = 2010, percentage change)"
replace category = "Sectoral prices" if varlabel=="Agriculture deflator (baseyear = 2010, percentage change)"
replace category = "Sectoral prices" if varlabel=="Industry deflator (baseyear = 2010 percentage change)"
replace category = "Sectoral prices" if varlabel=="Services deflator (baseyear = 2010, percentage change)"
keep if category!=""
	append using `out'
	save `out', replace
restore

***** POTENTIAL GDP *****
preserve
replace category = "Potential GDP" if varlabel=="Labor force growth (percentae change %)"
replace category = "Potential GDP" if varlabel=="Total factor productivity growth (percentage change %)"
replace category = "Potential GDP" if varlabel=="Capital stock growth (percentage change %)"
replace category = "Potential GDP" if varlabel=="Potential GDP growth (constant 2010 LCU, percentage change)"
keep if category!=""
	append using `out'
	save `out', replace
restore

***** POTENTIAL GDP growth decomposition *****
preserve
replace category = "Potential GDP growth decomposition" if varlabel=="Labor force (contribution, percentage points %p)"
replace category = "Potential GDP growth decomposition" if varlabel=="Total factor productiity (contribution, percentage points %p)"
replace category = "Potential GDP growth decomposition" if varlabel=="Capital stock (contribution, percentage points %p)"
replace category = "Potential GDP growth decomposition" if varlabel=="Potential GDP growth (constant 2010 LCU, percentage change)"
keep if category!=""
	append using `out'
	save `out', replace
restore

***** CURRENT ACCOUNT BALANCE / CAPITAL FLOWS *****
preserve
replace category = "Current account balance / capital flows" if varlabel=="Current account balance (percentage share of nominal GDP)"
replace category = "Current account balance / capital flows" if varlabel=="Capital and financial account balance (percentage share of nominal GDP)"
replace category = "Current account balance / capital flows" if varlabel=="Financial account balance, excl. R.A. (percentage share of nominal GDP)"
replace category = "Current account balance / capital flows" if varlabel=="Reserve asset changes (R.A.) (percentage share of nominal GDP)"
replace category = "Current account balance / capital flows" if varlabel=="Net errors and omissions (percentage share of nominal GDP)"
replace category = "Current account balance / capital flows" if varlabel=="Capital account balance (percentage share of nominal GDP)"
replace category = "Current account balance / capital flows" if varlabel=="Financial account balance (percentage share of nominal GDP)"
replace category = "Current account balance / capital flows" if varlabel=="Foreign direct investment balance (percentage share of nominal GDP)"
replace category = "Current account balance / capital flows" if varlabel=="Portfolio investment balance, equity (percentage share of nominal GDP)"
replace category = "Current account balance / capital flows" if varlabel=="Portfolio investment balance, debt (percentae share of nominal GDP)"
replace category = "Current account balance / capital flows" if varlabel=="Other investment balance (percentage share of nominal GDP)"
keep if category!=""
	append using `out'
	save `out', replace
restore

***** EXTERNAL CONDITIONS *****
preserve
replace category = "External conditions" if varlabel=="Export market (percentage change %)"
replace category = "External conditions" if varlabel=="Nominal exchange rate (local currency per USD)"
replace category = "External conditions" if varlabel=="Nominal effective exchange rate (2010 = 100)"
replace category = "External conditions" if varlabel=="Real effective exchange rate (2010 = 100)"	
keep if category!=""
	append using `out'
	save `out', replace
restore

	use `out', clear
*/











