*!v1.0
/*========================================================================
Project:			Inputs for Microsimulation Tool
Institution:		World Bank

Author:				Kelly Y. Montoya (kmontoyamunoz@worldbank.org)
Creation Date:		07/25/2022

Last Modification:	Israel Osorio-Rodarte (iosoriorodarte@worldbank.org)
Modification date: 	07/29/2024
========================================================================*/

drop _all

**************************************************************************
* 	0 - SETTING
**************************************************************************

* Globals
global rootdatalib "S:/Datalib"
global path "Z:/public/Stats_Team/PLBs/23. Poverty projections simulations/New estimates informality new"
global dofiles "$path/dofiles/tool"

global path_mpo "Z:/public/Stats_Team/PLBs/23. Poverty projections simulations/LAC_Inputs_Regional_Microsims/FY2024/01_Microsims_AM2023/_inputs"
global path_share "C:/Users/wb599516/WBG/Knowledge ELCPV - WB Group - LAC_Inputs_Regional_Microsims/FY2024/01_Microsims_AM2023/_inputs" // sharepoint
global povmod "//wurepliprdfs01/gpvfile/gpv/Knowledge_Learning/Pov Projection/Central Team/MFM-allvintages.dta"
global data "Z:/public/Stats_Team/PLBs/23. Poverty projections simulations/LAC_Inputs_Regional_Microsims/definitive_historic_versions" // microsimulated data

global input_sedlac "input_elasticities_sedlac.dta" // SEDLAC Input file for elasticities
global input_lablac "input_elasticities_lablac.dta" // LABLAC Input file for elasticities
global outfile "input_MASTER.xlsx"

global version "Jul-29-2024"

cd "$path"

*************************************************************
* Set up list of countries with income/expenditure surveys
* Set up minimum and maximum years
*************************************************************
global countries_heis 	"BGD"
global init_year_heis 	= 2000
global end_year_heis 	= 2022


*************************************************************
* Set up list of countries with income/expenditure surveys
* Set up minimum and maximum years
*************************************************************
local countries_lablac "ARG CHL COL ECU GTM MEX NIC SLV URY" 
*local countries_lablac "ARG BRA CHL COL CRI ECU GTM MEX NIC PER PRY SLV URY" 
gl init_year_lablac = 2014
gl end_year_lablac = 2023
local quarters "q01 q02 q03 q04"
/* Observations (also in lablac dofile)
ARG 2016q02 is in ppp05
BRA doesn´t have the variables to construct informality
CHL only has labor income for q04
COL 2022 doesn´t have income
CRI doesn´t have variables for sector
MEX 2020q03 needs revision.
PER doesn´t have djubila
PRY doesn´t have sector 
*/


* Set up Elasticities
************************
* Countries to include and their RESPECTIVE year restriction
* NOTE: We need to include PAN later.
gl countries 	"ARG  BOL  BRA  CHL  COL  CRI  DOM  ECU  GTM  HND  MEX  PER  PRY  SLV  URY  PAN" 
gl min_year 	"2006 2007 2006 2006 2008 2006 2006 2006 2006 2006 2006 2006 2006 2006 2006 2006" // Long series
gl min_year2 	"2011 2011 2011 2011 2011 2011 2011 2011 2010 2011 2010 2011 2011 2011 2011 2011" // Middle series
gl min_year3 	"2015 2015 2015 2015 2015 2015 2015 2015 2015 2015 2015 2015 2015 2015 2015 2015" // Short Series
gl last_year 	"2019 2019 2019 2017 2019 2019 2019 2019 2019 2019 2018 2019 2019 2019 2019 2019" // Last year
*gl last_year2 	"2022 2021 2021 2021 2021 2021 2021 2022 2021 2019 2022 2021 2021 2021 2021 2021"


*************************************************************************
* 	1 - RUN DO FILES
*************************************************************************

* 1. inputs using SEDLAC
	run "$dofiles/01_inputs_sedlac"
	
* 2. inputs using LABLAC
	run "$dofiles/02_inputs_lablac"
	
* 3. inputs using Microsimulated data
	run "$dofiles/03_inputs_microsims"
	
* 4. elasticities
	run "$dofiles/04_elasticities"
	
* 5. GDP and Population
	run "$dofiles/05_inputs_macro" // This one is Cicero's old do with Rodrigo's improvements
	
	
*************************************************************************
*	- END
*************************************************************************