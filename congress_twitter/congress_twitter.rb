# congress_twitter.rb

require 'yaml'
require 'json'
require 'fileutils'
require 'open-uri'
require 'twitter'
require 'active_support/core_ext/hash/indifferent_access'
module CongressTwitter

  PROCESSED_DATA_DIR = File.expand_path('../data-hold/processed', __FILE__)
  RAW_DATA_DIR = File.expand_path('../data-hold/raw', __FILE__)
  FileUtils.mkdir_p(PROCESSED_DATA_DIR)
  FileUtils.mkdir_p(RAW_DATA_DIR)

  CONGRESS_SOCIAL_YAML_URL = 'https://raw.githubusercontent.com/unitedstates/congress-legislators/master/legislators-social-media.yaml'
  CONGRESS_CURRENT_INFO_YAML_URL = 'https://github.com/unitedstates/congress-legislators/raw/master/legislators-current.yaml'
  module Fetching
    class << self
      def get_sunlight_data(overwrite = false)
        [CONGRESS_SOCIAL_YAML_URL, CONGRESS_CURRENT_INFO_YAML_URL].each do |url|
          puts "Fetching #{url}..."
          fname = File.join(RAW_DATA_DIR, File.basename(url))
          unless File.exists?(fname) && overwrite == true
            open(fname, 'w'){|f| f.write(open(url){|u| u.read })}
          end
        end
      end

      # Using the social media YAML listing, fetch user profiles from twitter
      # and save to disk
      # ...
      # expects legislators-social-media.yaml to have been downloaded
      def get_congress_twitter_profiles
        social_listings = YAML.load_file(File.join(RAW_DATA_DIR, File.basename(CONGRESS_SOCIAL_YAML_URL)))
        twitter_names = social_listings.collect{|x| x['social']['twitter'] unless x['social'].nil? }.compact
        profiles = Twit.fetch_user_profiles(twitter_names)

        profiles.each{|profile| save_raw_data("twitter/profiles/#{profile[:screen_name]}.json", profile) }
      end

      # Using the social media YAML listing, fetch user profiles from twitter
      # and save to disk
      # ...
      # expects legislators-social-media.yaml to have been downloaded
      def get_congress_tweets
        social_listings = YAML.load_file(File.join(RAW_DATA_DIR, File.basename(CONGRESS_SOCIAL_YAML_URL)))
        twitter_names = social_listings.collect{|x| x['social']['twitter'] unless x['social'].nil? }.compact
        twitter_names.each do |tname|
          puts "Fetching #{tname} tweets..."
          tweets = Twit.fetch_full_user_timeline(tname)
          save_raw_data("twitter/tweets/#{tname}.json", JSON.pretty_generate(tweets))
        end
      end

      private
        # convenience method to save data locally
        def save_raw_data(base_fname, content)
          fname = File.join(RAW_DATA_DIR, base_fname)
          FileUtils.mkdir_p(File.dirname(fname))

          open(fname, 'w'){|f| f.write content }
        end

    end
  end

  # simple wrapper around Twitter gem
  module Twit
    MAX_TWEET_ID = (2**62) - 1
    TWITTER_500_ERRORS = [ Twitter::Error::InternalServerError,
                  Twitter::Error::BadGateway,
                  Twitter::Error::ServiceUnavailable,
                  Twitter::Error::GatewayTimeout]

    class << self
      # instantiates an authorized Twitter client
      # expects ./.credentials.yml to exist
      def init_client(cred_path = File.expand_path('./.credentials.yml'))
        creds = Array(YAML.load_file(cred_path))
        # the file could have one or more set of credentials, we just
        # randomly pick one
        cred = creds.shuffle.first
        Twitter::REST::Client.new do |config|
          config.consumer_key        = cred['consumer_key']
          config.consumer_secret     = cred['consumer_secret']
          config.access_token        = cred['access_token']
          config.access_token_secret = cred['access_token_secret']
        end
      end


      # fetches and saves the entire timeline for a given screen_name
      # https://dev.twitter.com/docs/api/1.1/get/statuses/user_timeline
      # Note: running this will
      def fetch_user_timeline(screen_name, options = {})
        opts = HashWithIndifferentAccess.new(options)
        # retrieve the default maximum of tweets
        opts[:count] ||= 200
        # cut out the profile object by default
        opts[:trim_user] = opts[:trim_user] == false ? false : true
        # include retweets by default
        opts[:include_rts] = opts[:include_rts] == false ? false : true
        # include replies by default
        opts[:exclude_replies] = opts[:exclude_replies] == true ? true : false
        # call the API
        tweets = init_client.user_timeline(screen_name, opts)

        return tweets.collect(&:to_h)
      end

      # fetch the maximum number of tweets allowed
      # pass in options[:retry] to handle rate limit errors
      def fetch_full_user_timeline(screen_name, options={})
        opts = HashWithIndifferentAccess.new(options)
        opts[:max_id] ||= MAX_TWEET_ID
        opts[:since_id] ||= 1
        retries = opts.delete(:retry) == false ? 0 : 2
        be_verbose = opts.delete(:verbose) == false ? false : true
        all_tweets = []
        while opts[:max_id] > opts[:since_id]
          puts "Tweets collected: #{all_tweets.count}; max_id: #{opts[:max_id]}" if be_verbose
          begin
            tweets = fetch_user_timeline(screen_name, opts).collect(&:to_h)
          rescue Twitter::Error::TooManyRequests => err
            if retries > 0
              retries -= 1
              sleep_time = err.rate_limit.reset_in + 1
              puts "Error: #{err}", "Sleeping for #{sleep_time}" if be_verbose
              sleep sleep_time
            else
              raise err
            end
          rescue => err
            if TWITTER_500_ERRORS.include?(err.class) && retries > 0
              retries -= 1
              # sleep for two minutes
              sleep_time = 120
              puts "Error: #{err}", "Sleeping for #{sleep_time}" if be_verbose
              sleep sleep_time
              retry
            else
              raise err
            end
          else
            if( t = tweets.last )
              all_tweets.concat tweets
              opts[:max_id] = t[:id] - 1
            else
              opts[:max_id] = 0 # this will break the loop
            end
          end
        end

        return all_tweets
      end

      # fetches a batch of user_profiles
      # https://dev.twitter.com/docs/api/1.1/get/users/lookup
      def fetch_user_profiles(*screen_names)
        arr = []
        Array(screen_names).each_slice(100) do |batch|
          profiles = init_client.users(batch)
          arr.concat profiles.collect(&:to_h)
        end

        return arr
      end


    end
  end
end
