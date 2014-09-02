#GPCTweetSearch

search twitter and load results into tableview

### To install

From the command line

```code
$ git clone https://github.com/grahamito/GPCTweetSearch.git
$ cd GPCTweetSearch
$ pod install
```

### To Open Xcode Project
From xcode, or in the Finder, open project workspace 
```objectivec
Peek Buzz.xcworkspace
```

### Debugging using NSLogger
- If you don't have it, Download  pre-built version of the NSLogger desktop viewer for OS X.
https://www.dropbox.com/s/zt1eyfgymc9fbak/NSLogger-1.2.zip

- Setup your Mac OS username in NSLogger Desktop Viewer
Preferneces -> Network. Fill in the Bonjour Service Name, with the name of the account you are logged into on your Mac

## Current Status

### Basic status
- Initial Authorization, and Fetch from Twitter works
- Tweets are loaded into tableview
- Refresh works by performing the fetch again
- Paging appears to be working, but results are much fewer than when using twitter mac os x program, so maybe our app is using wrong params or the wrong twitter API. Or maybe it's this already detected problem: "API v1.1 search/tweets truncating/limiting results.": https://dev.twitter.com/discussions/22571
- ios7 only (not ios6)
- (No retweet)
- For testing, searches for "@BarackObama" (very frequent new tweets)

## Other issues

-Check we don’t need a separate managedObjectContext for inserts. Seems to work fine, i think because we are using UIManagedDocument to setup the managedObjectContext, and that has two managedObjectContexts built into it.

- Needs check for memory management
Check for memory leaks

## Suggested Improvements

- Only get tweets we don't already have stored in local db. The App stores retrieved tweets in core data db, so, on startup, we don't need to re-get thesed previously stored tweets from twitter api.

- For refresh, send the since_id to twitter. We can get this from the refresh_url that is returned by twitter 
"refresh_url" = "?since_id=505207116643061761&q=%40cnn&result_type=%40recent";

- Do bulk insert into coredata, instead of inserting a row at a time. 


 
## Basic algorithm

Based on photomania from Stanford Ios programming course http://web.stanford.edu/class/cs193p/cgi-bin/drupal/
This algorithm had to be adapted to work with twitter api, and to do paging of gets (cursoring).

In particular the project uses CoreDataTableViewController which is a subclass of UITableViewController, that incorporates Apple's recommendations on how to use coredata with a UITableview.
 
 ```objectivec
 Fires off a block on a queue to to get authorization for twitter.
 
  When authorized,  getTweet asynchronously ,
       they are returned in an array of tweet dictionaries
 
  The tweet dictionaries are loaded into Core Data by posting a block to do so on
    self.managedObjectContexts proper queue (using performBlock:).
 
  Data is loaded into Core Data by calling tweetWithApiObject:inManagedObjectContext: category method.
 ```
 
##  Paging

 The data from twitter includes meta_data which contains next_results
 ```objectivec
 "next_results" = "?max_id=505206494791356415&q=%40cnn&result_type=%40recent";
 program extracts max_id from this, and passes it back to twitter on subsequent calls. 
 ```

## Loading of images
 
 Done asynchronously with third party library SDWebImage
 
## Insert into coredata

 Done naively. 
 
 ```objectivec
 loop through array of tweet Dicts returned from twitter fetch
 for each tweet
  see if it exists already in coredata
  if it doesnt
   insert it
  ``` 

## Sample Data Received from Twitter Api:

 see https://dev.twitter.com/docs/api/1.1/get/search/tweets
 
## Parameters sent to twitter

 
```objectivec
twitter params: {
 count = 15;
 "include_entities" = false;
 q = "@peek";
 "result_type" = "@recent";
 }
 ```
 
## search_metadata Dictionary Returned From Twitter

 ```objectivec
 search_metadata: {
 "completed_in" = "0.023";
 count = 15;
 "max_id" = 505207116643061761;
 "max_id_str" = 505207116643061761;
 "next_results" = "?max_id=505206494791356415&q=%40cnn&result_type=%40recent";
 query = "%40cnn";
 "refresh_url" = "?since_id=505207116643061761&q=%40cnn&result_type=%40recent";
 "since_id" = 0;
 "since_id_str" = 0;
 }
 ```
 
