
*===============================================================================
* Speed tests
*===============================================================================

clear all

*-------------------------------------------------------------------------------
* Setup options
*-------------------------------------------------------------------------------

local num_sims 6

local sim_1_size 100000
local sim_1_reps 5

local sim_2_size 1000000
local sim_2_reps 5

local sim_3_size 10000000
local sim_3_reps 5

local sim_4_size 50000000
local sim_4_reps 2

local sim_5_size 100000000
local sim_5_reps 1

local sim_6_size 500000000
local sim_6_reps 1

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
	qui sum results_new`i', d
	local med_new = r(p50)
	qui sum results_old`i', d
	local med_old = r(p50)
	local ratio_medians = `med_old' / `med_new'
	di "Ratio of medians in test `i': `ratio_medians'"
	qui sum results_new`i'
	gen results_new`i'_n = results_new`i' / r(mean)
	gen results_old`i'_n = results_old`i' / r(mean)
	histogram results_old`i'_n, name(fig`i', replace)
}

sum results_old*_n
