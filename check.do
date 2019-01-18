*===============================================================================
* Test file: binscatter vs binscatter2
*===============================================================================

* Change directory to github folder
cd "C:\Users\Mike\Documents\GitHub\stata-binscatter2"
set rmsg on
set more off

*===============================================================================
* Functionality tests
*===============================================================================

*-------------------------------------------------------------------------------
* Continuous x tests
*-------------------------------------------------------------------------------

* Generate simulated data
clear all
set obs 1000000
gen x = runiform()
gen z = 3*x^2 + rnormal()
gen fe = ceil(runiform()*5)
gen g = ceil(runiform()*2)
gen y = fe + 2*x + 3*x^2 + 4*x^3 + z + rnormal()*3*x
gen y2 = fe - 2*x - 3*x^2 - 4*x^3 + z + rnormal()*3*x
replace y = y + 2 if g==2
replace y2 = y2 - 2 if g==2
tempfile t1
save `t1'

* Plain scatter plot of data
scatter y x, name(fig0, replace)

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

* Simulation 7: two y vars, medians
use `t1', clear
binscatter y y2 x, medians name(fig7a, replace)
binscatter2 y y2 x, medians name(fig7b, replace)

* Simulation 8: two y vars, genxq
use `t1', clear
binscatter y y2 x, genxq(test1) medians name(fig8a, replace)
binscatter2 y y2 x, genxq(test2) medians name(fig8b, replace)

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

*===============================================================================
* Speed tests
*===============================================================================

* Define number of simulations in Monte Carlo simulation
local num_sims 11

* Create a list containing observations
local sizes 1000000 5000000

* Run a monte carlo test for each on binscatter
mat results_old = J(`num_sims',4,.) 
forval i=1/`num_sims' {
	local col = 0
	foreach j in `sizes' {
		local col = `col' + 1
		* generate data
		clear
		set obs `j'
		gen x = runiform()
		gen y = 1 + 2*x + 3*x^2 + 4*x^3 + rnormal()*3*x
		timer clear
		timer on 1
		qui binscatter y x
		timer off 1
		timer list
		mat results_old[`i',`col'] = r(t1)
		timer clear
	}
}
svmat results_old


* Define number of simulations in Monte Carlo simulation
local num_sims 11

* Create a list containing observations
local sizes 1000000 5000000

* Run a monte carlo test for each on binscatter
mat results_new = J(`num_sims',4,.) 
forval i=1/`num_sims' {
	local col = 0
	foreach j in `sizes' {
		local col = `col' + 1
		* generate data
		clear
		set obs `j'
		gen x = runiform()
		gen y = 1 + 2*x + 3*x^2 + 4*x^3 + rnormal()*3*x
		timer clear
		timer on 1
		qui binscatter2 y x
		timer off 1
		timer list
		mat results_new[`i',`col'] = r(t1)
		timer clear
	}
}
svmat results_new
