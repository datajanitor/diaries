module CongressTwitter
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
end
