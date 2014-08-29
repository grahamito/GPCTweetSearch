//
//  Tweet+Helpers.m
//  Peek Buzz
//
//  Created by Graham Conway on 8/27/14.
//  Copyright (c) 2014 Graham Conway. All rights reserved.
//

#import "Tweet+Helpers.h"
#import "GPCUtility.h"
#import "NSString+HTML.h"


@implementation Tweet (Helpers)


- (NSString *)biggerImageUrlString {
    
    if (self.profileImageUrlString) {
        return  [self.profileImageUrlString
                 stringByReplacingOccurrencesOfString:@"normal"
                 withString:@"bigger"];
    } else {
        return nil;
    }
}


- (NSURL *)profileImageURL
{
    if (self.profileImageUrlString) {
        return  [NSURL URLWithString:self.profileImageUrlString];
    }
    else {
        return nil;
    }
}

- (NSURL *)biggerImageURL
{
    if (self.biggerImageUrlString) {
        return  [NSURL URLWithString:self.biggerImageUrlString];
    }
    else {
        return nil;
    }
}


+ (Tweet *)tweetWithApiObject:(NSDictionary *)tweetDictionary
       inManagedObjectContext:(NSManagedObjectContext *)context
{
    Tweet *tweet = nil;

    //Twitter recommends reading string version of Tweet id from returned json:
    NSNumber *numericTweetId = [GPCUtility nsnumberFromLargeIntString:tweetDictionary[@"id_str"] ];
    
    // Build a fetch request to see if we can find this tweet in the database.
    // The "unique" attribute in a Tweet is Twitter's "id" which is guaranteed by Twitter to be unique.
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Tweet"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"tweetId" ascending:NO]];
    
    request.predicate = [NSPredicate predicateWithFormat:@"tweetId = %@", numericTweetId];
    
    
    // Execute the fetch
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    // Check what happened in the fetch
    if (!matches || ([matches count] > 1)) {  // nil means fetch failed; more than one impossible (unique!)
        // handle error
    } else if (![matches count]) { // none found, so let's create a Tweet for that Twitter tweet
        tweet = [NSEntityDescription insertNewObjectForEntityForName:@"Tweet" inManagedObjectContext:context];

        tweet.tweetId = numericTweetId;
        tweet.tweetIdString = [tweetDictionary[@"id_str"] description];
        tweet.tweetText = [tweetDictionary[@"text"] description];
        tweet.decodedTweetText = [tweet.tweetText stringByDecodingHTMLEntities];
        
        
        // valueForKeyPath: supports "dot notation" to look inside dictionaries at other dictionaries
        tweet.twitterScreenName = [[tweetDictionary valueForKeyPath:@"user.screen_name"] description];
        tweet.tweetRealName = [[tweetDictionary valueForKeyPath:@"user.name"] description];
        tweet.profileImageUrlString = [[tweetDictionary valueForKeyPath:@"user.profile_image_url"] description];
        

    } else { // found the Tweet, just return it from the list of matches (which there will only be one of)
        tweet = [matches lastObject];
    }
    return tweet;
}




@end
