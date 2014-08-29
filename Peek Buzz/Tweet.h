//
//  Tweet.h
//  Peek Buzz
//
//  Created by Graham Conway on 8/27/14.
//  Copyright (c) 2014 Graham Conway. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Tweet : NSManagedObject

@property (nonatomic, retain) NSNumber * tweetId;
@property (nonatomic, retain) NSString * tweetIdString;
@property (nonatomic, retain) NSString * tweetText;
@property (nonatomic, retain) NSString * decodedTweetText;
@property (nonatomic, retain) NSString * twitterScreenName;
@property (nonatomic, retain) NSString * tweetRealName;
@property (nonatomic, retain) NSString * profileImageUrlString;

@end
