# congress_twitter.rb
require 'pathname'
require 'yaml'
require 'json'
require 'pry'
require 'fileutils'
require 'open-uri'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/hash/slice'
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
        require_relative './twit'
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


      # quickie hack
      # expects fetched/friend_ids to have been populated
      def quickie_fetch_friends_by_ids
        require_relative './twit'

        dir = DATA_DIR.join 'fetched', 'friend_objects'
        dir.mkpath

        ids = `cat data-hold/fetched/friend_ids/*.txt`.split("\n").map{|s| s.to_i }.uniq
        puts "Total ids: #{ids.count}"
        already_gathered_ids = Dir.glob(dir.join('*.json')).map{|f| File.basename(f, '.json').to_i  }
        remaining_ids = ids - already_gathered_ids
        puts "Remaining ids: #{remaining_ids.count}"

        count=0
        remaining_ids.each_slice(100) do |arr|
          count += 1
          puts "On count: #{count}"
          begin
            users = Twit.fetch_users_by_ids(arr)
          rescue Twitter::Error::TooManyRequests => err
            puts err
            puts "Sleeping for 30"
            sleep 30
            retry
          rescue Twitter::Error::NotFound => err
            puts err
            puts "moving on..."
          else
            users.each do |u|
              id = u.id
              open(dir.join("#{id}.json"), 'w'){|f| f.write JSON.pretty_generate(u.to_h )}
            end
            sleep 10
          end
        end
      end



      def fetch_congress_friend_ids(overwrite = false)
        require_relative './twit'
        # initialize the raw tweets directory
        dir = DATA_DIR.join 'fetched', 'friend_ids'
        dir.mkpath
        # Load up the social media yaml file as an array
        social_listings = YAML.load_file(CONGRESS_SOCIAL_YAML)
        twitter_names = social_listings.collect{|x| x['social']['twitter'] unless x['social'].nil? }.compact
        twitter_names.each do |tname|
          fname = dir.join("#{tname.downcase}.txt")
          puts fname
          if overwrite == true || !fname.exist?
            puts "Fetching #{tname} friend ids..."
            begin
              ids = Twit.fetch_full_user_friend_ids(tname)
            rescue => err
            # a common error will be Twitter::Error::NotFound
            # if errors bubble up from .fetch_full_user_timeline, we'll just
            # output to screen and move on
              puts err
            else
              open(fname, 'w'){ |f| f.puts ids }
              sleep 2
            end
          end
        end

      end # end congress followings

      # Using the social media YAML listing, fetch user profiles from twitter
      # and save to disk
      # ...
      # expects legislators-social-media.yaml to have been downloaded
      def fetch_congress_tweets(overwrite = false)
        require_relative './twit'
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
        header_names = %w(id user_id screen_name source created_at retweet_count favorite_count text in_reply_to_screen_name in_reply_to_status_id retweeted_status_id retweeted_status_user_id retweeted_status_screen_name)
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
            # remove new lines
            tweet['text'] = tweet['text'].gsub(/\s/, ' ').strip
            # force string output from: "Mon Jul 09 22:04:23 +0000 2007"
            #  to: "2007-07-09 22:04:23 UTC"
            tweet['created_at'] = Time.parse(tweet['created_at']).utc.strftime('%F %T')
            if( rt = tweet['retweeted_status'] )
              tweet['retweeted_status_id'] = rt['id']
              tweet['retweeted_status_user_id'] = rt['user']['id']
              tweet['retweeted_status_screen_name'] = tweet['text'][/(?<=^RT @)\w+(?=:)/]
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
        make_congress_terms_csv
        make_congress_social_info_csv
        make_congress_twitter_accounts_csv
        make_congress_tweets_csv

        true
      end

      def quickie_extract_friend_object_attributes
        obj_dir = DATA_DIR.join 'fetched', 'friend_objects'
        files = Dir.glob(obj_dir.join '*.json')
        arr = []
        atts = %w(name screen_name id followers_count friends_count statuses_count listed_count verified description url)
        files.each do |f|
          j = JSON.parse(open(f){|g| g.read})
          arr << atts.inject({}){|h, a| h[a] = j[a]; h }
        end

        fname = DATA_DIR.join('munged', 'friend_objects_extract.json')
        open(fname, 'w'){ |f|  f.write arr.to_json}
      end

      private
        def make_congress_member_info_csv
          data = YAML.load_file(CONGRESS_CURRENT_INFO_YAML)
          csv = CSV.open( DATA_DIR.join('munged', 'congress_member_info.csv'), 'w', headers: true)
          csv << %w(bioguide_id thomas_id govtrack_id opensecrets_id first_name middle_name last_name suffix nickname gender birthday current_role current_term_start current_term_end state party district senate_class state_rank url address phone fax contact_form rss_url)

          data.each do |m|
            member = HashWithIndifferentAccess.new(m)
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

            cterm = member[:terms].sort_by{|t| t[:start] }.reverse[0]
            h.merge!({
              current_role: cterm[:type],
              current_term_end: cterm[:end],
              current_term_start: cterm[:start],
              district: cterm[:district],
              senate_class: cterm[:class],
              state: cterm[:state],
              state_rank: cterm[:state_rank],
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

        def make_congress_terms_csv
          data = YAML.load_file(CONGRESS_CURRENT_INFO_YAML)
          csv = CSV.open( DATA_DIR.join('munged', 'congress_terms.csv'), 'w', headers: true)
          csv << %w(bioguide_id end start state role party district senate_class state_rank)
          data.each do |m|
            member = HashWithIndifferentAccess.new(m)
            b_id = member[:id][:bioguide]
            member[:terms].each do |cterm|
              t = HashWithIndifferentAccess.new(
                    bioguide_id: b_id,
                    role: cterm[:type],
                    end: cterm[:end],
                    start: cterm[:start],
                    district: cterm[:district],
                    senator_class: cterm[:class],
                    state: cterm[:state],
                    state_rank: cterm[:state_rank],
                    party: cterm[:party]
                  )
              csv << t
            end
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
end
