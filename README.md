
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

`version 0.1 08jan2019`


Overview
---------------------------------

binscatter2 is a faster method for producing binned scatterplots in Stata. It yields the same functionality as Michael Stepner's excellent -binscatter- package (originally developed with Jessica Laird), but scales much better for big datasets, like those that are now commonly used in applied economics research.

Motivation
---------------------------------

Binned scatterplots are a convenient, non-parametric method to visualize an arbitrary conditional expectation function. They are useful for examining the relationship between variables, possibly conditional on a set of covariates and/or fixed effects. Michael Stepner has provided a wonderful slide deck on the procedure involved in producing binned scatterplots on his website, available [here](https://michaelstepner.com/binscatter/binscatter-StataConference2014.pdf). 

Anyone who has used binscatter on a large dataset appreciates the fact that it can take a while to run. There are basically three mathematical operations involved in binscatter of y on x without conditioning covariates: the independent variable must be sorted, quantiles of the independent variable must be computed (except in the case of a 'discrete' binscatter), and the means of y must be computed within each quantile of x (or distinct value of x, in the case of a discrete binscatter). Michael's code is extremely well-written and was very efficient when it was first produced, using a number of clever tricks to make computing these quantiles really quick. However, recent improvements made possible by the -ftools- and -gtools- Stata plugins, produced by Ricardo Correia and Mauricio Caceres Bravo, respectively, have allowed these steps to be done considerably more efficiently and with fewer lines of code. 

This is especially important for applied economics researchers who need to work in a secure data environment. In these environments, programmer's time is at a premium. Binscatters are often a useful diagnostic prcoedure that researchers may wish to run in real-time for the purposes of data exploration. When working with datasets with millions of observations, it is important for binscatter to be as fast as possible. This is what binscatter2 primarily aims to do. The performance of binscatter2 scales with the number of observations in a dataset better than binscatter, resulting in substantial performance gains for datasets with millions of observations, as demonstrated in the benchmarking section below. In my experience, working with datasets with tens of millions of observations, binscatter2 reduces the runtime of a single binscatter from about five minutes to under one minute.

This project is being distributed separately from the original binscatter repository for a few reasons. For one, binscatter2 requires the compiled package gtools to run, and therefore the 'update' process of using binscatter2 may be nontrivial, especially for Stata users working on server environments that may not have privileges to compile code or modify available Stata packages. Second, incorporating the functionality of gtools into binscatter involves large changes to many parts of the code, and I can't guarantee that the multiple existing unresolved issues/forks on the Binscatter project page can be resolved easily with the present version of Binscatter2. Third, Binscatter2 creates a host of new features - given this and the aforementioned large changes to the code, it may have bugs to resolve. Michael Stepner is quite busy with his day job of being an economist, and I may have more time to fix these issues in the near term.


New Features
---------------------------------

In addition to general performance improvements, binscatter2 adds a few new features to the functionality of binscatter. Among these:

[x] Support for reghdfe. If reghdfe is installed, it is automatically used (unless specified otherwise with noreghdfe option). This offers modest further speed improvements and allows the user to directly absorb multi-way fixed effects. 
[x] Plot distributional statistics. The user can overlay quantiles of the sample distribution or standard deviation intervals on top of the means/medians within each bin, providing more information on the shape of the conditional distribution of y given x than is provided by the mean or median alone. 
[x] More flexible save commands. The user can save out to .dta files and also choose to omit the do-file created by savedata().
[x] Higher-order polynomial fit lines. Arbitrary polynomial fit lines are now supported.


Installation
---------------------------------

There are two options for installing binscatter2.

1. The most recent version can be installed from Github with the following Stata command:

```stata
net install binscatter2, from(https://raw.githubusercontent.com/mdroste/stata-binscatter2/master/)
```

2. A ZIP containing the program can be downloaded and manually placed on the user's adopath from Github.

I plan on submitting a stable version of this project to the SSC repository very soon.


Usage
---------------------------------

Complete internal documentation is provided with the installation and can be accessed by typing:
```stata
help binscatter2
````

Usage of binscatter2 is nearly identical to binscatter and should be familiar to any users of the original package.

The included do-file, check.do, provides a number of checks to verify the functionality of each option within binscatter2 and demonstrates equivalence to binscatter for options shared by both programs.



Benchmarks
---------------------------------

XX todo
  
Todo
---------------------------------

The following items will be addressed soon:

- [ ] Finish off this readme.md and the help file
- [ ] Finish benchmarking
- [ ] Add a ton of options


Acknowledgements
---------------------------------

As the name suggests, this program builds extensively on the indispenseable binscatter package, developed by the illustrious [Michael Stepner](https://github.com/michaelstepner) and Jessica Laird. In addition, binscatter2 would not have been possible without gtools by Mauricio Caceres Bravo, which (I would guess) would not have happened without ftools, developed by Sergio Correa.


License
---------------------------------

binscatter2 is [MIT-licensed](https://github.com/mdroste/stata-binscatter2/blob/master/LICENSE).
