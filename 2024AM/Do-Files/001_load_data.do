*!v1.1 July 24, 2024
*===============================================================================
* Microsimulation load data
* Based on each simulation year, this program loads and save the base household
* survey data. It loads the labor (LBR), income (INC), individual (IND), and
* "IMP" modules.
*===============================================================================
{
	*===========================================================================
	* Save global with household survey to use
	*===========================================================================
	local allyears = $baseyear

	*===========================================================================
	* Bring CPI
	*===========================================================================
	
	local code="$country"
	local year0=$baseyear
	local cpiversion="09"	
	
	* Make DLW directory
	cap mkdir "$data_in/DLW"
	
	* Download CPI from datalibweb, in Windows
	if "`c(os)'"=="Windows" {
		if "$reload_dlw"=="yes" {
			cap datalibweb, country(Support) year(2005) type(GMDRAW) surveyid(Support_2005_CPI_v`cpiversion'_M) filename(Final_CPI_PPP_to_be_used.dta)
			if _rc {
				noi di ""
				noi di as error "Note: Downloading data from datalibweb failed. Verify connection"
				exit
			}
			else save "$data_in/DLW/datalib_support_2005_GMDRAW.dta", replace
		}
		if "$reload_dlw"=="" {
			cap use "$data_in/DLW/datalib_support_2005_GMDRAW.dta", clear
			if _rc {
				noi di as error "CPI data not found. Download it using datalibweb in Windows"
				exit
			}	
		}
	}
	
	* Read CPI in MacOSX
	if (c(os)=="MacOSX"|c(os)=="Unix") {
		noi di ""
		noi di as text `"Note: MacOSX/Unix, datalibweb skipped. CPI data should exist alreay in the "$data_in/DLW" folder"'
		
		cap use "$data_in/DLW/datalib_support_2005_GMDRAW.dta", clear
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
	
	
	
	* Year: 2022
	if `year'==2022 {
		
		if c(os)=="Windows" {
		
		if "$reload_dlw"=="yes" {
			foreach module in LBR INC IND GMD {
				cap datalibweb, country(BGD) year(2022) type(SARMD) vermast(02) veralt(03) survey(HIES) module(`module') clear
				if _rc {
					noi di as text "Note: file not found in datalibweb"
					exit
				}
			
				else {
					save "$data_in/DLW/`r(filename)'", replace
					noi di "`r(filename)'"
					global `module' "$data_in/DLW/`r(filename)'"
				}
			}
		}
		
		if "$reload_dlw"=="" {
			noi di ""
			noi di as text "Windows, datalibweb skipped"
			foreach module in LBR INC IND GMD {
				global `module' "$data_in/DLW/BGD_2022_HIES_v02_M_v03_A_SARMD_`module'.dta"
			}
		}
		
		}
		
		if (c(os)=="MacOSX"|c(os)=="Unix") {
			noi di ""
			noi di as text "MacOSX, datalibweb skipped"
			foreach module in LBR INC IND {	
				global `module' "$data_in/DLW/BGD_2022_HIES_v02_M_v03_A_SARMD_`module'.dta"
			}
		}
	}
	
	* Year: 2016 (legacy)
	if `year'==2016 {
		global LBR "C:/Users/wb553773/OneDrive - WBG/BD/BGD Poverty Assessment 2023/Data/HIES 2016/BGD_2016_HIES_v01_M_v06_A_SARMD_LBR"
		global INC "C:/Users/wb553773/OneDrive - WBG/BD/BGD Poverty Assessment 2023/Data/HIES 2016/BGD_2016_HIES_v01_M_v06_A_SARMD_INC"
		global IND "C:/Users/wb553773/OneDrive - WBG/BD/BGD Poverty Assessment 2023/Data/HIES 2016/BGD_2016_HIES_v01_M_v06_A_SARMD_IND"
	}
	
	* Year: 2010 (legacy)
	if `year'==2010 {
		global LBR "C:/Users/wb553773/OneDrive - WBG/BD/BGD Poverty Assessment 2023/Data/HIES 2010/BGD_2010_HIES_v01_M_v07_A_SARMD_LBR"
		global INC "C:/Users/wb553773/OneDrive - WBG/BD/BGD Poverty Assessment 2023/Data/HIES 2010/BGD_2010_HIES_v01_M_v07_A_SARMD_INC"
		global IND "C:/Users/wb553773/OneDrive - WBG/BD/BGD Poverty Assessment 2023/Data/HIES 2010/BGD_2010_HIES_v01_M_v07_A_SARMD_IND"
	}

	*===========================================================================
	* Load modules and merge modules
	*===========================================================================
	use "$LBR", clear

	keep pid industrycat10_year industrycat10_2_year ocusec_year ocusec_2_year occup_year occup_2_year empstat_year empstat_2_year lstatus_year

	tempfile labor

	save `labor'

	use "$INC", clear

	keep pid ip ila inla ii ipcf inp ijubi itranp itrane icap inla_otro renta_imp itf

	tempfile income

	save `income'

	use "$IND", clear

	merge m:1 pid using `income', nogen

	merge m:1 pid using `labor'

	drop if _merge==2
	drop _merge

	* Rename labels
	cap lab def industrycat10_year 1 "Agriculture, Hunting, Fishing, etc." 2 "Mining" 3 "Manufacturing"  4 "Public Utility Services"  5 "Construction"  6 "Commerce" 7 "Transport and Communications" 8 "Financial and Business Services"  9 "Public Administration"  10 "Others Services, Unspecified", replace
	cap lab val industrycat10_year industrycat10_year

	cap lab def industrycat10_2_year 1 "Agriculture, Hunting, Fishing, etc." 2 "Mining" 3 "Manufacturing"  4 "Public Utility Services"  5 "Construction"  6 "Commerce" 7 "Transport and Communications" 8 "Financial and Business Services"  9 "Public Administration"  10 "Others Services, Unspecified", replace
	cap lab val industrycat10_2_year industrycat10_2_year

	cap lab def ocusec_year 1 "Public sector, Central Government, Army" 2 "Private, NGO" 3 "State owned" 4 "Public or State-owned, but cannot distinguish", replace
	cap lab val ocusec_year ocusec_year

	cap lab def ocusec_2_year 1 "Public sector, Central Government, Army" 2 "Private, NGO" 3 "State owned" 4 "Public or State-owned, but cannot distinguish", replace
	cap lab val ocusec_2_year ocusec_2_year

	cap lab def occup_year 1 "Managers"  2  "Professionals"  3  "Technicians and associate professionals"  4  "Clerical support workers"  5 "Service and sales workers" 6 "Skilled agricultural, forestry and fishery workers" 7  "Craft and related trades workers" 8  "Plant and machine operators, and assemblers" 9 "Elementary occupations" 10  "Armed forces occupations" 99 "Other/unspecified", replace
	cap lab val occup_year occup_year

	cap lab def occup_2_year 1 "Managers"  2  "Professionals"  3  "Technicians and associate professionals"  4  "Clerical support workers"  5 "Service and sales workers" 6 "Skilled agricultural, forestry and fishery workers" 7  "Craft and related trades workers" 8  "Plant and machine operators, and assemblers" 9 "Elementary occupations" 10  "Armed forces occupations" 99 "Other/unspecified", replace
	cap lab val occup_2_year occup_2_year

	cap lab def empstat_year 1 "Paid Employee"  2 "Non-Paid Employee"  3 "Employer"  4 "Self-employed" 5 "Other, workers not classifiable by status", replace
	cap lab val empstat_year empstat_year

	cap lab def empstat_2_year 1 "Paid Employee"  2 "Non-Paid Employee"  3 "Employer"  4 "Self-employed" 5 "Other, workers not classifiable by status", replace
	cap lab val empstat_2_year empstat_2_year

	cap lab def lstatus_year 1 "Employed"  2 "Unemployed"  3 "Not in labor force", replace
	cap lab val lstatus_year lstatus_year

	cap lab def lstatus 1 "Employed"  2 "Unemployed"  3 "Not in labor force", replace
	cap lab val lstatus lstatus

	* Recode industry variable to match macro aggregation
	clonevar industry6=industrycat10_year
	recode industry6 (3=2) (4=2) (5=3) (6=4) (7=5) (8=6) (9=4) (10=4)
	cap lab def industry6 1 "Agriculture" 2 "Industry" 3 "Construction"  4 "Services" 5 "Transport" 6 "Finance", replace
	cap lab val industry6 industry6

	clonevar industry6_2=industrycat10_2_year
	recode industry6_2 (3=2) (4=2) (5=3) (6=4) (7=5) (8=6) (9=4) (10=4)
	cap lab def industry6_2 1 "Agriculture" 2 "Industry" 3 "Construction"  4 "Services" 5 "Transport" 6 "Finance", replace
	cap lab val industry6_2 industry6_2

	* Incorporate IMP module (legacy)
	if `year'==2016 {
		destring idh, replace
		clonevar hhold=idh
		merge m:1 hhold using "C:/Users/wb553773/OneDrive - WBG/BD/BGD Poverty Assessment 2023/Data/HIES 2016/BGD_2016_HIES_v01_M_v06_A_SARMD_IND_imp", keepusing(index)
	}

	* Incorporate IMP module (legacy)
	if `year'==2010 {
		destring idh, replace
		clonevar hhold=idh
		merge m:1 hhold using "C:/Users/wb553773/OneDrive - WBG/BD/BGD Poverty Assessment 2023/Data/HIES 2010/BGD_2010_HIES_v01_M_v06_A_SARMD_IND_imp", keepusing(index10)
	}


	* Incorporate povextline (needs to be updated)
	if `year'==2022 & "`c(username)'"=="WB553773" {
		*merge with updated welfare (consumption)
		gen hhidseq = substr(hhid, strpos(hhid, "-") + 1, .)
		destring hhidseq , replace
		gen hhold = psu*1000+hhidseq
		merge m:1 hhold using "C:/Users/wb553773/OneDrive - WBG/BD/HIES2022/HIES2022_HH_08_16_23.dta", keepusing(p_cons2 zu_cbn zl_cbn domain16)
		*keep if _merge==3
		*drop _merge
		drop welfarenom
		rename p_cons2 welfarenom
		rename zl_cbn povextline
		rename zu_cbn povline
	}
	
	* Tabulations
	tab industry6 [iw=wgt]

	if `year'==2016 {
		replace ila = ila * index
		replace ip = ip*index
	}

	if `year'==2010 {
		replace ila = ila * index10
		replace ip = ip*index10
	}

	tabstat ila ip [aw=wgt], by(industry6)

	tab lstatus [iw=wgt]

	tab lstatus_year [iw=wgt]

	gen workage=0
	replace workage=1 if age>=15 & age<=64
	tab workage [iw=wgt]
	
	*===========================================================================
	* Merge CPI
	*===========================================================================		
	drop cpi2017
	merge m:1 countrycode year using `dlwcpi'
	keep if _merge==3
	drop _merge	
	
}
*===============================================================================
