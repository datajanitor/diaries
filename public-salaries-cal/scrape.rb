# ca_public_salaries.rb
# A quickie script to batch download all the raw salary data
# from publicpay.ca.gov
#
# by Dan Nguyen
#
# How to use:
# install these gems: nokogiri, rubyzip
#
# then pop open irb and run:
# require './ca_public_salaries'
# CAPublicSalaries.fetch_data  #=> this will download all the zip files to your local drive
# CAPublicSalaries.unzip_data  #=> this will unzip the files from the previous step
# CAPublicSalaries.concat_data  #=> this combines all the CSV files from the previous step into one CSV
#
# the result will be a file, ./data-hold/processed/combined-data.csv, that is 1.2+GB
require 'fileutils'
module CAPublicSalaries
  DATA_SOURCE_URL = 'http://www.publicpay.ca.gov/Reports/RawExport.aspx'

  PROCESSED_DATA_DIR = File.expand_path('../data-hold/processed', __FILE__)
  RAW_DATA_DIR = File.expand_path('../data-hold/raw', __FILE__)
  ZIP_DIR = File.join(RAW_DATA_DIR, 'zip')
  CSV_DIR = File.join(RAW_DATA_DIR, 'csv')

  class << self
    def fetch_data
      require 'nokogiri'
      require 'open-uri'

      FileUtils.mkdir_p(ZIP_DIR)
      Nokogiri::HTML(open(DATA_SOURCE_URL)).search('.column_main li a').each do |a|
        url = URI.join(DATA_SOURCE_URL, a['href']).to_s
        fname = url[/(?<=file=).+/]
        puts "Fetching #{fname}"
        open(File.join(ZIP_DIR, fname), 'wb') do |ofile|
          open(url, 'rb'){ |ifile| ofile.write ifile.read }
        end
      end
    end

    def unzip_data
      require 'zip'
      FileUtils.mkdir_p(CSV_DIR)
      Dir.glob(File.join(ZIP_DIR, '*.zip')).each do |zipname|
        Zip::File.open(zipname) do |zip_file|
          zip_file.each do |entry|
            # Extract to file/directory/symlink
            puts "Extracting #{entry.name}"
            dest_fname = File.join CSV_DIR, entry.name
            entry.extract dest_fname
          end
        end
      end
    end

    def concat_data
      require 'csv'
      require 'set'
      FileUtils.mkdir_p(PROCESSED_DATA_DIR)
      file_handles = {}
      all_headers = Set.new
      Dir.glob(File.join(CSV_DIR, '*.csv')).each do |csv_name|
        file = open(csv_name, 'r')
        # the first 4 lines are boilerplate and can be ignored
        4.times{ file.gets }
        # collect the headers
        header_line = file.gets
        all_headers.merge CSV.new(header_line).to_a
        # save the handle and header_line for the next loop
        file_handles[csv_name] = [header_line, file]
      end

      # at this point, all_headers includes all the different fields
      # just incase the field format has changed over the years

      # now build the CSV file by re-looping through all the files and parsing them
      # as CSV, then concatenating them to out_csv
      CSV.open(File.join(PROCESSED_DATA_DIR, 'combined-data.csv'), 'w', headers: true) do |out_csv|
        out_csv << all_headers.to_a.flatten
        file_handles.each_pair do |csv_name, (hline, file)|
          in_csv = CSV.parse(hline + file.read.force_encoding('iso-8859-1').encode('utf-8'),  headers: true)
          puts "#{csv_name}: #{in_csv.count} rows"
          in_csv.each do |row|
            out_csv << row.to_h
          end
          file.close
        end
      end
    end
  end
end
