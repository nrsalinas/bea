bea
===

Perl and R scripts to carry on a Biotic Element Analysis.

2prabclus.pl: Outputs a couple of files compatible with Prabclus. One file (a .csv file) will contain the geographic distributions in a grid format, whose resolution can be selected by the user. The second file (a .txt text file) provides the neighborhood information of the grid (which cell is beside which). Finally, this Perl script will call the R script (see below).

Requirements: Perl interpreter.


prabclus.r: Executes a Biotic Element Analysis. It takes as inputs the two files created by 2prabclus.pl. However, this script can be executed directly from the command line, without using 2prabclus.pl

Requirements: R interprester and R packages maps, mapdata, and prabclus.
