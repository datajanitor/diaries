require 'fileutils'
require 'zip'
require 'open-uri'

module SSAStateBabyNames
  DATA_SOURCE_URL = 'http://www.ssa.gov/oact/babynames/state/namesbystate.zip'

  PROCESSED_DATA_DIR = File.expand_path('../../data-hold/processed', __FILE__)
  RAW_DATA_DIR = File.expand_path('../../data-hold/raw', __FILE__)
  FileUtils.mkdir_p PROCESSED_DATA_DIR
  FileUtils.mkdir_p RAW_DATA_DIR

  class << self
    def fetch_and_unzip
      zipname = File.join RAW_DATA_DIR, File.basename(DATA_SOURCE_URL)
      # fetch from the URL and save to disk
      puts "Downloading from #{DATA_SOURCE_URL}"
      open(zipname, 'wb'){|f| f.write open(DATA_SOURCE_URL){|u| u.read } }
      # now unzip
      Zip::File.open(zipname) do |zip_file|
        zip_file.each do |entry|
          dest_fname = File.join RAW_DATA_DIR, entry.name
          puts "Extracting to #{dest_fname}"
          # this strange #extract notation simply means we overwrite existing files
          entry.extract(dest_fname){ true }
        end
      end
      # return a list of text files
      Dir.glob(File.join RAW_DATA_DIR, '*.TXT')
    end

    def combine
      require 'csv'
      csv = CSV.open(File.join(PROCESSED_DATA_DIR, 'all-states.csv'), 'w')
      csv << %w(state gender year name count rank rank_change per_100k per_100k_change)
      txtfiles = Dir.glob(File.join RAW_DATA_DIR, '*.TXT')
      txtfiles.each do |txt_name|
        puts "Adding #{File.basename txt_name}"
        # normally, loading an entire CSV into memory, converting to an array
        # and then doing a group_by is not advisable. But these files
        # are pretty small and so this operation shouldn't crash most modern
        # computers. But yes, I'm being lazy here
        grouped_rows = CSV.open(txt_name).to_a.group_by{ |row| [row[1], row[2]] }
        # grouped_rows is a Hash with year values for keys
        prev_year = {}
        grouped_rows.each_value do |rows|
          total_names = rows.count
          total_babies = rows.inject(0){|sum, r| sum += r[4].to_i }
          last_rank = 1
          last_baby_count = 0
          current_year = rows.each_with_index.inject({}) do |hsh, (row, idx)|
            current_baby_count = row[4].to_i
            if last_baby_count == current_baby_count
              # this is a tie, so rank should be the same as the last
              rank = last_rank
            else
              # this is not a tie
              last_rank = rank = idx + 1
              last_baby_count = current_baby_count
            end

            per_100k = (current_baby_count[4].to_i * 100000.0 / total_babies).round(1)
            # calculate change from last year
            p_row = prev_year[row[3]]
            rank_change = p_row.nil? ? nil : -(rank - p_row[0])  # we want the inverse of the difference
            per_100k_change = p_row.nil? ? nil : (per_100k - p_row[1]).round(1)
            csv << (row << rank << rank_change << per_100k << per_100k_change)
            # use name field as the key
            hsh[row[3]] = [rank, per_100k]

            hsh
          end
          prev_year = current_year
        end
      end # end of txtfiles.each

      csv.close
    end
  end


end
