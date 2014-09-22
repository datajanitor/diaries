require 'json'
require 'csv'
DATA_FILE = File.expand_path('../data-source/all.json', __FILE__)
CSV_FILE =  File.expand_path('../data-munged/all.csv', __FILE__)


timebins = JSON.parse(open(DATA_FILE){|f| f.read })['timeBins']
CSV.open(CSV_FILE, 'w') do |csv|
  csv << %w(year importer category exporter value)

  timebins.each do |t|
    year = t['t']
    data = t['data']
    puts "#{year}: #{data.count} entries"

    data.each{|d| csv << [year, d['i'], d['wc'], d['e'], d['v']] }
  end
end
