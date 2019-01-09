
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

Binned scatterplots provide a convenient and non-parametric way to visualize an arbitrary conditional expectation function. They are useful for evaluating the relationship between two variables, possibly conditional on a set of covariates and/or fixed effects. Michael Stepner has provided a wonderful slide deck on the procedure involved in producing binned scatterplots on his website, available [here](https://michaelstepner.com/binscatter/binscatter-StataConference2014.pdf). 

Anyone who has used binscatter on a large dataset appreciates the fact that it can take a while to run. There are basically three mathematical operations involved in binscatter of y on x without conditioning covariates: the independent variable must be sorted, quantiles of the independent variable must be computed (except in the case of a 'discrete' binscatter), and the means of y must be computed within each quantile of x (or distinct value of x, in the case of a discrete binscatter). Michael's code is extremely well-written and was very efficient when it was first produced, using a number of clever tricks to make computing these quantiles really quick. However, recent improvements made possible by the -ftools- and -gtools- Stata plugins, produced by Ricardo Correia and Mauricio Caceres Bravo, respectively, have allowed these steps to be done considerably more efficiently and with fewer lines of code. 

This is especially important for applied economics researchers who need to work in a secure data environment. In these environments, programmer's time is at a premium. Binscatters are often useful diagnostic procedures to examine the relationship between variables, and are an important operation that an applied researcher may wish to run in real-time. In this case, it is extremely important for binscatter to be really fast. Empirical research in economics frequently makes use of datasets consisting of millions of observations. 


Installation
---------------------------------

There are two options for installing binscatter2.

1. The most recent version can be installed from Github with the following Stata command:

```stata
net install binscatter2, from(https://raw.githubusercontent.com/mdroste/stata-binscatter2/master/)
```

2. A ZIP containing the program can be downloaded and manually placed on the user's adopath from Github.


Usage
---------------------------------

The following two commands are equivalent:

```stata
binscatter y x
binscatter2 y x
```

More on this soon. See the help file in Stata.


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

As the name suggests, this program is just a faster version of binscatter, developed by the illustrious [Michael Stepner](https://github.com/michaelstepner) and Jessica Laird. In addition, binscatter2 would not have been possible without gtools by Mauricio Caceres Bravo, which (I would guess) would not have happened without ftools, developed by Sergio Correa.


License
---------------------------------

binscatter2 is [MIT-licensed](https://github.com/mdroste/stata-binscatter2/blob/master/LICENSE).
