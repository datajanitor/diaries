module CongressTwitter
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
          output.write(open(csv_name)) do |cf|
            cf.gets unless idx == 0  # all subsequent files, skip the header
            cf.read
          end
        end
        output.close
      end

      # Creates all-friends-ids.csv in which many-to-many relationship between
      # user id (congressmember) and friend_id is shown
      def concat_friend_ids
        output = open(DATA_DIR.join('unpacked', 'all-friends-ids.csv'), 'w')
        friendfiles = Dir.glob(DATA_DIR.join('fetched', 'friend_ids', '*.txt'))
        friendfiles.each do |fname|
          uname = File.basename(fname).split('.')[0]
          puts uname
          open(fname).readlines.each{ |l| output.write(l.prepend("#{uname},")) }
        end
        output.close
      end
    end

  end # module Unpacking
end
