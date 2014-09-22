require 'pathname'
module SafecarRatings
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
      # todo
    end

    def munge!
      # todo
    end
  end


  module Fetching
    class << self
      SAFECAR_GOV_LISTINGS = {
        '2011-Newer' => 'http://www.safercar.gov/Vehicle+Shoppers/5-Star+Safety+Ratings/2011-Newer+Vehicles/Search-Results?startpage=0&pagesize=4000&vclass=&model=&year=&manufacturer=&searchtype=model&make1=&make2=&model1=&model2=&year1=&year2=&compcars=&year=&pagesize=100&channelLink=%2FVehicle%2BShoppers%2F5-Star%2BSafety%2BRatings%2F2011-Newer%2BVehicles%2FSearch-Results',
        '1990-2010' => 'http://www.safercar.gov/Vehicle+Shoppers/5-Star+Safety+Ratings/1990-2010+Vehicles/Search-Results?startpage=0&vclass=&model=&year=&manufacturer=&searchtype=model&make1=&make2=&model1=&model2=&year1=&year2=&compcars=&year=&pagesize=5000&channelLink2010=%2FVehicle%2BShoppers%2F5-Star%2BSafety%2BRatings%2F1990-2010%2BVehicles%2FSearch-Results'
      }

      def fetch_from_website
        require 'open-uri'
        require 'nokogiri'

        ## start with 1990-2010
        pdir = DATA_DIR.join('fetched', '1990-2010')
        pdir.mkpath
        list_url = SAFECAR_GOV_LISTINGS['1990-2010']
        puts "Fetching list: #{list_url}"
        page = Nokogiri::HTML(open(list_url))
        # begin the iteration
        _count = 0; fetched_count = 0
        page.search('th.fill a').each do |a|
          _count += 1
          url = 'http://www.safercar.gov' + a['href']
          fname = pdir.join(a['href'][/(?<=vehicleId=)\d+/] + '.html')
          if fname.exist?
            puts "#{_count}.\tAlready fetched #{url}"
          else
            fetched_count += 1
            puts "#{_count}.\tFetching #{url}"
            open(fname, 'w'){|f| f.write open(url){|o| o.read }}
          end
          if fetched_count % 25 == 24
            puts "Pausing..."
            sleep rand
          end
        end
      end # fetch from website

    end
  end
end
