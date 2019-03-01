
binscatter2
=================================

[Overview](#overview)
| [Motivation](#motivation)
| [Installation](#installation)
| [Usage](#usage)
| [Benchmarks](#benchmarks)
| [To-Do](#todo)
| [Acknowledgements](#acknowledgements)
| [License](#license)

Faster binned scatterplots in Stata with a few new bells and whistles

`version 0.14 13feb2019`


Overview
---------------------------------

binscatter2 is a program for producing binned scatterplots in Stata. It nests the functionality of the excellent [binscatter](https://github.com/michaelstepner/binscatter) package, but runs substantially faster for big datasets (see [benchmarks](#benchmarks)). In addition, binscatter2 offers a handful of new features: the ability to overlay additional information about the conditional probability distribution (e.g. quantile intervals) and additional options for fit lines, saving, and multi-way fixed effects.

Motivation
---------------------------------

Binned scatterplots are a convenient, non-parametric method to visualize an arbitrary conditional expectation function. They are useful for examining the relationship between variables, possibly conditional on a set of covariates and/or fixed effects. Michael Stepner has provided a wonderful slide deck describing binned scatterplots on his website, available [here](https://michaelstepner.com/binscatter/binscatter-StataConference2014.pdf). 

Anyone who has used binscatter on a large dataset can appreciate that it takes a while to run. The original binscatter program is extremely well-written and was very efficient when it was written; however, recent improvements made possible by the Stata program [gtools](https://github.com/mcaceresb/stata-gtools) have allowed several of the operations underlying binscatter to be accomplished more efficiently and with fewer lines of code. This means that binscatter2 runs much more quickly than binscatter for large datasets, as demonstrated in the [benchmarks](#benchmarks) below. In my experience, working with data involving tens or hundreds of millions of observation, binscatter2 runs between two and eight times faster than binscatter.

In addition, binscatter2 contains a handful of additional new features intended to enhance the functionality of binscatter. For one, binscatter now allows quantile intervals to be overlaid on top of the graph. This allows the user to gauge variation in the conditional distribution of y given x.



New Features
---------------------------------

In addition to substantial performance improvements for large datasets (see [benchmarks](#benchmarks)), binscatter2 adds a few new features to binscatter. In particular:

- [x] **Multi-way fixed effects**. If [reghdfe](https://github.com/sergiocorreia/reghdfe) is installed, multi-way fixed effects can be specified in the absorb() option.
- [x] **Quantile intervals**. Overlay quantiles of the sample distribution on top of the means/medians within each bin, providing more information on the shape of the conditional distribution of y given x.
- [x] **Flexible save commands**. Save scatter points out to .dta files and also choose to omit the do-file created by savedata() with the nodofile option.
- [x] **More fit line options**. Exponential and logarithmic fits, with higher-order polynomials coming soon.
- [x] **Alternative procedure to control for covariates**. Implements the suggested procedure described in [Cattaneo et al. (2019)](https://sites.google.com/site/nppackages/binsreg/Cattaneo-Crump-Farrell-Feng_2019_Binscatter.pdf) to control for covariates without residualizing y and x. 

![binscatter2 demo](benchmarks/ex.png "binscatter2 demo")


Installation
---------------------------------

There are two options for installing binscatter2.

1. The most recent version can be installed from Github with the following Stata command:

```stata
net install binscatter2, from("https://raw.githubusercontent.com/mdroste/stata-binscatter2/master/")
```

2. A ZIP containing the program can be downloaded and manually placed on the user's adopath from Github.

This project will be submitted to the SSC repository very soon.


Usage
---------------------------------

Complete internal documentation is provided with the installation and can be accessed by typing:
```stata
help binscatter2
````

The basic syntax and usage of binscatter2 is inherited from binscatter and should be familiar to existing users of that program.

This repository includes a do-file, check.do, that provides a number of checks to verify the functionality of each option within binscatter2 and demonstrates equivalence to binscatter for options shared by both programs. The file check_speed.do runs Monte Carlo simulations that were used in the benchmark section of this readme.



Benchmarks
---------------------------------

![binscatter2 benchmark](benchmarks/benchmarks.png "binscatter2 benchmark")


  
Todo
---------------------------------

The following items will be addressed soon:

- [ ] Fix higher-order polynomial fit lines
- [ ] Fix reghdfe support
- [ ] Save out quantile intervals when using savedata() option
- [ ] More aesthetic options on quantiles() option
- [ ] Comparison against binsreg


Acknowledgements
---------------------------------

As the name suggests, this program builds extensively on the indispenseable binscatter package, developed by the illustrious [Michael Stepner](https://github.com/michaelstepner) and Jessica Laird. 

In addition, binscatter2 would certainly not have been possible without [gtools](https://github.com/mcaceresb/stata-gtools) by Mauricio Caceres Bravo, which in turn would not have happened without [ftools](https://github.com/sergiocorreia/ftools), developed by Sergio Correa.


License
---------------------------------

binscatter2 is [MIT-licensed](https://github.com/mdroste/stata-binscatter2/blob/master/LICENSE).
