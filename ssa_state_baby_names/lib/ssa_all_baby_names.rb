# just drafting out some things
require 'pathname'
require 'csv'
csv = CSV.open('all-compiled-names.csv', 'w', headers: true)
csv << [:year, :name, :sex, :count, :count_change, :count_per_100k, :count_per_100k_change, :rank, :rank_change]

files = Pathname.new File.expand_path("../../data-hold/names/*.txt", __FILE__)
prev_year = {}
Dir.glob(files).each do |file|
  puts file
  rows = open(file){|f| f.readlines.map{|r| r.strip.split(',').tap{|s| s[2] = s[2].to_i } }  }
  year = File.basename(file)[/\d{4}/]
  total_babies = rows.reduce(0){ |s,x| s += x[2] }
  prev_name = nil
  c_rank = 0
  this_year = {}

  rows.each do |row|
    h = {:year => year}
    h[:name], h[:sex], h[:count] = row
    h[:count_per_100k] = (100000.0 * h[:count] / total_babies).round
    c_rank += 1 if prev_name.nil? || prev_name[:count] > h[:count]
    h[:rank] = c_rank
    if (x = prev_year[[h[:name], h[:sex]]])
      h[:rank_change] = x[:rank] - h[:rank]
      h[:count_change] = h[:count] - x[:count]
      h[:count_per_100k_change] = h[:count_per_100k] - x[:count_per_100k]
    else
      h[:rank_change] = h[:count_change] = h[:count_per_100k_change] = 0
    end

    csv << h
    prev_name = h
    this_year[[h[:name], h[:sex]]] = h
  end
  prev_year = this_year
  this_year = {}
end

csv.close
