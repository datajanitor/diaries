require 'json'
require 'csv'
DATA_FILE = File.expand_path('../data-source/all.json', __FILE__)
CSV_FILE =  File.expand_path('../data-munged/all.csv', __FILE__)
USA_EXPS_CSV_FILE =  File.expand_path('../data-munged/usa-exports.csv', __FILE__)
USA_IMPS_CSV_FILE =  File.expand_path('../data-munged/usa-imports.csv', __FILE__)

csv = CSV.open(CSV_FILE, 'w')
usa_exp_csv = CSV.open(USA_EXPS_CSV_FILE, 'w')
usa_imp_csv = CSV.open(USA_IMPS_CSV_FILE, 'w')

timebins = JSON.parse(open(DATA_FILE){|f| f.read })['timeBins']

[csv, usa_exp_csv, usa_imp_csv ].each{ |c| c << %w(year importer category exporter value) }
timebins.each do |t|
  year = t['t']
  data = t['data']
  puts "#{year}: #{data.count} entries"
  data.each do |d|
    row = [year, d['i'], d['wc'], d['e'], d['v']]
    csv <<  row
    usa_exp_csv << row if d['e'] == 'United States'
    usa_imp_csv << row if d['i'] == 'United States'
  end
end

