module CongressTwitter
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
