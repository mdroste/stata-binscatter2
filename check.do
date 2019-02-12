*===============================================================================
* Test file: binscatter vs binscatter2
*===============================================================================

* Change directory to github folder
cd "C:\Users\Mike\Documents\GitHub\stata-binscatter2"
set rmsg on
set more off
cap program drop binscatter2

*===============================================================================
* Functionality tests
*===============================================================================

*-------------------------------------------------------------------------------
* Continuous x tests
*-------------------------------------------------------------------------------

* Generate simulated data
clear all
set obs 500000
gen x = runiform()
gen z = 3*x^2 + rnormal()
gen fe = ceil(runiform()*5)
gen g = ceil(runiform()*2)
gen y = fe + 2*x + 3*x^2 + 4*x^3 + z + rnormal()*10*x^2
gen y2 = fe - 2*x - 3*x^2 - 4*x^3 + z + rbeta(1,300)*2000*x
replace y = y + 2 if g==2
replace y2 = y2 - 2 if g==2
tempfile t1
save `t1'

binscatter y x, name(fig1a, replace)
binscatter2 y x, name(fig1b, replace)
binscatter2 y x, quantiles(25 75) name(fig2, replace)

* Usual scatter plot of y on x, for reference
twoway (scatter y x, msize(tiny)), name(fig0, replace)

/*
* Simulation 1: standard binscatter, no options
use `t1', clear 
binscatter y x, name(fig1a, replace)
binscatter2 y x, name(fig1b, replace)

* Simulation 2: single control
use `t1', clear
binscatter y x, controls(z) name(fig2a, replace)
binscatter2 y x, controls(z) name(fig2b, replace)

* Simulation 3: RD
use `t1', clear 
binscatter y x, rd(0.5) name(fig3a, replace)
binscatter2 y x, rd(0.5) name(fig3b, replace)

* Simulation 4: by group
use `t1', clear 
binscatter y x, by(g) name(fig4a, replace)
binscatter2 y x, by(g) name(fig4b, replace)

* Simulation 5: two y vars
use `t1', clear
binscatter y y2 x, name(fig5a, replace)
binscatter2 y y2 x, name(fig5b, replace)

* Simulation 6: two y vars, by group
use `t1', clear
binscatter y y2 x, by(g) name(fig6a, replace)
binscatter2 y y2 x, by(g) name(fig6b, replace)

* Simulation 7: medians of variable with highly asymmetric error distribution
use `t1', clear
binscatter y2 x, medians name(fig7a, replace)
binscatter2 y2 x, medians name(fig7b, replace)

* Simulation 8: two y vars, genxq
use `t1', clear
binscatter y y2 x, genxq(test1) medians name(fig8a, replace)
binscatter2 y y2 x, genxq(test2) medians name(fig8b, replace)

* Simulation 9: two y vars, xq
use `t1', clear
gen xq_test = .
replace xq_test = 1  if inrange(x,0.00, 0.2)
replace xq_test = 2  if inrange(x,0.20, 0.4)
replace xq_test = 3  if inrange(x,0.40, 0.5)
replace xq_test = 4  if inrange(x,0.50, 0.6)
replace xq_test = 5  if inrange(x,0.60, 0.65)
replace xq_test = 6  if inrange(x,0.65, 0.7)
replace xq_test = 7  if inrange(x,0.70, 0.75)
replace xq_test = 8  if inrange(x,0.75, 0.8)
replace xq_test = 9  if inrange(x,0.80, 0.9)
replace xq_test = 10 if inrange(x,0.90, 1.0)
binscatter y y2 x, xq(xq_test) medians name(fig9a, replace)
binscatter2 y y2 x, xq(xq_test) medians name(fig9b, replace)
*/
* Simulation 10: savedata
use `t1', clear
binscatter y y2 x, savedata(test1) replace
binscatter2 y y2 x, savedata(test2) replace


*-------------------------------------------------------------------------------
* Discrete x tests
*-------------------------------------------------------------------------------

* Generate simulated data
clear all
set obs 10000
gen x = ceil(runiform()*100)
gen y = 1 + 2*x + 3*x^2 + 4*x^3 + rnormal()*50*x^2
tempfile t1
save `t1'

* Baseline simulation
use `t1', clear 
binscatter y x, name(fig1a, replace) discrete
binscatter2 y x, name(fig1b, replace) discrete

** xx potential issue with small matsizes

*===============================================================================
* Speed tests
*===============================================================================

clear all
*-------------------------------------------------------------------------------
* Setup options
*-------------------------------------------------------------------------------

local num_sims 3

local sim_1_size 1000
local sim_1_reps 50

local sim_2_size 10000
local sim_2_reps 40

local sim_3_size 100000
local sim_3_reps 30

local sim_4_size 1000000
local sim_4_reps 20

*-------------------------------------------------------------------------------
* Initialization
*-------------------------------------------------------------------------------

* Cheap fix: define `sizes' and `num_sims'
local max_reps 0
forval i=1/`num_sims' {
	di "sim i reps: `sim_`i'_reps'"
	local sizes `sizes' `sims_`i'_size'
	if `sim_`i'_reps' > `max_reps' local max_reps = `sim_`i'_reps'
}

* Create matrices to store results
set matsize 10000
mat results_old = J(`max_reps',`num_sims',.) 
mat results_new = J(`max_reps',`num_sims',.) 

*-------------------------------------------------------------------------------
* Monte Carlo tests
*-------------------------------------------------------------------------------

* Cheap fix: define `sizes' and `num_sims'
forval i=1/`num_sims' {
	local sizes `sizes' `sim_`i'_size'
}

local col = 0
forval i=1/`num_sims' {
	noi di "sim `i'"
	local curr_reps = `sim_`i'_reps'
	local curr_size = `sim_`i'_size'
	local col = `col' + 1
	di "curr reps: `curr_reps'"
	
	* Run Monte Carlo simulations
	qui forval j=1/`curr_reps' {
		noi di "  rep `j'"
	
		* Increment column
		if mod(`i',10)==0 noi di "    `j'"
		
		* Generate data
		clear
		set obs `curr_size'
		gen x = runiform()
		gen y = 1 + 2*x + 3*x^2 + 4*x^3 + rnormal()*5*x
		
		* Randomize which one goes first
		local dice = runiform()
		if `dice'<0.5 {
			local num1  
			local num2 2
		}
		if `dice'>=0.5 {
			local num1 2
			local num2 
		}
		
		* Test out binscatters (in randomized order)
		timer clear
		timer on 1
		qui binscatter`num1' y x
		timer off 1
		timer on 2
		qui binscatter`num2' y x
		timer off 2
		
		* Save results
		timer list
		mat results_old[`i',`col'] = r(t1)
		mat results_new[`i',`col'] = r(t2)
		timer clear
		
	}
}

* Save results to datasets
svmat results_old
svmat results_new

*-------------------------------------------------------------------------------
* Results analysis
*-------------------------------------------------------------------------------

* Count number of sizes
local num_sizes = `num_sims'

* List output
forval i=1/`num_sizes' {
	qui sum results_new`i', d
	local med_new = r(p50)
	qui sum results_old`i', d
	local med_old = r(p50)
	local ratio_medians = `med_old' / `med_new'
	di "Ratio of medians in test `i': `ratio_medians'"
	qui sum results_new`i'
	gen results_new`i'_n = results_new`i' / r(mean)
	gen results_old`i'_n = results_old`i' / r(mean)
	histogram results_old`i'_n
}

