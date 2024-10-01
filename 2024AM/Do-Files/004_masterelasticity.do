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
global init_year_hies 	= 2016
global end_year_hies 	= 2022


*************************************************************
* Set up list of countries with income/expenditure surveys
* Set up minimum and maximum years
*************************************************************
global countries_lfs   "BGD" 
global init_year_lfs = 2005
global end_year_lfs  = 2022
global quarters "q01"


* Set up Elasticities
************************
* Countries to include and their RESPECTIVE year restriction
gl countries 	"BGD" 
gl lfmin_year1 	"2005" // Long series
gl lfmin_year2 	"2010" // Middle series
gl lfmin_year3 	"2015" // Short Series
gl lflast_year 	"2022" // Last year

*gl hsmin_year1 	"2016" // Long series
*gl hsmin_year2 	"2016" // Middle series
gl hsmin_year3 	"2016" // Short Series
gl hslast_year 	"2022" // Last year



*************************************************************************
* 	1 - RUN DO FILES
*************************************************************************

* 1. inputs using HIES				  
	*do "$dofiles/005_inputs_hies.do"

* 2. inputs using LFS
	*do "$dofiles/006_inputs_lfs.do"
		
* 4. elasticities
	*do "$dofiles/007_elasticities.do"
	
	
*************************************************************************
*	- END
*************************************************************************
