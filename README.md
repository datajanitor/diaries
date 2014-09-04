# Computational Data Diaries

A collection of data downloading recipe examples. I'm using this data for a class, but these examples are meant to show how to break up big data tasks into small pieces.


### Inventory (in-progress)

* California public salaries database - Scraping the links to the zip files, downloading them, and combining the CSV files into one.
* Congressional tweets - Getting the tweets and profiles of current members of Congress, via batch request to the Twitter API
* Popular baby names by state - combining the state files into a single CSV and doing some convenient calculations, such as rank-per-state-per-year
* Dallas crime reports - Sanely download hundreds of zip files from a FTP site

## Purpose

For my Public Affairs Data Journalism I class (Fall 2014), I need to have cleaned and specifically-packaged datasets to use as examples. The scripts in these repos handle the downloading, organizing, and automated pruning and aggregation I need to do for my students, as I can't expect all/any of them to know enough SQL or programming to wrangle large, unorganized datasets.

Understanding these scripts aren't part of the class, though in my winter class, which studies computational methods in data journalism, I'll expect students to use computational thinking to tackle data problems.

These aren't great scripts or even best-practices. They're just things I whipped up that were, in my opinion, less maddening than doing things the manual way. 

A lot of novice programmers ask how to use what they've learned in class in real-life and my advice is: use programming to make your own life less annoying. Since my life currently involves getting and organizing data for class, these scripts are what I've written to ease my own pain.


