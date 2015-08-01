# congress_twitter.rb
require 'pathname'
require 'yaml'
require 'json'
require 'pry'
require 'fileutils'
require 'open-uri'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/hash/slice'
require_relative 'congress_twitter/fetching'
require_relative 'congress_twitter/munging'
require_relative 'congress_twitter/unpacking'
require_relative 'congress_twitter/packaging'


module CongressTwitter
  DATA_DIR = Pathname.new File.expand_path( '../../data-hold', __FILE__)
  CONGRESS_SOCIAL_YAML_URL = 'https://raw.githubusercontent.com/unitedstates/congress-legislators/master/legislators-social-media.yaml'
  CONGRESS_SOCIAL_YAML = DATA_DIR.join('fetched', File.basename(CONGRESS_SOCIAL_YAML_URL))
  CONGRESS_CURRENT_INFO_YAML_URL = 'https://github.com/unitedstates/congress-legislators/raw/master/legislators-current.yaml'
  CONGRESS_CURRENT_INFO_YAML = DATA_DIR.join('fetched', File.basename(CONGRESS_CURRENT_INFO_YAML_URL))

  class << self
    def setup!
      %w(fetched unpacked munged packaged).each do |dname|
        DATA_DIR.join(dname).mkpath
      end
    end

    def fetch!
      DATA_DIR.join('dname').mkpath
      puts "Fetching congressmember data"
      Fetching.fetch_congressmember_data
      puts "Fetching twitter profiles"
      Fetching.fetch_congress_twitter_profiles
      puts "Fetching friend_ids"
      Fetching.fetch_congress_friend_ids
      puts "Fetching tweets"
      Fetching.fetch_congress_tweets
      nil
    end

    def unpack!
      puts "Unpacking tweets to csvs"
      Unpacking.tweets_to_csvs
      puts "Concatenating tweet csvs"
      Unpacking.concat_tweet_csvs

      nil
    end

    def munge!
      Munging.make_csvs
    end
  end
end
