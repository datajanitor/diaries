require 'pathname'
module SsaStateBabyNames
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
        remote_url = 'http://www.ssa.gov/oact/babynames/state/namesbystate.zip'
        file = DATA_DIR.join('fetched', 'namesbystate.zip')
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
        zipname = DATA_DIR.join('fetched', 'namesbystate.zip')
        state_dir = DATA_DIR.join 'unpacked', 'states'
        state_dir.mkpath
        Zip::File.open(zipname) do |z|
          z.select{|e| e.name =~ /[A-Z]{2}\.TXT/}.each do |entry|
            dest_fname = state_dir.join entry.name
            puts "Extracting to #{dest_fname}"
            # this strange #extract notation simply means we overwrite existing files
            entry.extract(dest_fname){ true }
          end
        end
        true

      end
    end
  end # unpacking


  # Each file looks like this:

  #   AK,F,1910,Mary,14
  #   AK,F,1910,Annie,12
  #   AK,F,1910,Anna,10
  #   AK,F,1910,Margaret,8
  #   AK,F,1910,Helen,7
  #   AK,F,1910,Elsie,6

  module Munging
    class << self
      def combine
        require 'csv'
        # set up the CSV file
        csv_name = DATA_DIR.join('munged', 'state-names.csv')
        csv = CSV.open(csv_name, 'w', headers: true)
        csv << [:state, :year, :name, :sex, :count, :per_100k, :rank,  :count_change, :per_100k_change, :rank_change]

        # set up a placeholder for prev_year

        # gather up the unpacked files, which each represent a year
        fnames = Dir.glob DATA_DIR.join('unpacked', 'states', '*.TXT')
        fnames.each do |fname|
          current_year_data = {}
          puts fname
          rows = open(fname){|f| f.readlines.map{|r| r.strip.split(',').tap{|s| s[4] = s[4].to_i } }  }

          # first, we break things up by year
          prev_year_data = {}
          rows_grouped_by_year = rows.group_by{|row| row[2]}
          rows_grouped_by_year.each_pair do |year, year_rows|
            puts year
            # group rows by name and sex
            rows_grouped_by_sex = year_rows.group_by{ |row| row[1] }
            rows_grouped_by_sex.each_pair do |sex, sex_rows|
              puts "\t#{sex}"
              total_names_of_sex = sex_rows.count
              total_babies_of_sex = sex_rows.inject(0){|sum, r| sum += r[4] }
              last_rank = 0
              last_baby_count = 0


              sex_rows.each_with_index do |row, idx|
                baby = {
                  state: row[0],
                  year: year,
                  name: row[3],
                  sex: sex,
                  count: row[4]
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
          end
          prev_year_data  = current_year_data
        end

        csv.close
        true
      end
    end

  end
end

