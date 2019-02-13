*===============================================================================
* FILE:    check_functionality.do
* PURPOSE: Verifies options work for binscatter2 and demonstrates equivalence
*          with binscatter
* AUTHOR:  Michael Droste (mdroste@fas.harvard.edu)
* UPDATED: 2019/02/13
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
set obs 50000
gen x = runiform()
gen z = 3*x^2 + rnormal()
gen fe = ceil(runiform()*5)
gen g = ceil(runiform()*2)
gen y = fe + 2*x + 3*x^2 + 4*x^3 + z + rnormal()*10*x^2
gen y2 = fe - 2*x - 3*x^2 - 4*x^3 + z + rbeta(1,300)*2000*x
gen y3 = 1 + 2*x + 3*x^2 + 4*x^3 + rnormal()*5*x^2
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
