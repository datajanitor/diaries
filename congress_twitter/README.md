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
- `.get_congress_tweets` iterates through the social-media list for twitter screen_names and then does a batch fetch of tweets _per_ screen_name, retrieving the maximum number of tweets allowed. Inevitably, you'll hit the rate limit, so the script will by default go to sleep when necessary (15 minutes at a time)

