# Data Janitor Diaries

A collection of data janitor diaries, i.e. the steps needed to collect, clean, and organize data __before__ it can properly be analyzed, investigated, and published.

This repo consists of example scripts that are focused solely on downloading, unpacking, re-combining data files. There are some examples of analyses as a proof-of-concept, but for the most part, these are recipes you would run _before_ involving a database or statistical software package.

## Motivation

From an Aug. 8, 2014, article in the New York Times, ["For Big-Data Scientists, ‘Janitor Work’ Is Key Hurdle to Insights", New York Times](http://www.nytimes.com/2014/08/18/technology/for-big-data-scientists-hurdle-to-insights-is-janitor-work.html):

> Yet far too much handcrafted work — what data scientists call “data wrangling,” “data munging” and “data janitor work” — is still required. Data scientists, according to interviews and expert estimates, __spend from 50 percent to 80 percent of their time mired in this more mundane labor__ of collecting and preparing unruly digital data, before it can be explored for useful nuggets.

In my professional experience, data munging may seem mundane, but doing it almost always uncover useful information (and flaws) about a dataset. But you don't have to be [Henry Ford](http://corporate.ford.com/news-center/press-releases-detail/677-5-dollar-a-day) to know that if something sucks up 80 percent of your professional time, then you ought to become better at it.

## Useful programming

Novice programmers make the mistake of saving up their coding skills to use on a big enough idea. But being novices, they either don't have "(good) big ideas", or don't know where programming would even fit in.

Data munging is a great way to practice programming. The tasks are often easy enough for brute-force algorithms. And even if your solution is sub-optimal, it likely is still much faster than tackling it as old-fashioned grunt work.

One of my intentions for this repo is to spark ideas on the kinds of mundane things that can be made easier through programming.


### Todo: Conventions

(the repo is in-progress and being updated when I feel like it. Currently, it's a mishmash of conventions and styles that I'm going to make more uniform)

### Inventory (in-progress)

* California public salaries database - Scraping the links to the zip files, downloading them, and combining the CSV files into one.
* Congressional tweets - Getting the tweets and profiles of current members of Congress, via batch request to the Twitter API
* Popular baby names by state - combining the state files into a single CSV and doing some convenient calculations, such as rank-per-state-per-year
* Dallas crime reports - Sanely download hundreds of zip files from a FTP site



