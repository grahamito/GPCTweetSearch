#GPCTweetSearch

search twitter and load results into tableview

## To install

### From command line

```code
$ git clone https://github.com/grahamito/GPCTweetSearch.git
$ cd GPCTweetSearch
$ pod install
```
### From xcode or in Finder

open project workspace 
```objectivec
Peek Buzz.xcworkspace
```

## Current Status

### Basic status
- Initial Authorization, and Fetch from Twitter works
- Tweets are loaded into tableview
- For debugging, cell currently shows tweetId instead of tweet Username
- Refresh works by performing the fetch again
- Paging has been coded but needs to be debugged
- ios7 only (not ios6)
- (No retweet)
- For testing, searches for "@BarackObama" (very frequent new tweets)

## Other issues
- Code to prevent simultaneous fetches needs to be debugged
- Image sizes in tableview display oddly need code to fix size, or change placeholder image

-Check we don’t need a separate managedObjectContext for inserts

(app uses  UIManagedDocument for core data)

####Needs check for memory management
- Check for memory leaks

####Memory management for blocks needs to be checked
-     may need __block and weak self     
-      in places where variables are updated within blocks 
 
## Basic algorithm

 
 ```objectivec
 Fires off a block on a queue to to get authorization for twitter.
 
  When authorized,  getTweet asynchronously ,
       they are returned in an array of tweet dictionaries
 
  The tweet dictionaries are loaded into Core Data by posting a block to do so on
    self.managedObjectContext's proper queue (using performBlock:).
 
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
 
