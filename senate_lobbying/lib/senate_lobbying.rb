require 'pathname'
module SenateLobbying
  DATA_DIR = Pathname.new File.expand_path( '../../data-hold', __FILE__)
  class << self
    def setup!
      %w(fetched unpacked munged).each do |dname|
        DATA_DIR.join(dname).mkpath
      end
    end
    def fetch!
      Fetching.fetch_from_website
    end
    def unpack!
      Unpacking.unzip
    end
    def munge!
      # todo
    end
  end


  module Fetching
    LOBBYING_DATA_SOURCE_URL = 'http://www.senate.gov/legislative/Public_Disclosure/database_download.htm'
    def self.fetch_from_website
      require 'open-uri'
      require 'nokogiri'
      page = Nokogiri::HTML(open(LOBBYING_DATA_SOURCE_URL))
      # Select just the links that are zip files
      links = page.search('a').select{|a| a['href'] =~ /\/downloads\/\w+\.zip/}
      links.each do |link|
         # Downloading the file
         puts "Getting #{link['href']}"
         fname = DATA_DIR.join 'fetched', File.basename(link['href'])
         open(fname, 'w'){|f| f.write open(link['href']){|o| o.read} }
      end

      true
    end
  end # end fetching

  module Unpacking
    def self.unzip
      require 'zip'
      # Get all the zip filenames from where we stored them
      zip_filenames = Dir.glob(DATA_DIR.join('fetched', '*.zip'))
      zip_filenames.each do |zipname|
        Zip::File.open(zipname) do |z|
          z.each do |entry|
            dest_fname = DATA_DIR.join 'unpacked', entry.name
            puts "Extracting to #{dest_fname}"
            # this strange #extract notation simply means we overwrite existing files
            entry.extract(dest_fname){ true }
          end
        end
      end

      true
    end

  end # unpacking
end
