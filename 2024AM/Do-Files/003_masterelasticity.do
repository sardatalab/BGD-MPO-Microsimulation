*!v1.0
/*========================================================================
Project:			Inputs for Microsimulation Tool
Institution:		World Bank

Author:				Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Creation Date:		07/25/2022

Last Modification:	Israel Osorio-Rodarte (iosoriorodarte@worldbank.org)
Modification date: 	07/29/2024
========================================================================*/

*drop _all

**************************************************************************
* 	0 - SETTING
**************************************************************************

* Globals
*global rootdatalib 	"S:/Datalib"
*global path 			"Z:/public/Stats_Team/PLBs/23. Poverty projections simulations/New estimates informality new"
*global dofiles 		"$path/dofiles/tool"

*global path_mpo 	"Z:/public/Stats_Team/PLBs/23. Poverty projections simulations/LAC_Inputs_Regional_Microsims/FY2024/01_Microsims_AM2023/_inputs"
*global path_share 	"C:/Users/wb599516/WBG/Knowledge ELCPV - WB Group - LAC_Inputs_Regional_Microsims/FY2024/01_Microsims_AM2023/_inputs" // sharepoint

*global data 		"Z:/public/Stats_Team/PLBs/23. Poverty projections simulations/LAC_Inputs_Regional_Microsims/definitive_historic_versions" // microsimulated data

*global input_sedlac "input_elasticities_sedlac.dta" // SEDLAC Input file for elasticities
*global input_lablac "input_elasticities_lablac.dta" // LABLAC Input file for elasticities
*global outfile 		"input_MASTER.xlsx"

*global version "Jul-29-2024"

*************************************************************
* Set up list of countries with income/expenditure surveys
* Set up minimum and maximum years
*************************************************************
global countries_hies 	  "BGD"
global init_year_hies 	= 2022
global end_year_hies 	= 2022


*************************************************************
* Set up list of countries with income/expenditure surveys
* Set up minimum and maximum years
*************************************************************
local  countries_lfs   "BGD" 
global init_year_lfs = 2015
global end_year_lfs  = 2022
local quarters "q01 q02 q03 q04"


* Set up Elasticities
************************
* Countries to include and their RESPECTIVE year restriction
gl countries 	"BGD" 
gl min_year 	"2010" // Long series
gl min_year2 	"2016" // Middle series
gl min_year3 	"2016" // Short Series
gl last_year 	"2022" // Last year



*************************************************************************
* 	1 - RUN DO FILES
*************************************************************************

* 1. inputs using HIES				  
	do "$dofiles/004_inputs_hies.do"

* 2. inputs using LFS
	*do "$dofiles/005_inputs_lfs.do"
		
* 4. elasticities
	*do "$dofiles/006_elasticities.do"
	
	
*************************************************************************
*	- END
*************************************************************************
