#GPCTweetSearch

search twitter and load results into tableview

## To install
From command line

```code
git clone this project
in command line cd to project directory
$ pod install
```
 
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
 
