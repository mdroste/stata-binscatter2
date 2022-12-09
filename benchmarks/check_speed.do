*===============================================================================
* FILE:    check_speed.do
* PURPOSE: Runs speed tests comparing the runtime of binscatter and binscatter2
* AUTHOR:  Michael Droste (mdroste@fas.harvard.edu)
* UPDATED: Dec 6, 2022
*===============================================================================

clear all
cls
cap log close
log using benchmark_log, replace

*===============================================================================
* Configuration
*===============================================================================

*-----------------------------------------------
* Options for all benchmarks
*-----------------------------------------------

* Number of repetitions.
local num_reps = 25

* List containing set of bins to consider
local bin_list 20

* List containing set of observations (in millions) to consider
local obs_list 10 20 30 40 50 60 70 80 90 100 

*-----------------------------------------------
* Options for certain benchmarks
*-----------------------------------------------

* Benchmark 3: Number of controls
local C = 10

* Benchmark 4: Number of FEs
local G = 50

* Benchmark 5: Number of FEs, as fraction of # obs (grows with N)
local G_rel = 0.1

* Benchmark 6: Number of FEs, two-way FEs spec
local G1 = 50
local G2 = 100

*===============================================================================
* BENCHMARK 1: CONTINUOUS X, NO CONTROLS/FIXED EFFECTS
*===============================================================================

*-------------------------------------------------------------
* Run simulations
*-------------------------------------------------------------

* Double loop over bins and obs
foreach o in `obs_list' {
	foreach num_bins in `bin_list' {
		
		di " "
		di " "
		di "Simulations with `o' million observations and `num_bins' bins"
		
		* Create matrix to store results
		mat R_`num_bins'_`o' = J(`num_reps',3,.)
		
		* Loop over repetitions
		forval i=1/`num_reps' {
			
			noi di "   Repetition `i' of `num_reps'"
			
			timer clear

			* Generate data
			drop _all
			set obs `=`o'*1000000'
			gen x = runiform()
			gen y = 1 + 2*x + 3*x^2 + 4*x^3 + rnormal()*5*x
			preserve
			
			* Binscatter
			restore, preserve
			timer on 1
			qui binscatter y x, nquantiles(`num_bins')
			timer off 1
			
			* Binscatter2
			restore, preserve
			timer on 2
			qui binscatter2 y x, nbins(`num_bins')
			timer off 2
			
			* Binsreg
			restore
			timer on 3
			qui binsreg y x, nbins(`num_bins') polyreg(1)
			timer off 3
			
			* Save current rep to results row
			timer list
			mat R_`num_bins'_`o'[`i',1] = r(t1)
			mat R_`num_bins'_`o'[`i',2] = r(t2)
			mat R_`num_bins'_`o'[`i',3] = r(t3)
			di " " 
			
		}
	}
}

*-------------------------------------------------------------
* Display results
*-------------------------------------------------------------

drop *
foreach num_bins in `bin_list' {
	foreach o in `obs_list' {
		svmat R_`num_bins'_`o'
		rename (R_`num_bins'_`o'1 R_`num_bins'_`o'2 R_`num_bins'_`o'3) (bs_`num_bins'_`o' bs2_`num_bins'_`o' br_`num_bins'_`o')
	}
}
gen rep = _n
reshape long bs_20_ bs2_20_ br_20_, i(rep) j(obs)
*reshape long bs_10_ bs_50_ bs_100_ bs2_10_ bs2_20_ bs2_50_ bs2_100_ br_10_ br_20_ br_50_ br_100_, i(rep) j(obs)
rename *_ *
reshape long bs_ bs2_ br_, i(rep obs) j(bins)
rename *_ *
save benchmarks_1, replace

collapse (median) bs bs2 br, by(obs bins)
gen relative_bs2_vs_bs = bs / bs2
gen relative_bs2_vs_br = br / bs2

* Display table of relative speed, binscatter2 vs binscatter
preserve
keep obs bin relative_bs2_vs_bs
reshape wide relative_bs2_vs_bs, i(obs) j(bins)
list
restore

* Display table of relative speed, binscatter2 vs binsreg
preserve
keep obs bin relative_bs2_vs_br
reshape wide relative_bs2_vs_br, i(obs) j(bins)
list
restore


*===============================================================================
* BENCHMARK 2: DISCRETE X (= # BINS), NO CONTROLS/FIXED EFFECTS
*===============================================================================

*-------------------------------------------------------------
* Run simulations
*-------------------------------------------------------------

* Double loop over bins and obs
foreach o in `obs_list' {
	foreach num_bins in `bin_list' {
		
		di " "
		di " " 
		di "Simulations with `o' million observations and `num_bins' bins"
		
		* Create matrix to store results
		mat R_`num_bins'_`o' = J(`num_reps',3,.)
		
		* Loop over repetitions
		forval i=1/`num_reps' {
			
			noi di "   Repetition `i' of `num_reps'"
			
			timer clear

			* Generate data
			drop _all
			set obs `=`o'*1000000'
			gen x = ceil(runiform()*`num_bins')
			gen y = 1 + 2*x + 3*x^2 + 4*x^3 + rnormal()*5*x
			preserve
			
			* Binscatter
			restore, preserve
			timer on 1
			qui binscatter y x, discrete
			timer off 1
			
			* Binscatter2
			restore, preserve
			timer on 2
			qui binscatter2 y x, discrete
			timer off 2
			
			* Binsreg
			restore
			timer on 3
			qui binsreg y x, nbins(`num_bins') polyreg(1)
			timer off 3
			
			* Save current rep to results row
			timer list
			mat R_`num_bins'_`o'[`i',1] = r(t1)
			mat R_`num_bins'_`o'[`i',2] = r(t2)
			mat R_`num_bins'_`o'[`i',3] = r(t3)
			di " " 
			
		}
	}
}

