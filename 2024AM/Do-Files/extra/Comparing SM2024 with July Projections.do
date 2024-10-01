*!v1.0
*===============================================================================
* Compare Baseline and July Projections
*===============================================================================
* Created on : August 22, 2024
* Last update: August 22, 2024
*===============================================================================
* Prepared by: South Asia Regional Stats Team

* Initiated by: Israel Osorio Rodarte
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
* RUNNING STEPS
*===============================================================================
{


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
	*cap mkdir "${path}/Data"
	gl data_root "${path}/Data"
	gl data_in   "${path}/Data/INPUT"
	gl data_out  "${path}/Data/OUTPUT"

}

*===============================================================================
* Step 1. Comparison
*===============================================================================

	cd "$data_in/Macro and elasticities"
	
	import excel using "GDP sectoral data projections - Poverty microsimulations", sheet("Constant price") firstrow clear
	drop if A==""
	
	encode A, gen(_ind)
	keep if inlist(_ind,2,5,9,13,19,21)
	/*
		2	Agriculture
		5	Construction
		
		9	Financial and Insurance activities
		13	Industry
		19	Services
		21	Transportation, Storage and Comunication
	*/	
	drop A
	reshape long FY, i(_ind) j(year)
	replace year = year+2000
	
	rename FY value
	reshape wide value, i(year) j(_ind) 
	
	gen double val1 = value2 // Agriculture
	gen double val2 = value5 // Construction
	gen double val3 = value13 - value5	// Rest of Industry
	gen double val4 = value21	// Transport
	gen double val5 = value9	// Finance
	gen double val6 = value19 - value21 - value9
	drop value*
	rename val* value*
	reshape long value, i(year) j(ind)
	
	#delimit ;
	label define lblind 1 "GDP Agriculture, constant LCU"
						2 "GDP Construction, constant LCU"
						3 "GDP Rest of industry, constant LCU"
						4 "GDP Transport, constant LCU"
						5 "GDP Finance, constant LCU"
						6 "GDP Rest of services, constant LCU";
	#delimit cr
	
	label values ind lblind
	decode ind, gen(title)
	
	gen indicator = ""
	replace indicator = "mfnvagrtotlkn"	if ind==1
	replace indicator = "mfnvindconskn" if ind==2
	replace indicator = "mfnvindrestkn" if ind==3
	replace indicator = "mfnvsrvtrnskn" if ind==4
	replace indicator = "mfnvsrvfinakn" if ind==5
	replace indicator = "mfnvsrvrestkn" if ind==6
	
	gen country = "BGD"
	
	gen date = "July 2024"
	
	order country year indicator value  title date ind
	keep  country year indicator value  title date ind
	
	save "mfmod_bgd_base.dta"
	
	append using "mfmod_bgd.dta"
	keep if year>=2024 & year<=2027
	
	gen _ind = ind
	bys country year indicator: egen _indm = median(_ind)
	replace ind = _indm if ind==. & _indm!=.
		drop _ind _indm
		drop if ind==.
	
	encode date, gen(numdate)
	drop date
	sort country year indicator title ind
	reshape wide value, i(country year indicator title ind) j(numdate)
	sort country year ind 
	drop if value1==.
	
	label var value1 "Value July 2024"
	label var value2 "Value SM 2024"
	
	gen double grvalue = 100*(value1/value2-1)
	label var grvalue "Growth, % change"
	format grvalue %2.1f
	
	label var ind "Industry, short"
	
	sort country indicator year

	#delimit ;
	label define lblindshort 1 "Agriculture"
						2 "Construction"
						3 "Rest of industry"
						4 "Transport"
						5 "Finance"
						6 "Rest of services";
	#delimit cr
	label values ind lblindshort
	
	sort country year ind
	export excel using "Forecast Check Comparison between SM24 and July 24", sheet("Comparison", modify) firstrow(varlabels)
	
	reshape long value , i(country year indicator title) j(date)
	
	replace value = value/10^6
	
	set scheme s2color
	graph bar value, over(ind) asyvar stack over(date) by(year, graphregion(color(white)) note("")) legend(size(small)) 	ytitle("billions, constant LCU")