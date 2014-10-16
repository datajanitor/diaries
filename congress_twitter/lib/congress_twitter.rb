# congress_twitter.rb
require 'pathname'
require 'yaml'
require 'json'
require 'fileutils'
require 'open-uri'
require 'twitter'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/hash/slice'
require 'pathname'
module CongressTwitter
  DATA_DIR = Pathname.new File.expand_path( '../../data-hold', __FILE__)
  CONGRESS_SOCIAL_YAML_URL = 'https://raw.githubusercontent.com/unitedstates/congress-legislators/master/legislators-social-media.yaml'
  CONGRESS_SOCIAL_YAML = DATA_DIR.join('fetched', File.basename(CONGRESS_SOCIAL_YAML_URL))
  CONGRESS_CURRENT_INFO_YAML_URL = 'https://github.com/unitedstates/congress-legislators/raw/master/legislators-current.yaml'
  CONGRESS_CURRENT_INFO_YAML = DATA_DIR.join('fetched', File.basename(CONGRESS_CURRENT_INFO_YAML_URL))

  class << self
    def setup!
      %w(fetched unpacked munged).each do |dname|
        DATA_DIR.join(dname).mkpath
      end
    end

    def fetch!
      puts "Fetching congressmember data"
      Fetching.fetch_congressmember_data
      puts "Fetching twitter profiles"
      Fetching.fetch_congress_twitter_profiles
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

  module Fetching
    class << self
      def fetch_congressmember_data
        open(CONGRESS_SOCIAL_YAML, 'w'){|f| f.write(open(CONGRESS_SOCIAL_YAML_URL){|u| u.read })}
        open(CONGRESS_CURRENT_INFO_YAML, 'w'){|f| f.write(open(CONGRESS_CURRENT_INFO_YAML_URL){|u| u.read })}
      end

      # Using the social media YAML listing, fetch user profiles from twitter
      # and save to disk
      # ...
      # expects legislators-social-media.yaml to have been downloaded
      def fetch_congress_twitter_profiles
        # initialize the raw data directory
        dir = DATA_DIR.join 'fetched', 'profiles'
        dir.mkpath
        # Load up the social media yaml file as an array
        social_listings = YAML.load_file(CONGRESS_SOCIAL_YAML)
        # collect twitter names from the legislators who have them
        twitter_names = social_listings.collect{|x| x['social']['twitter'] unless x['social'].nil? }.compact
        # fetch from the API
        profiles = Twit.fetch_user_profiles(twitter_names)

        profiles.each do |profile|
          fname = dir.join "#{profile[:screen_name].downcase}.json"
          open(fname, 'w'){ |f| f.write JSON.pretty_generate profile }
        end
      end

      # Using the social media YAML listing, fetch user profiles from twitter
      # and save to disk
      # ...
      # expects legislators-social-media.yaml to have been downloaded
      def fetch_congress_tweets(overwrite = false)
        # initialize the raw tweets directory
        dir = DATA_DIR.join 'fetched', 'tweets'
        dir.mkpath
        # Load up the social media yaml file as an array
        social_listings = YAML.load_file(CONGRESS_SOCIAL_YAML)
        twitter_names = social_listings.collect{|x| x['social']['twitter'] unless x['social'].nil? }.compact
        twitter_names.each do |tname|
          fname = dir.join("#{tname.downcase}.json")
          puts fname
          if overwrite == true || !fname.exist?
            puts "Fetching #{tname} tweets..."
            begin
              tweets = Twit.fetch_full_user_timeline(tname)
            rescue => err
            # a common error will be Twitter::Error::NotFound
            # if errors bubble up from .fetch_full_user_timeline, we'll just
            # output to screen and move on
              puts err
            else
              open(fname, 'w'){ |f| f.write JSON.pretty_generate tweets }
            end
          end
        end
      end # get_congress_tweets
    end
  end # module Fetching


  module Unpacking # TODO
    class << self
      require 'csv'


      # converts json tweet collections to csvs
      def tweets_to_csvs
        tweets_dir = DATA_DIR.join 'unpacked', 'tweets'
        tweets_dir.mkpath
        header_names = %w(id user_id screen_name source created_at retweet_count favorite_count text in_reply_to_screen_name in_reply_to_status_id retweeted_status_id)
        # iterate for each tweets json...remember each json file contains multiple tweets
        Dir.glob(DATA_DIR.join( 'fetched', 'tweets', '*.json')).each do |jfile|
          screen_name = File.basename(jfile, '.json')
          puts "Converting tweets from: #{screen_name}"
          csv = CSV.open(tweets_dir.join("#{screen_name}.csv"), 'w', headers: true)
          csv << header_names
          # open and parse the tweets json
          tweets = JSON.parse(open(jfile){|f| f.read})
          tweets.each do |tweet|
            tweet['screen_name'] = screen_name
            # force string output from: "<a href=\"http://twitter.com\" rel=\"nofollow\">Twitter Web Client</a>"
            #  to: Twitter Web Client
            tweet['source'] = tweet['source'][/(?<=>).+?(?=<\/a>)/] || tweet['source']
            tweet['user_id'] = tweet['user']['id']
            # force string output from: "Mon Jul 09 22:04:23 +0000 2007"
            #  to: "2007-07-09 22:04:23 UTC"
            tweet['created_at'] = Time.parse(tweet['created_at']).utc.strftime('%F %T')
            if( rt = tweet['retweeted_status'] )
              tweet['retweeted_status_id'] = rt['id']
            end
            csv << tweet.slice(*header_names)
          end
          csv.close
        end
      end

      # simply take all existing tweet csvs and make a big file
      def concat_tweet_csvs
        output = open(DATA_DIR.join('unpacked', 'all-tweets.csv'), 'w')
        Dir.glob(DATA_DIR.join('unpacked', 'tweets', '*.csv')).each_with_index do |csv_name, idx|
          output.write open(csv_name){ |cf|
            cf.gets unless idx == 0  # all subsequent files, skip the header
            cf.read
          }
        end
        output.close
      end
    end

  end # module Unpacking


  module Munging
    class << self
      def make_csvs
        require 'csv'
        require 'yaml'
        make_congress_member_info_csv
        make_congress_social_info_csv
        make_congress_twitter_accounts_csv
        make_congress_tweets_csv
      end

      private
        def make_congress_member_info_csv
          data = YAML.load_file(CONGRESS_CURRENT_INFO_YAML)
          csv = CSV.open( DATA_DIR.join('munged', 'congress_member_info.csv'), 'w', headers: true)
          csv << %w(bioguide_id thomas_id govtrack_id opensecrets_id first_name middle_name last_name suffix nickname gender birthday current_role current_term_start current_term_end state party url address phone fax contact_form rss_url)

          data.each do |m|
            member = HashWithIndifferentAccess.new(m)
            puts member[:name][:official_full]
            h = HashWithIndifferentAccess.new({
              bioguide_id: member[:id][:bioguide],
              thomas_id: member[:id][:thomas],
              govtrack_id: member[:id][:govtrack],
              opensecrets_id: member[:id][:opensecrets],
              first_name: member[:name][:first],
              middle_name: member[:name][:middle],
              last_name: member[:name][:last],
              suffix_name: member[:name][:suffix],
              nickname: member[:name][:nickname],
              gender: member[:bio][:gender],
              birthday: member[:bio][:birthday],
            })

            cterm = member[:terms][0]
            h.merge!({
              current_role: cterm[:type],
              current_term_end: cterm[:end],
              current_term_start: cterm[:start],
              state: cterm[:state],
              party: cterm[:party],
              url: cterm[:url],
              address: cterm[:address],
              phone: cterm[:phone],
              fax: cterm[:fax],
              contact_form: cterm[:contact_form],
              rss_url: cterm[:rss_url]
            })

            csv << h
          end

          csv.close
          true
        end

        def make_congress_social_info_csv
          data = YAML.load_file(CONGRESS_SOCIAL_YAML)
          csv = CSV.open( DATA_DIR.join('munged', 'congress_social_info.csv'), 'w', headers: true)
          csv << %w(bioguide_id twitter_screen_name facebook_id youtube_id)

          data.each do |m|
            info = HashWithIndifferentAccess.new(m)
            csv << HashWithIndifferentAccess.new(
              bioguide_id: info[:id][:bioguide],
              twitter_screen_name: info[:social][:twitter],
              facebook_id: info[:social][:facebook_id],
              youtube_id: info[:social][:youtube_id]
            )
          end

          csv.close
          true
        end

        def make_congress_twitter_accounts_csv
         # combines json profiles to one flattened CSV file
          header_names = %w(id name screen_name location description url followers_count friends_count listed_count created_at favourites_count statuses_count utc_offset time_zone verified geo_enabled lang profile_image_url profile_background_image_url profile_background_color profile_link_color)
          csv = CSV.open(DATA_DIR.join('munged', 'congress_twitter_accounts.csv'), 'w', headers: true)
          csv << header_names
          # collect all the fetched profiles
          Dir.glob(DATA_DIR.join('fetched', 'profiles', '*.json')).each do |jfile|
            profile = JSON.parse(open(jfile){|f| f.read})
            # force string output from: "Mon Jul 09 22:04:23 +0000 2007"
            #  to: "2007-07-09 22:04:23 -0000"
            profile['created_at'] = Time.parse(profile['created_at']).utc.strftime('%F %T')
            csv << profile.slice(*header_names)
          end

          csv.close
          true
        end

        # simply does a concatenation of files
        def make_congress_tweets_csv
          tweet_csvs = Dir.glob( DATA_DIR.join( 'unpacked', 'tweets', '*.csv'))
          file = File.open(DATA_DIR.join('munged', 'congress_tweets.csv'), 'w', headers: true)
          tweet_csvs.each_with_index do |csv, idx|
            c = open(csv)
            c.gets unless idx == 0

            file.write c.read
          end
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
  end # module Twit
end
