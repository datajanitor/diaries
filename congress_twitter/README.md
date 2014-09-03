# Congress Twitter Bulk Download

Using the Sunlight Foundation's [updated social-media list](https://github.com/unitedstates/congress-legislators/blob/master/legislators-social-media.yaml), we can batch download legislators' profiles and [up to their last 3,200 tweets](https://dev.twitter.com/docs/api/1.1/get/statuses/user_timeline), as per the Twitter API limitations.

## Requirements

- Ruby 2.x
- The [twitter](https://github.com/sferik/twitter) gem
- Creating a Twitter developer account and an app, which will get you the authentication keys needed to access the API.


## Description

In the `CongressTwitter::Fetching` module:

- `.fetch_sunlight_data` retrieves the current legislator boilerplate and social media information from the [unitedstates/congress-legislators Github project](https://github.com/unitedstates/congress-legislators)
- `init_client` creates an instance of an authorized Twitter client, assuming that `./.credentials.yaml` exists

