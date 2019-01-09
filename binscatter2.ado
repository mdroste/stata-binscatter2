*===============================================================================
* Program: binscatter2.ado
* Purpose: New functionality and efficiency improvements for binscatter.
* Author:  Michael Droste
* Version: 0.1 (01/08/2019)
* Credits: This program was made possible due to the collective efforts of a 
*          handful of Stata superstars, among them:
*           - Michael Stepner, who wrote the original binscatter (with 
*             contributions from Jessica Laird).
*           - Sergio Correa, who developed ftools and proved that hash tables
*             could be used to speed up a number of Stata routines.
*           - Mauricio Caceres Bravo, who produced gtools, Correa's ftools in 
*             hyper-efficient compiled C.
* License: You are free to do whatever you want with this program.
*===============================================================================

program define binscatter2, eclass 
	version 12.1
	
	syntax varlist(min=2 numeric) [if] [in] [aweight fweight], ///
	[ ///
		by(varname) ///
		Nquantiles(integer 20) ///
		GENxq(name) ///
		discrete ///
		xq(varname numeric) ///
		MEDians ///
		CONTROLs(varlist numeric ts fv) ///
		absorb(varname) ///
		noAddmean ///
		LINEtype(string) ///
		rd(numlist ascending) ///
		reportreg ///
		COLors(string) ///
		MColors(string) ///
		LColors(string) ///
		\Msymbols(string) ///
		savegraph(string) ////
		savedata(string) ///
		replace ///
		nofastxtile ///
		randvar(varname numeric) ///
		randcut(real 1) ///
		verbose ///
		randn(integer -1) ///
		/* LEGACY OPTIONS */ nbins(integer 20) create_xq x_q(varname numeric) symbols(string) method(string) unique(string) ///
		*]

	set more off
	preserve
	
	* Prereq: must have gtools
	cap which fasterxtile
	local a1 = _rc
	cap which gcollapse
	local a2 = _rc
	if `a1'!=0 | `a2'!=0 {
		di as error "Error: Must have gtools installed to use binscatter2"
		di as error " See the Github page: https://github.com/mcaceresb/stata-gtools"
		exit
	}
	
	if "`verbose'"!="" timer clear
	if "`verbose'"!="" timer on 1 // total timer
	if "`verbose'"!="" timer on 2 // setup and error checking timier

	* Create convenient weight local
	if ("`weight'"!="") local wt [`weight'`exp']
	
	***** Begin legacy option compatibility code
	
	if (`nbins'!=20) {
		if (`nquantiles'!=20) {
			di as error "Cannot specify both nquantiles() and nbins(): both are the same option, nbins is supported only for backward compatibility."
			exit
		}
		di as text "NOTE: legacy option nbins() has been renamed nquantiles(), and is supported only for backward compatibility."
		local nquantiles=`nbins'
	}
	
	if ("`create_xq'"!="") {
		if ("`genxq'"!="") {
			di as error "Cannot specify both genxq() and create_xq: both are the same option, create_xq is supported only for backward compatibility."
			exit
		}
		di as text "NOTE: legacy option create_xq has been renamed genxq(), and is supported only for backward compatibility."
		local genxq="q_"+word("`varlist'",-1)
	}
	
	if ("`x_q'"!="") {
		if ("`xq'"!="") {
			di as error "Cannot specify both xq() and x_q(): both are the same option, x_q() is supported only for backward compatibility."
			exit
		}
		di as text "NOTE: legacy option x_q() has been renamed xq(), and is supported only for backward compatibility."
		local xq `x_q'
	}
	
	if ("`symbols'"!="") {
		if ("`msymbols'"!="") {
			di as error "Cannot specify both msymbols() and symbols(): both are the same option, symbols() is supported only for backward compatibility."
			exit
		}
		di as text "NOTE: legacy option symbols() has been renamed msymbols(), and is supported only for backward compatibility."
		local msymbols `symbols'
	}
	
	if ("`linetype'"=="noline") {
		di as text "NOTE: legacy line type 'noline' has been renamed 'none', and is supported only for backward compatibility."
		local linetype none
	}
	
	if ("`method'"!="") {
		di as text "NOTE: method() is no longer a recognized option, and will be ignored. binscatter15 now always uses the fastest method without a need for two instances"
	}
	
	if ("`unique'"!="") {
		di as text "NOTE: unique() is no longer a recognized option, and will be ignored. binscatter15 now considers the x-variable discrete if it has fewer unique values than nquantiles()"
	}

