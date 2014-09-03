# Congress Twitter Bulk Download

Using the Sunlight Foundation's [updated social-media list](https://github.com/unitedstates/congress-legislators/blob/master/legislators-social-media.yaml), we can batch download legislators' profiles and [up to their last 3,200 tweets](https://dev.twitter.com/docs/api/1.1/get/statuses/user_timeline), as per the Twitter API limitations.

## Requirements

- Ruby 2.x
- The [twitter](https://github.com/sferik/twitter) gem
- Creating a Twitter developer account and an app, which will get you the authentication keys needed to access the API.

The script expects `./credentials.yaml` to exist. Look at `sample.credentials.yaml` for an example.


## Description


- `.get_sunlight_data` retrieves the current legislator boilerplate and social media information from the [unitedstates/congress-legislators Github project](https://github.com/unitedstates/congress-legislators)
- `.get_congress_twitter_profiles` iterates through the social-media list for twitter screen_names and fetches them from Twitter
- `.get_congress_tweets` iterates through the social-media list for twitter screen_names and then does a batch fetch of tweets _per_ screen_name, retrieving the maximum number of tweets allowed. Inevitably, you'll hit the rate limit, so the script will by default go to sleep when necessary (15 minutes at a time).
 
  Sample output: 
  
        Fetching RobWittman tweets...
        Tweets collected: 0; max_id: 4611686018427387903
        Tweets collected: 200; max_id: 438424773300092927
        Tweets collected: 398; max_id: 390125033223225343
        Tweets collected: 596; max_id: 337241051859390464
        Tweets collected: 791; max_id: 291316681958096895
        Tweets collected: 988; max_id: 215065096416792575
        Tweets collected: 1187; max_id: 182220989986381823
        Tweets collected: 1386; max_id: 146662509074587647
        Tweets collected: 1586; max_id: 113708873973641216
        Tweets collected: 1786; max_id: 83214510843887615
        Tweets collected: 1986; max_id: 67667609130237951
        Tweets collected: 2185; max_id: 48470145391280127
        Tweets collected: 2385; max_id: 30123729715462143
        Tweets collected: 2583; max_id: 26487993574
        Tweets collected: 2782; max_id: 18360017911
        Error: Rate limit exceeded
        Sleeping for 763