*-------------------------------------------------------------
* Display results
*-------------------------------------------------------------

drop *
foreach num_bins in `bin_list' {
	foreach o in `obs_list' {
		svmat R_`num_bins'_`o'
		rename (R_`num_bins'_`o'1 R_`num_bins'_`o'2 R_`num_bins'_`o'3) (bs_`num_bins'_`o' bs2_`num_bins'_`o' br_`num_bins'_`o')
	}
}
gen rep = _n
reshape long bs_10_ bs_20_ bs_50_ bs_100_ bs2_10_ bs2_20_ bs2_50_ bs2_100_ br_10_ br_20_ br_50_ br_100_, i(rep) j(obs)
rename *_ *
reshape long bs_ bs2_ br_, i(rep obs) j(bins)
rename *_ *
save benchmarks_2, replace

collapse (median) bs bs2 br, by(obs bins)
gen relative_bs2_vs_bs = bs / bs2
gen relative_bs2_vs_br = br / bs2

* Display table of relative speed, binscatter2 vs binscatter
preserve
keep obs bin relative_bs2_vs_bs
reshape wide relative_bs2_vs_bs, i(obs) j(bins)
list
restore

* Display table of relative speed, binscatter2 vs binsreg
preserve
keep obs bin relative_bs2_vs_br
reshape wide relative_bs2_vs_br, i(obs) j(bins)
list
restore

*===============================================================================
* BENCHMARK 3: MULTIPLE CONTROLS
*===============================================================================

*-------------------------------------------------------------
* Run simulations
*-------------------------------------------------------------

