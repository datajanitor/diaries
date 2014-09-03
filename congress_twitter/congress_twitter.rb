# congress_twitter.rb

require 'yaml'
require 'fileutils'
require 'open-uri'
require 'twitter'

module CongressTwitter

  PROCESSED_DATA_DIR = File.expand_path('../data-hold/processed', __FILE__)
  RAW_DATA_DIR = File.expand_path('../data-hold/raw', __FILE__)
  FileUtils.mkdir_p(PROCESSED_DATA_DIR)
  FileUtils.mkdir_p(RAW_DATA_DIR)

  module Fetching
    CONGRESS_SOCIAL_YAML_URL = 'https://raw.githubusercontent.com/unitedstates/congress-legislators/master/legislators-social-media.yaml'
    CONGRESS_CURRENT_INFO_YAML_URL = 'https://github.com/unitedstates/congress-legislators/raw/master/legislators-current.yaml'

    class << self
      def fetch_sunlight_data(overwrite = false)
        [CONGRESS_SOCIAL_YAML_URL, CONGRESS_CURRENT_INFO_YAML_URL].each do |url|
          puts "Fetching #{url}..."
          fname = File.join(RAW_DATA_DIR, File.basename(url))
          unless File.exists?(fname) && overwrite == true
            open(fname, 'w'){|f| f.write(open(url){|u| u.read })}
          end
        end
      end

      # instantiates an authorized Twitter client
      # expects ./.credentials.yml to exist
      def init_client(cred_path = File.expand_path('./.credentials.yml'))

      end

      # fetches and saves the entire timeline for a given screen_name
      def fetch_user_timeline(screen_name, opts = {})
        # TODO ~ client.user_timeline(screen_name)
        save_raw_data("tweets/#{screen_name}.json", tweets)
      end

      # fetches and saves a batch of user_profiles
      def fetch_user_profiles(screen_names)
        Array(screen_names).each_slice(100) do |batch|
          init_client.users(batch).each do |profile|
            # TODO ~ client.users(snames)
            profiles.each do |profile|
              save_raw_data("profiles/#{p['screen_name']}.json", profile)
            end
          end
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
end
