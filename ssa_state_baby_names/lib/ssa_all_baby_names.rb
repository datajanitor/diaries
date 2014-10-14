require 'pathname'
module SsaAllBabyNames
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
      Munging.combine
    end
  end



  module Fetching
    class << self
      def fetch_from_website
        require 'open-uri'
        remote_url = 'http://www.ssa.gov/oact/babynames/names.zip'
        file = DATA_DIR.join('fetched', 'all-names.zip')
        open(file, 'w') do |f|
          f.write open(remote_url){|o| o.read}
        end
      end
    end
  end # Fetching

  module Unpacking
    class << self
      def unzip
        require 'open-uri'
        require 'zip'
        zipname = DATA_DIR.join('fetched', 'all-names.zip')
        alldir = DATA_DIR.join('unpacked', 'all')
        alldir.mkpath
        Zip::File.open(zipname) do |z|
          z.select{|e| e.name =~ /yob\d{4}/}.each do |entry|
            dest_fname = alldir.join  entry.name
            puts "Extracting to #{dest_fname}"
            # this strange #extract notation simply means we overwrite existing files
            entry.extract(dest_fname){ true }
          end
        end
      end
      true
    end
  end # unpacking


  # Each file looks like this:

  #   Mary,F,8148
  #   Anna,F,3143
  #   Emma,F,2303
  #   Elizabeth,F,2187
  #   Minnie,F,2004

  module Munging
    class << self
      def combine
        require 'csv'
        # set up the CSV file
        csv_name = DATA_DIR.join('munged', 'all-names.csv')
        csv = CSV.open(csv_name, 'w', headers: true)
        csv << [:year, :name, :sex, :count, :per_100k, :rank,  :count_change, :per_100k_change, :rank_change]

        # set up a placeholder for prev_year
        prev_year_data = {}
        # gather up the unpacked files, which each represent a year
        fnames = Dir.glob DATA_DIR.join('unpacked', 'all', '*.txt')
        fnames.each do |fname|
          current_year_data = {}
          year = File.basename(fname)[/\d{4}/]
          puts "#{year}"
          rows = open(fname){|f| f.readlines.map{|r| r.strip.split(',').tap{|s| s[2] = s[2].to_i } }  }

          # group rows by name and sex
          rows_grouped_by_sex = rows.group_by{ |row| row[1]}
          rows_grouped_by_sex.each_pair do |sex, sex_rows|
            puts "\t#{sex}"
            last_rank = 0
            last_baby_count = 0
            total_names_of_sex = sex_rows.count
            total_babies_of_sex = sex_rows.inject(0){|sum, r| sum += r[2] }
            sex_rows.each_with_index do |row, idx|
              baby = {
                year: year,
                name: row[0],
                sex: row[1],
                count: row[2]
              }
              # calculate rank
              if last_baby_count == baby[:count]
                # no increment in rank
                baby[:rank] = last_rank
              else
                # not a tie
                last_rank = baby[:rank] = (idx + 1)
                last_baby_count = baby[:count]
              end
              # calculate per_100k
              baby[:per_100k] = (baby[:count] * 100000.0 / total_babies_of_sex).round
              # if previous year data exists, calculate the change
              if (p_baby = prev_year_data[[baby[:name], baby[:sex]]])
                baby[:count_change] = baby[:count] - p_baby[:count]
                baby[:per_100k_change] = baby[:per_100k] - p_baby[:per_100k]
                baby[:rank_change] = p_baby[:rank] - baby[:rank]
              else
                baby[:count_change] = baby[:count]
                baby[:per_100k_change] = baby[:per_100k]
                # need to invert this number by total_names
                baby[:rank_change] = (total_names_of_sex - baby[:rank]) + 1
              end
              # write to CSV
              csv << baby
              current_year_data[[baby[:name], baby[:sex]]] = baby
            end # done with this sex
          end # done with this year / fname

          prev_year_data  = current_year_data
        end

        csv.close
        true
      end
    end # munging

  end
end