* Double loop over bins and obs
foreach o in `obs_list' {
	foreach num_bins in `bin_list' {
		
		di " "
		di " " 
		di "Simulations with `o' million observations and `num_bins' bins"
		
		* Create matrix to store results
		mat R_`num_bins'_`o' = J(`num_reps',3,.)
		
		* Loop over repetitions
		forval i=1/`num_reps' {
			
			noi di "   Repetition `i' of `num_reps'"
			
			timer clear

			* Generate data
			drop _all
			set obs `=`o'*1000000'
			gen x = runiform()
			gen y = 1 + 2*x + 3*x^2 + 4*x^3 + rnormal()*5*x
			gen g = ceil(runiform()*50)
			forval i=1/`C' {
				gen c`i' = rnormal()
			}
			preserve
			
			* Binscatter
			restore, preserve
			timer on 1
			qui binscatter y x, nquantiles(`num_bins') controls(c*) absorb(g)
			timer off 1
			
			* Binscatter2
			restore, preserve
			timer on 2
			qui binscatter2 y x, nbins(`num_bins') controls(c*) absorb(g)
			timer off 2
			
			* Binsreg
			restore
			timer on 3
			qui binsreg y x c*, nbins(`num_bins') polyreg(1) absorb(g)
			timer off 3
			
			* Save current rep to results row
			timer list
			mat R_`num_bins'_`o'[`i',1] = r(t1)
			mat R_`num_bins'_`o'[`i',2] = r(t2)
			mat R_`num_bins'_`o'[`i',3] = r(t3)
			di " " 
			
		}
	}
}

*-------------------------------------------------------------
* Display results
*-------------------------------------------------------------

* Take results matrices, put into Stata dataset, generate relative runtime
local num_reps 5
local bin_list 10 20 50 100
local obs_list 1 10 25 50 100
drop *
foreach num_bins in `bin_list' {
	foreach o in `obs_list' {
		svmat R_`num_bins'_`o'
		rename (R_`num_bins'_`o'1 R_`num_bins'_`o'2 R_`num_bins'_`o'3) (bs_`num_bins'_`o' bs2_`num_bins'_`o' br_`num_bins'_`o')
	}
}
gen rep = _n
reshape long bs_10_ bs_20_ bs_50_ bs_100_ bs2_10_ bs2_20_ bs2_50_ bs2_100_ br_10_ br_20_ br_50_ br_100_, i(rep) j(obs)
rename *_ *
reshape long bs_ bs2_ br_, i(rep obs) j(bins)
rename *_ *
save benchmarks_3, replace

collapse (median) bs bs2 br, by(obs bins)
gen relative_bs2_vs_bs = bs / bs2
gen relative_bs2_vs_br = br / bs2

* Display table of relative speed, binscatter2 vs binscatter
preserve
keep obs bin relative_bs2_vs_bs
reshape wide relative_bs2_vs_bs, i(obs) j(bins)
list
restore

* Display table of relative speed, binscatter2 vs binsreg
preserve
keep obs bin relative_bs2_vs_br
reshape wide relative_bs2_vs_br, i(obs) j(bins)
list
restore

*===============================================================================
* BENCHMARK 4: SMALL NUMBER OF ONE-WAY FIXED EFFECTS
*===============================================================================

*-------------------------------------------------------------
* Run simulations
*-------------------------------------------------------------

* Double loop over bins and obs
foreach o in `obs_list' {
	foreach num_bins in `bin_list' {
		
		di " "
		di " " 
		di "Simulations with `o' million observations and `num_bins' bins"
		
		* Create matrix to store results
		mat R_`num_bins'_`o' = J(`num_reps',3,.)
		
		* Loop over repetitions
		forval i=1/`num_reps' {
			
			noi di "   Repetition `i' of `num_reps'"
			
			timer clear

			* Generate data
			drop _all
			set obs `=`o'*1000000'
			gen x = runiform()
			gen y = 1 + 2*x + 3*x^2 + 4*x^3 + rnormal()*5*x
			gen g = ceil(runiform()*50)
			preserve
			
			* Binscatter
			restore, preserve
			timer on 1
			qui binscatter y x, nquantiles(`num_bins') absorb(g)
			timer off 1
			
			* Binscatter2
			restore, preserve
			timer on 2
			qui binscatter2 y x, nbins(`num_bins') absorb(g)
			timer off 2
			
			* Binsreg
			restore
			timer on 3
			qui binsreg y x, nbins(`num_bins') polyreg(1) absorb(g)
			timer off 3
			
			* Save current rep to results row
			timer list
			mat R_`num_bins'_`o'[`i',1] = r(t1)
			mat R_`num_bins'_`o'[`i',2] = r(t2)
			mat R_`num_bins'_`o'[`i',3] = r(t3)
			di " " 
			
		}
	}
}

*-------------------------------------------------------------
* Display results
*-------------------------------------------------------------

* Take results matrices, put into Stata dataset, generate relative runtime
local num_reps 5
local bin_list 10 20 50 100
local obs_list 1 10 25 50 100
drop *
foreach num_bins in `bin_list' {
	foreach o in `obs_list' {
		svmat R_`num_bins'_`o'
		rename (R_`num_bins'_`o'1 R_`num_bins'_`o'2 R_`num_bins'_`o'3) (bs_`num_bins'_`o' bs2_`num_bins'_`o' br_`num_bins'_`o')
	}
}
gen rep = _n
reshape long bs_10_ bs_20_ bs_50_ bs_100_ bs2_10_ bs2_20_ bs2_50_ bs2_100_ br_10_ br_20_ br_50_ br_100_, i(rep) j(obs)
rename *_ *
reshape long bs_ bs2_ br_, i(rep obs) j(bins)
rename *_ *
save benchmarks_4, replace

collapse (median) bs bs2 br, by(obs bins)
gen relative_bs2_vs_bs = bs / bs2
gen relative_bs2_vs_br = br / bs2

* Display table of relative speed, binscatter2 vs binscatter
preserve
keep obs bin relative_bs2_vs_bs
reshape wide relative_bs2_vs_bs, i(obs) j(bins)
list
restore

* Display table of relative speed, binscatter2 vs binsreg
preserve
keep obs bin relative_bs2_vs_br
reshape wide relative_bs2_vs_br, i(obs) j(bins)
list
restore

*===============================================================================
* BENCHMARK 5: LARGE NUMBER OF ONE-WAY FIXED EFFECTS
*===============================================================================

*-------------------------------------------------------------
* Run simulations
*-------------------------------------------------------------

* Double loop over bins and obs
foreach o in `obs_list' {
	foreach num_bins in `bin_list' {
		
		di " "
		di " " 
		di "Simulations with `o' million observations and `num_bins' bins"
		
		* Create matrix to store results
		mat R_`num_bins'_`o' = J(`num_reps',3,.)
		
		* Loop over repetitions
		forval i=1/`num_reps' {
			
			noi di "   Repetition `i' of `num_reps'"
			
			timer clear

			* Generate data
			drop _all
			set obs `=`o'*1000000'
			gen x = runiform()
			gen y = 1 + 2*x + 3*x^2 + 4*x^3 + rnormal()*5*x
			gen g = ceil(runiform()*`G_rel'*`=`o'*1000000')
			preserve
			
			* Binscatter
			restore, preserve
			timer on 1
			qui binscatter y x, nquantiles(`num_bins') absorb(g)
			timer off 1
			
			* Binscatter2
			restore, preserve
			timer on 2
			qui binscatter2 y x, nbins(`num_bins') absorb(g)
			timer off 2
			
			* Binsreg
			restore
			timer on 3
			qui binsreg y x, nbins(`num_bins') polyreg(1) absorb(g)
			timer off 3
			
			* Save current rep to results row
			timer list
			mat R_`num_bins'_`o'[`i',1] = r(t1)
			mat R_`num_bins'_`o'[`i',2] = r(t2)
			mat R_`num_bins'_`o'[`i',3] = r(t3)
			di " " 
			
		}
	}
}

