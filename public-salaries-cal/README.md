# ca_public_salaries.rb

A quickie script to batch download all the raw salary data from the [Government Compensation in California (GCC) Website](http://publicpay.ca.gov/), e.g. http://publicpay.ca.gov/

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


