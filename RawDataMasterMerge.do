/*
Filename: RawDataMasterMerge.do
Author: Anthony D'Agostino (ald2187 -at - columbia -dot- edu)
Date Created: 03/29/2017
Last Edited: 03/29/2017
Purpose: Tutorial example of how Stata can easily merge thousands of raw data files from an unspecified path architecture


*/



clear
clear all
clear matrix 
set more off
set mem 10000m 
set matsize 5000
set scheme s2mono 
set graphics on

**********************************
* What is your local Dropbox path?
**********************************

	
	* identify parent directory of RCP85 folder * 
	loc parentDir ""  // replace with your root directory that contains the unzipped RCP85 contents
	
	* create folder for outputs * 
	loc outDir "`parentDir'/Output"
		cap mkdir "`outDir'" 
	
	loc rcp85dir "`parentDir'/RCP85"
	
	* first search through to get directory structure * 
	ashell find "`rcp85dir'" -maxdepth 1 -mindepth 1 -type d
		forvalues j = 1/`r(no)' { 
			loc currentDir "`r(o`j')'"
			di "Current Dir = `currentDir'" 
	
							
		* then recover files from each model family * 	
		ashell find "`currentDir'" -maxdepth 1 -name "*.csv" 	
			forval i = 1/`r(no)' { 
			
				di "`i'"
				di "r(o`i')"
				insheet using "`r(o`i')'", comma clear
				loc fn = "`r(o`i')'"
								
						di "`fn'"		
								
				* Recover basics from filename, presumably more accurate than if sourced from directory name *  
					gen polynomialOrder = regexs(2) if regexm("`fn'", "(Power_)([0-9])(.csv)")
					gen modelFamily = regexs(2) if regexm("`fn'", "(r1i1p1_)([a-zA-Z0-9-]*)(_2050)")
					gen experiment = regexs(2) if regexm("`fn'", "(BCSD_)([a-zA-Z0-9-]*)(_r1)")				
					
					
					levelsof modelFamily, loc(mf) clean 
					gen dateFixed = regexs(2) if regexm("`fn'", "(`mf'_)([0-9-]*)(_1991District)" )
					
						gen year = regexs(1) if regexm(dateFixed, "([0-9][0-9][0-9][0-9])(-)")
						gen month = regexs(2) if regexm(dateFixed, "(-)([0-9][0-9])(-)")
						gen day = regexs(4) if regexm(dateFixed, "(-)([0-9][0-9])(-)([0-9][0-9])")
					
					destring, replace
					
					gen date = mdy(month, day, year) 
						format date %td 
					
					
					levelsof polynomialOrder, loc(degr) clean 
					
					ren mean mean_`degr' 
						keep dist_code mean_`degr' modelFamily experiment date 
					
						tempfile temp`i'
						save `temp`i'' 
						di "Just finished saving file `i'" 
						
					ashell find "`currentDir'" -maxdepth 1 -name "*.csv" 
					} 
				

					use `temp1', clear 
					
						forval j = 2/`r(no)' { 
							merge 1:1 dist_code date modelFamily experiment using `temp`j'', update replace
								tab _merge
								drop _merge 
						}
				
				
					levelsof modelFamily, loc(mf) clean
					levelsof experiment, loc(expe) clean
					
					
					* Save each model-family x experiment as a separate file *
					saveold "`outDir'/`mf'_`expe'_1991DistProcessed.dta", replace 				
			
	ashell find "`rcp85dir'" -maxdepth 1 -mindepth 1 -type d
	
			} // end of j loop  

			
			