*-------------------------------------------------------------
* Display results
*-------------------------------------------------------------

* Take results matrices, put into Stata dataset, generate relative runtime
local num_reps 5
local bin_list 10 20 50 100
local obs_list 1 10 25 50 100
drop *
foreach num_bins in `bin_list' {
	foreach o in `obs_list' {
		svmat R_`num_bins'_`o'
		rename (R_`num_bins'_`o'1 R_`num_bins'_`o'2 R_`num_bins'_`o'3) (bs_`num_bins'_`o' bs2_`num_bins'_`o' br_`num_bins'_`o')
	}
}
gen rep = _n
reshape long bs_10_ bs_20_ bs_50_ bs_100_ bs2_10_ bs2_20_ bs2_50_ bs2_100_ br_10_ br_20_ br_50_ br_100_, i(rep) j(obs)
rename *_ *
reshape long bs_ bs2_ br_, i(rep obs) j(bins)
rename *_ *
save benchmarks_5, replace

collapse (median) bs bs2 br, by(obs bins)
gen relative_bs2_vs_bs = bs / bs2
gen relative_bs2_vs_br = br / bs2

* Display table of relative speed, binscatter2 vs binscatter
preserve
keep obs bin relative_bs2_vs_bs
reshape wide relative_bs2_vs_bs, i(obs) j(bins)
list
restore

