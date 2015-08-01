# extra functions
# Run this after fetching/unpacking/munging:
# Produces:
# - gets friend info for every friends id
require 'csv'
require 'active_support/core_ext/hash/indifferent_access'
require_relative '../twit'
module CongressTwitter
  module Packaging
    # minimum number of follows to be included in the friend_profiles search
    MIN_FRIEND_COUNT = 10
    USER_ATTRIBUTES = %w(id name screen_name location description url followers_count friends_count listed_count created_at favourites_count statuses_count utc_offset time_zone verified geo_enabled lang profile_image_url profile_background_image_url profile_background_color profile_link_color)

    class << self
      # creates a CSV from a filtered list of friend_ids
      def friend_profiles
        friends = filter_friends
        profiles = gather_user_profiles_from_ids(friends.keys)
        profile_data = extract_user_object_attributes(profiles)
        CSV.open(DATA_DIR.join('packaged', 'congress-friends.csv'), 'w', headers: true) do |csv|
          csv << USER_ATTRIBUTES
          profile_data.each{ |p| csv << p }
        end
      end

      private
        # ids is an array of user ids. Will be coerced into integers via Integer()
        # returns an array of user Twitter::Profile as a batch
        # includes error handling for batch stuff
        # not actually robust...so don't try this with tens of thousands of things...
        def gather_user_profiles_from_ids(ids)
          ids = ids.map{|i| Integer(i) }
          profiles = []
          count = 0
          ids.each_slice(100) do |arr|
            count += 1
            puts "On count: #{count}"
            begin
              data = Twit.fetch_users_by_ids(arr)
            rescue Twitter::Error::TooManyRequests => err
              puts err
              puts "Sleeping for 30"
              sleep 30
              retry
            rescue Twitter::Error::NotFound => err
              puts err
              puts "moving on..."
            else
              profiles.concat(data)
              sleep 5
            end
          end

          return profiles
        end

        # users is an Array of Twitter profile objects
        # coerces them to Hash
        def extract_user_object_attributes(users)
          arr = users.inject([]) do |a, user|
            u = HashWithIndifferentAccess.new(user)
            a << u.slice(*USER_ATTRIBUTES)
          end

          return arr
        end

        # returns a hash of friend_ids => count in which count >= MIN_FRIEND_COUNT
        def filter_friends
          inname = DATA_DIR.join('unpacked', 'all-friends-ids.csv')
          rows = open(inname, 'r'){|i| i.readlines }
          hsh = rows.inject(Hash.new{|h, k| h[k] = 0}) do |h, row|
            uname, friend_id = row.strip.split(',')
            h[friend_id] += 1
            h
          end

          fhsh = hsh.select{|k, v| v >= MIN_FRIEND_COUNT }
        end
        # /filter_friends

        # quickie hack
        # expects fetched/friend_ids to have been populated
        # not currently used
        # def quickie_fetch_friends_by_ids
        #   require_relative './twit'

        #   dir = DATA_DIR.join 'fetched', 'friend_objects'
        #   dir.mkpath

        #   ids = `cat data-hold/fetched/friend_ids/*.txt`.split("\n").map{|s| s.to_i }.uniq
        #   puts "Total ids: #{ids.count}"
        #   already_gathered_ids = Dir.glob(dir.join('*.json')).map{|f| File.basename(f, '.json').to_i  }
        #   remaining_ids = ids - already_gathered_ids
        #   puts "Remaining ids: #{remaining_ids.count}"

        #   count=0
        #   remaining_ids.each_slice(100) do |arr|
        #     count += 1
        #     puts "On count: #{count}"
        #     begin
        #       users = Twit.fetch_users_by_ids(arr)
        #     rescue Twitter::Error::TooManyRequests => err
        #       puts err
        #       puts "Sleeping for 30"
        #       sleep 30
        #       retry
        #     rescue Twitter::Error::NotFound => err
        #       puts err
        #       puts "moving on..."
        #     else
        #       users.each do |u|
        #         id = u.id
        #         open(dir.join("#{id}.json"), 'w'){|f| f.write JSON.pretty_generate(u.to_h )}
        #       end
        #       sleep 10
        #     end
        #   end
        # end



    end
  end
end
