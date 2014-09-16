# FBI UCR Bulk Data

There seems to be a lack of bulk data downloads of the important FBI Uniform Crime Reports.

Their tablemaker tool is here: http://www.ucrdatatool.gov/Search/Crime/Local/JurisbyJuris.cfm


The fetching method is straightforward. Use the [Ruby mechanize gem](http://readysteadycode.com/howto-scrape-websites-with-ruby-and-mechanize) to fill out the forms. You could probably just examine the POST request and skip the form process...but it's pretty straightforward to do it this old fashioned way.

There is also a POST request available for CSV files:

    http://www.ucrdatatool.gov/Search/Crime/Local/DownCrimeJurisbyJuris.cfm/LocalCrimeJurisbyJuris.csv
    

An example parameter list for that request:

    CrimeCrossId=4060&YearStart=1985&YearEnd=2012&DataType=1%2C2%2C3%2C4