* Display table of relative speed, binscatter2 vs binsreg
preserve
keep obs bin relative_bs2_vs_br
reshape wide relative_bs2_vs_br, i(obs) j(bins)
list
restore

*===============================================================================
* BENCHMARK 6: TWOWAY FIXED EFFECTS
*===============================================================================

*-------------------------------------------------------------
* Run simulations
*-------------------------------------------------------------

* Double loop over bins and obs
foreach o in `obs_list' {
	foreach num_bins in `bin_list' {
		
		di " "
		di " " 
		di "Simulations with `o' million observations and `num_bins' bins"
		
		* Create matrix to store results
		mat R_`num_bins'_`o' = J(`num_reps',3,.)
		
		* Loop over repetitions
		forval i=1/`num_reps' {
			
			noi di "   Repetition `i' of `num_reps'"
			
			timer clear

			* Generate data
			drop _all
			set obs `=`o'*1000000'
			gen x = runiform()
			gen y = 1 + 2*x + 3*x^2 + 4*x^3 + rnormal()*5*x
			gen g1 = ceil(runiform()*`G1')
			gen g2 = ceil(runiform()*`G2')
			preserve
			
			* Binscatter
			restore, preserve
			timer on 1
			*qui binscatter y x, nquantiles(`num_bins') absorb(g)
			timer off 1
			
			* Binscatter2
			restore, preserve
			timer on 2
			qui binscatter2 y x, nbins(`num_bins') absorb(g1 g2)
			timer off 2
			
			* Binsreg
			restore
			timer on 3
			qui binsreg y x, nbins(`num_bins') polyreg(1) absorb(g1 g2)
			timer off 3
			
			* Save current rep to results row
			timer list
			mat R_`num_bins'_`o'[`i',1] = r(t1)
			mat R_`num_bins'_`o'[`i',2] = r(t2)
			mat R_`num_bins'_`o'[`i',3] = r(t3)
			di " " 
			
		}
	}
}

*-------------------------------------------------------------
* Display results
*-------------------------------------------------------------

* Take results matrices, put into Stata dataset, generate relative runtime
local num_reps 5
local bin_list 10 20 50 100
local obs_list 1 10 25 50 100
drop *
foreach num_bins in `bin_list' {
	foreach o in `obs_list' {
		svmat R_`num_bins'_`o'
		rename (R_`num_bins'_`o'1 R_`num_bins'_`o'2 R_`num_bins'_`o'3) (bs_`num_bins'_`o' bs2_`num_bins'_`o' br_`num_bins'_`o')
	}
}
gen rep = _n
reshape long bs_10_ bs_20_ bs_50_ bs_100_ bs2_10_ bs2_20_ bs2_50_ bs2_100_ br_10_ br_20_ br_50_ br_100_, i(rep) j(obs)
rename *_ *
reshape long bs_ bs2_ br_, i(rep obs) j(bins)
rename *_ *
save benchmarks_6, replace

collapse (median) bs bs2 br, by(obs bins)
gen relative_bs2_vs_bs = bs / bs2
gen relative_bs2_vs_br = br / bs2

* Display table of relative speed, binscatter2 vs binscatter
preserve
keep obs bin relative_bs2_vs_bs
reshape wide relative_bs2_vs_bs, i(obs) j(bins)
list
restore

* Display table of relative speed, binscatter2 vs binsreg
preserve
keep obs bin relative_bs2_vs_br
reshape wide relative_bs2_vs_br, i(obs) j(bins)
list
restore
