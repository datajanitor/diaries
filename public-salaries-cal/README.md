# ca_public_salaries.rb

A quickie script to batch download all the raw salary data from the [Government Compensation in California (GCC) Website](http://publicpay.ca.gov/), e.g. http://publicpay.ca.gov/

This is an example of **day-to-day** grunt coding. You could obviously [download each zip file](http://www.publicpay.ca.gov/Reports/RawExport.aspx) via point-and-click, then point-and-click to unzip them, then manually import them via your favorite database manager.

But even just 25 files can be a hassle to work with, especially since each file make take some time to download and unpackage. Also, if you were building an application or report in which having the most up-to-date data was essential, this point-and-click process would become very tiresome to do on a daily basis (the GCC is purportedly updated every morning).

Putting in even 30 minutes of time to write a batch-downloading script is worth it in this case, as it might take at least that long to _physically_ download, unpackage, and manually combine the data. Making a script also allows us to throw in automated data-error-checking as needed.





## Requirements

- Ruby 1.9.3 or 2.x
- the nokogiri gem
- the rubyzip gem


## Description

The script consists of three methods:

- `.fetch_data` - downloads all zips found in the [Raw Export page](http://www.publicpay.ca.gov/Reports/RawExport.aspx)
- `.unzip_data` - extracts the CSV files in each zip
- `.concat_data` - combines all the CSVs into one CSV with common headers

## Result

The result is a 1.2GB file stored at `./data-hold/processed/combined-data.csv`