*-------------------------------------------------------------------------------
* Error checking
*-------------------------------------------------------------------------------

	* Set default linetype and check valid
	if ("`linetype'"=="") local linetype lfit
	else if !inlist("`linetype'","connect","lfit","qfit","none") {
		di as error "linetype() must either be connect, lfit, qfit, or none"
		exit
	}
	
	* Check that nofastxtile isn't combined with fastxtile-only options
	if "`fastxtile'"=="nofastxtile" & ("`randvar'"!="" | `randcut'!=1 | `randn'!=-1) {
		di as error "Cannot combine randvar, randcut or randn with nofastxtile"
		exit
	}

	* Misc checks
	if ("`genxq'"!="" & ("`xq'"!="" | "`discrete'"!="")) | ("`xq'"!="" & "`discrete'"!="") {
		di as error "Cannot specify more than one of genxq(), xq(), and discrete simultaneously."
		exit
	}
	if ("`genxq'"!="") confirm new variable `genxq'
	if ("`xq'"!="") {
		capture assert `xq'==int(`xq') & `xq'>0
		if _rc!=0 {
			di as error "xq() must contain only positive integers."
			exit
		}
		
		if ("`controls'`absorb'"!="") di as text "warning: xq() is specified in combination with controls() or absorb(). note that binning takes places after residualization, so the xq variable should contain bins of the residuals."
	}
	if `nquantiles'!=20 & ("`xq'"!="" | "`discrete'"!="") {
		di as error "Cannot specify nquantiles in combination with discrete or an xq variable."
		exit
	}
	if "`reportreg'"!="" & !inlist("`linetype'","lfit","qfit") {
		di as error "Cannot specify 'reportreg' when no fit line is being created."
		exit
	}
	if "`replace'"=="" {
		if `"`savegraph'"'!="" {
			if regexm(`"`savegraph'"',"\.[a-zA-Z0-9]+$") confirm new file `"`savegraph'"'
			else confirm new file `"`savegraph'.gph"'
		}
		if `"`savedata'"'!="" {
			confirm new file `"`savedata'.csv"'
			confirm new file `"`savedata'.do"'
		}
	}

	* Mark sample (reflects the if/in conditions, and includes only nonmissing observations)
	marksample touse
	markout `touse' `by' `xq' `controls' `absorb', strok
	qui count if `touse'
	local samplesize=r(N)
	local touse_first=_N-`samplesize'+1
	local touse_last=_N

	* Parse varlist into y-vars and x-var
	local x_var=word("`varlist'",-1)
	local y_vars=regexr("`varlist'"," `x_var'$","")
	local ynum=wordcount("`y_vars'")

	* Check number of unique byvals & create local storing byvals
	if "`by'"!="" {
		local byvarname `by'
		capture confirm numeric variable `by'
		if _rc {
			* by-variable is string => generate a numeric version
			tempvar by
			tempname bylabel
			egen `by'=group(`byvarname'), lname(`bylabel')
		}	
		local bylabel `:value label `by'' /*catch value labels for numeric by-vars too*/ 	
		tempname byvalmatrix
		qui tab `by' if `touse', nofreq matrow(`byvalmatrix')	
		local bynum=r(r)
		forvalues i=1/`bynum' {
			local byvals `byvals' `=`byvalmatrix'[`i',1]'
		}
	}
	else local bynum=1
	
if "`verbose'"!="" timer off 2

* xx restrict sample

*-------------------------------------------------------------------------------
* Residualize x and y vars
*-------------------------------------------------------------------------------

if "`verbose'"!="" timer on 3 // residualize x timer

	* Controls specified
	if (`"`controls'`absorb'"'!="") quietly {
	
		* Parse absorb to define the type of regression to be used
		if `"`absorb'"'!="" {
			local regtype "areg"
			local absorb "absorb(`absorb')"
		}
		else {
			local regtype "reg"
		}
	
		* Generate residuals
		local firstloop=1
		foreach var of varlist `x_var' `y_vars' {
			tempvar residvar
			`regtype' `var' `controls' `wt' if `touse', `absorb' noheader notable
			predict `residvar' if e(sample), residuals
			if ("`addmean'"!="noaddmean") {
				summarize `var' `wt' if `touse', meanonly
				replace `residvar'=`residvar'+r(mean)
			}	
			label variable `residvar' "`var'"
			if `firstloop'==1 {
				local x_r `residvar'
				local firstloop=0
			}
			else local y_vars_r `y_vars_r' `residvar'
		}
	}
	
	* No controls specified
	else {
		local x_r `x_var'
		local y_vars_r `y_vars'
	}

