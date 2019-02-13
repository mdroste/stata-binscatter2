
*===============================================================================
* Speed tests
*===============================================================================

clear all

*-------------------------------------------------------------------------------
* Setup options
*-------------------------------------------------------------------------------

local num_sims 4

local sim_1_size 1000000
local sim_1_reps 100

local sim_2_size 10000000
local sim_2_reps 50

local sim_3_size 25000000
local sim_3_reps 20

local sim_4_size 50000000
local sim_4_reps 5

*-------------------------------------------------------------------------------
* Initialization
*-------------------------------------------------------------------------------

* Cheap fix: define `sizes' and `num_sims'
local max_reps 0
forval i=1/`num_sims' {
	local sizes `sizes' `sims_`i'_size'
	if `sim_`i'_reps' > `max_reps' local max_reps = `sim_`i'_reps'
}
di

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
		noi di "  rep `j' of `curr_reps'"
		
		* Generate data
		clear
		set obs `curr_size'
		gen x = runiform()
		gen y = 1 + 2*x + 3*x^2 + 4*x^3 + rnormal()*5*x
		
		* Test binscatter
		timer on 1
		qui binscatter y x
		timer off 1
		
		
		* Test binscatter2
		timer on 2
		qui binscatter2 y x
		timer off 2
		
		* Save results
		timer list
		mat results_old[`j',`col'] = r(t1)
		mat results_new[`j',`col'] = r(t2)
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
	gen ratio`i' = results_old`i' / results_new`i'
	histogram ratio`i', name(fig`i', replace)
}

sum ratio*, d