if "`verbose'"!="" timer off 3

*-------------------------------------------------------------------------------
* Run regressions for fit lines
*-------------------------------------------------------------------------------

if "`verbose'"!="" timer on 4

	if ("`reportreg'"=="") local reg_verbosity "quietly"

	if inlist("`linetype'","lfit","qfit") `reg_verbosity' {

		* If doing a quadratic fit, generate a quadratic term in x
		if "`linetype'"=="qfit" {
			tempvar x_r2
			gen `x_r2'=`x_r'^2
		}
		
		* Create matrices to hold regression results
		tempname e_b_temp
		forvalues i=1/`ynum' {
			tempname y`i'_coefs
		}
		
		* LOOP over by-vars
		local counter_by=1
		if ("`by'"=="") local noby="noby"
		foreach byval in `byvals' `noby' {
		
			* LOOP over rd intervals
			tokenize  "`rd'"
			local counter_rd=1	
				
			while ("`1'"!="" | `counter_rd'==1) {
				* display text headers
				if "`reportreg'"!="" {
					di "{txt}{hline}"
					if ("`by'"!="") {
						if ("`bylabel'"=="") di "-> `byvarname' = `byval'"
						else {
							di "-> `byvarname' = `: label `bylabel' `byval''"
						}
					}
					if ("`rd'"!="") {
						if (`counter_rd'==1) di "RD: `x_var'<=`1'"
						else if ("`2'"!="") di "RD: `x_var'>`1' & `x_var'<=`2'"
						else di "RD: `x_var'>`1'"
					}
				}
				
				* set conditions on reg
				local conds `touse'
				
				if ("`by'"!="" ) local conds `conds' & `by'==`byval'
				
				if ("`rd'"!="") {
					if (`counter_rd'==1) local conds `conds' & `x_r'<=`1'
					else if ("`2'"!="") local conds `conds' & `x_r'>`1' & `x_r'<=`2'
					else local conds `conds' & `x_r'>`1'
				}

				local counter_depvar=1
				foreach depvar of varlist `y_vars_r' {
					* display text headers
					if (`ynum'>1) {
						if ("`controls'`absorb'"!="") local depvar_name : var label `depvar'
						else local depvar_name `depvar'
						di as text "{bf:y_var = `depvar_name'}"
					}
					* perform regression
					if ("`reg_verbosity'"=="quietly") capture reg `depvar' `x_r2' `x_r' `wt' if `conds', noheader notable
					else capture noisily reg `depvar' `x_r2' `x_r' `wt' if `conds'
					* store results
					if (_rc==0) matrix e_b_temp=e(b)
					else if (_rc==2000) {
						if ("`reg_verbosity'"=="quietly") di as error "no observations for one of the fit lines. add 'reportreg' for more info."
						if ("`linetype'"=="lfit") matrix e_b_temp=.,.
						else /*("`linetype'"=="qfit")*/ matrix e_b_temp=.,.,.
					}
					else {
						error _rc
						exit _rc
					}
					* relabel matrix row			
					if ("`by'"!="") matrix roweq e_b_temp = "by`counter_by'"
					if ("`rd'"!="") matrix rownames e_b_temp = "rd`counter_rd'"
					else matrix rownames e_b_temp = "="
					* save to y_var matrix
					if (`counter_by'==1 & `counter_rd'==1) matrix `y`counter_depvar'_coefs'=e_b_temp
					else matrix `y`counter_depvar'_coefs'=`y`counter_depvar'_coefs' \ e_b_temp
					local ++counter_depvar
				}
				if (`counter_rd'!=1) mac shift
				local ++counter_rd
			}
			local ++counter_by
		}
	
		* relabel matrix column names
		forvalues i=1/`ynum' {
			if ("`linetype'"=="lfit") matrix colnames `y`i'_coefs' = "`x_var'" "_cons"
			else if ("`linetype'"=="qfit") matrix colnames `y`i'_coefs' = "`x_var'^2" "`x_var'" "_cons"
		}
	}	

if "`verbose'"!="" timer off 4

*-------------------------------------------------------------------------------
* Generate x-bin
*-------------------------------------------------------------------------------

qui keep if ~mi(`x_r')
qui foreach v of local y_vars_r {
	keep if ~mi(`v')
}

if "`verbose'"!="" timer on 5 

* When xq is not specified...
if "`xq'"=="" {
	* When discrete is not specified...
	if "`discrete'"=="" {
		if ("`genxq'"!="") local xq `genxq'
		else tempvar xq
		fasterxtile `xq' = `x_r', nq(`nquantiles')	
	}
	* If discrete is specified...
	if "`discrete'"!="" {
		if ("`genxq'"!="") local xq `genxq'
		else tempvar xq
		gen `xq' = `x_r'
	}
}

* When xq is specified....
else {
	noi di "XX  xq option is not implemented"
}

if "`verbose'"!="" timer off 5

*-------------------------------------------------------------------------------
* Compute means of x and y within each bin
* KEY OUTPUT: `y1_scatterpts' for each 1,...N depvars is a N_BINS x 2 matrix
*             containing binned x vals in col 1 and binned y vals in col 2
*-------------------------------------------------------------------------------

if "`verbose'"!="" timer on 6

* Collapse residualized y vars and x var within each x bin
drop if `xq'==.
gcollapse `y_vars_r' `x_r', by(`xq') fast

* Make matrix containing mean x and mean y within each bin for each y var
local counter_depvar=0
foreach depvar of varlist `y_vars_r' {
	local ++counter_depvar
	tempname y`counter_depvar'_scatterpts
	mkmat `x_r' `depvar', mat(`y`counter_depvar'_scatterpts')
}

if "`verbose'"!="" timer off 6

*-------------------------------------------------------------------------------
* Graph the binscatter
*-------------------------------------------------------------------------------

if "`verbose'"!="" timer on 7

* If rd is specified, prepare xline parameters
if "`rd'"!="" {
	foreach xval in "`rd'" {
		local xlines `xlines' xline(`xval', lpattern(dash) lcolor(gs8))
	}
}

* Fill colors if missing
if `"`colors'"'=="" local colors navy maroon forest_green dkorange teal cranberry ///
	lavender khaki sienna emidblue emerald brown erose gold bluishgray
if `"`mcolors'"'=="" {
	if (`ynum'==1 & `bynum'==1 & "`linetype'"!="connect") local mcolors `: word 1 of `colors''
	else local mcolors `colors'
}
if `"`lcolors'"'=="" {
	if (`ynum'==1 & `bynum'==1 & "`linetype'"!="connect") local lcolors `: word 2 of `colors''
	else local lcolors `colors'
}
local num_mcolor=wordcount(`"`mcolors'"')
local num_lcolor=wordcount(`"`lcolors'"')

* Prepare connect & msymbol options
if ("`linetype'"=="connect") local connect "c(l)"
if "`msymbols'"!="" {
	local symbol_prefix "msymbol("
	local symbol_suffix ")"
}
	
*** Prepare scatter plots
* c indexes which color is to be used
local c=0
local counter_series=0
local counter_by=0
if ("`by'"=="") local noby="noby"
foreach byval in `byvals' `noby' {
	local ++counter_by
	local xind=`counter_by'*2-1
	local yind=`counter_by'*2
	local counter_depvar=0
	foreach depvar of varlist `y_vars' {
		local ++counter_depvar
		local ++c
		local row=1
		local xval=`y`counter_depvar'_scatterpts'[`row',`xind']
		local yval=`y`counter_depvar'_scatterpts'[`row',`yind']
		if !missing(`xval',`yval') {
			local ++counter_series
			local scatters `scatters' (scatteri
			if ("`savedata'"!="") {
				if ("`by'"=="") local savedata_scatters `savedata_scatters' (scatter `depvar' `x_var'
				else local savedata_scatters `savedata_scatters' (scatter `depvar'_by`counter_by' `x_var'_by`counter_by'
			}
		}
		else continue
		while (`xval'!=. & `yval'!=.) {
			local scatters `scatters' `yval' `xval'	
			local ++row
			local xval=`y`counter_depvar'_scatterpts'[`row',`xind']
			local yval=`y`counter_depvar'_scatterpts'[`row',`yind']
		}
		* Add options
		local scatter_options `connect' mcolor(`: word `c' of `mcolors'') lcolor(`: word `c' of `lcolors'') `symbol_prefix'`: word `c' of `msymbols''`symbol_suffix'
		local scatters `scatters', `scatter_options')
		if ("`savedata'"!="") local savedata_scatters `savedata_scatters', `scatter_options')
		* Add legend
		if "`by'"=="" {
			if (`ynum'==1) local legend_labels off
			else local legend_labels `legend_labels' lab(`counter_series' `depvar')
		}
		else {
			if ("`bylabel'"=="") local byvalname=`byval'
			else {
				local byvalname `: label `bylabel' `byval''
			}
			if (`ynum'==1) local legend_labels `legend_labels' lab(`counter_series' `byvarname'=`byvalname')
			else local legend_labels `legend_labels' lab(`counter_series' `depvar': `byvarname'=`byvalname')
		}
		if ("`by'"!="" | `ynum'>1) local order `order' `counter_series'
	}
}

*** Prepare fit lines
if inlist(`"`linetype'"',"lfit","qfit") {
	
	* c indexes which color is to be used
	local c=0
	local rdnum=wordcount("`rd'")+1
	tempname fitline_bounds
	if ("`rd'"=="") matrix `fitline_bounds'=.,.
	else matrix `fitline_bounds'=.,`=subinstr("`rd'"," ",",",.)',.
	* LOOP over by-vars
	local counter_by=0
	if ("`by'"=="") local noby="noby"
	foreach byval in `byvals' `noby' {
		local ++counter_by
		** Set the column for the x-coords in the scatterpts matrix
		local xind=`counter_by'*2-1
		* Set the row to start seeking from. note: each time we seek a coeff, it should be from row (rd_num)(counter_by-1)+counter_rd
		local row0=( `rdnum' ) * (`counter_by' - 1)
		* LOOP over y-vars
		local counter_depvar=0
		foreach depvar of varlist `y_vars_r' {
			local ++counter_depvar
			local ++c
			* Find lower and upper bounds for the fit line
			matrix `fitline_bounds'[1,1]=`y`counter_depvar'_scatterpts'[1,`xind']
			local fitline_ub_rindex=`nquantiles'
			local fitline_ub=.
			while `fitline_ub'==. {
				local fitline_ub=`y`counter_depvar'_scatterpts'[`fitline_ub_rindex',`xind']
				local --fitline_ub_rindex
			}
			matrix `fitline_bounds'[1,`rdnum'+1]=`fitline_ub'
			* LOOP over rd intervals
			forvalues counter_rd=1/`rdnum' {
				if (`"`linetype'"'=="lfit") {
					local coef_quad=0
					local coef_lin=`y`counter_depvar'_coefs'[`row0'+`counter_rd',1]
					local coef_cons=`y`counter_depvar'_coefs'[`row0'+`counter_rd',2]
				}
				else if (`"`linetype'"'=="qfit") {
					local coef_quad=`y`counter_depvar'_coefs'[`row0'+`counter_rd',1]
					local coef_lin=`y`counter_depvar'_coefs'[`row0'+`counter_rd',2]
					local coef_cons=`y`counter_depvar'_coefs'[`row0'+`counter_rd',3]
				}
				if !missing(`coef_quad',`coef_lin',`coef_cons') {
					local leftbound=`fitline_bounds'[1,`counter_rd']
					local rightbound=`fitline_bounds'[1,`counter_rd'+1]
				
					local fits `fits' (function `coef_quad'*x^2+`coef_lin'*x+`coef_cons', range(`leftbound' `rightbound') lcolor(`: word `c' of `lcolors''))
				}
			}
		}
	}
}
	
* Prepare y-axis title
if (`ynum'==1) local ytitle `y_vars'
else if (`ynum'==2) local ytitle : subinstr local y_vars " " " and "
else local ytitle : subinstr local y_vars " " "; ", all

* Display graph
timer on 9
local graphcmd twoway `scatters' `fits', graphregion(fcolor(white)) `xlines' xtitle(`x_var') ytitle(`ytitle') legend(`legend_labels' order(`order')) `options'
if ("`savedata'"!="") local savedata_graphcmd twoway `savedata_scatters' `fits', graphregion(fcolor(white)) `xlines' xtitle(`x_var') ytitle(`ytitle') legend(`legend_labels' order(`order')) `options'
`graphcmd'
timer off 9

if "`verbose'"!="" timer off 7

*-------------------------------------------------------------------------------
* Save results out
*-------------------------------------------------------------------------------
	

if "`verbose'"!="" timer on 8

* Save graph
if `"`savegraph'"'!="" {
	* check file extension using a regular expression
	if regexm(`"`savegraph'"',"\.[a-zA-Z0-9]+$") local graphextension=regexs(0)
	if inlist(`"`graphextension'"',".gph","") graph save `"`savegraph'"', `replace'
	else graph export `"`savegraph'"', `replace'
}

* Save data
if ("`savedata'"!="") {
	
	*** Save a CSV containing the scatter points
	tempname savedatafile
	file open `savedatafile' using `"`savedata'.csv"', write text `replace'
		
	* LOOP over rows
	forvalues row=0/`nquantiles' {
		forvalues counter_by=1/`bynum' {
			if (`row'==0) { /* write variable names */
				if "`by'"!="" local bynlabel _by`counter_by'
				file write `savedatafile' "`x_var'`bynlabel',"
			}
		else { /* write data values */
				if (`row'<=`=rowsof(`y1_scatterpts')') file write `savedatafile' (`y1_scatterpts'[`row',`counter_by'*2-1]) ","
				else file write `savedatafile' ".,"
			}
		}
		*** Now y-variables at the right
		local counter_depvar=0
		foreach depvar of varlist `y_vars' {
			local ++counter_depvar
			forvalues counter_by=1/`bynum' {
				if (`row'==0) { /* write variable names */
					if "`by'"!="" local bynlabel _by`counter_by'
					file write `savedatafile' "`depvar'`bynlabel'"
				}
				else { /* write data values */
					if (`row'<=`=rowsof(`y`counter_depvar'_scatterpts')') file write `savedatafile' (`y`counter_depvar'_scatterpts'[`row',`counter_by'*2])
					else file write `savedatafile' "."
				}
				* unless this is the last variable in the dataset, add a comma
				if !(`counter_depvar'==`ynum' & `counter_by'==`bynum') file write `savedatafile' ","
			} 
		}
		file write `savedatafile' _n
	} 

	file close `savedatafile'
	di as text `"(file `savedata'.csv written containing saved data)"'
		
	*** Save a do-file with the commands to generate a nicely labeled dataset and re-create the binscatter15 graph
	file open `savedatafile' using `"`savedata'.do"', write text `replace'
	file write `savedatafile' `"insheet using `savedata'.csv"' _n _n
	if "`by'"!="" {
		foreach var of varlist `x_var' `y_vars' {
			local counter_by=0
			foreach byval in `byvals' {
				local ++counter_by
				if ("`bylabel'"=="") local byvalname=`byval'
			else {
					local byvalname `: label `bylabel' `byval''
				}
				file write `savedatafile' `"label variable `var'_by`counter_by' "`var'; `byvarname'==`byvalname'""' _n
			}
		}
		file write `savedatafile' _n
	}
	
	file write `savedatafile' `"`savedata_graphcmd'"' _n
	file close `savedatafile'
	di as text `"(file `savedata'.do written containing commands to process saved data)"'
}

*-------------------------------------------------------------------------------
* Return items
*-------------------------------------------------------------------------------

/*
ereturn post, esample(`touse')
ereturn scalar N = `samplesize'
ereturn local graphcmd `"`graphcmd'"'
if inlist("`linetype'","lfit","qfit") {
	forvalues yi=`ynum'(-1)1 {
		ereturn matrix y`yi'_coefs=`y`yi'_coefs'
	}
}
*/
	
if ("`rd'"!="") {
	tempname rdintervals
	matrix `rdintervals' = (. \ `=subinstr("`rd'"," ","\",.)' ) , ( `=subinstr("`rd'"," ","\",.)' \ .)
	forvalues i=1/`=rowsof(`rdintervals')' {
		local rdintervals_labels `rdintervals_labels' rd`i'
	}
	matrix rownames `rdintervals' = `rdintervals_labels'
	matrix colnames `rdintervals' = gt lt_eq
	ereturn matrix rdintervals=`rdintervals'
}
	
if ("`by'"!="" & "`by'"=="`byvarname'") { /* if a numeric by-variable was specified */
	forvalues i=1/`=rowsof(`byvalmatrix')' {
		local byvalmatrix_labels `byvalmatrix_labels' by`i'
	}
	matrix rownames `byvalmatrix' = `byvalmatrix_labels'
	matrix colnames `byvalmatrix' = `by'
	ereturn matrix byvalues=`byvalmatrix'
}

quietly {
	if "`verbose'"!="" timer off 1
	if "`verbose'"!="" timer off 8
	if "`verbose'"!="" timer list
	if "`verbose'"!="" timer clear
}
if ("`verbose'"!="") {
	di "Ran in `r(t1)' seconds."
	di "  Setup: `r(t2)' seconds."
	di "  Residualize: `r(t3)' seconds."
	di "  Regressions: `r(t4)' seconds."
	di "  Xtile:: `r(t5)' seconds."
	di "  Collapse: `r(t6)' seconds."
	di "  Graph: `r(t7)' seconds."
	di "    Twoway: `r(t9)' seconds."
	di "  Save: `r(t8)' seconds."
}
	
end
