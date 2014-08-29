//
//  Tweet+Helpers.h
//  Peek Buzz
//
//  Created by Graham Conway on 8/27/14.
//  Copyright (c) 2014 Graham Conway. All rights reserved.
//

#import "Tweet.h"

@interface Tweet (Helpers)

@property (nonatomic, readonly) NSString *biggerImageUrlString;
@property (nonatomic, readonly) NSURL *biggerImageURL;
@property (nonatomic,readonly) NSURL *profileImageURL;



// Creates a Tweet in the database for a given Tweet Dict  (if necessary).

+ (Tweet *)tweetWithApiObject:(NSDictionary *)tweetDictionary
       inManagedObjectContext:(NSManagedObjectContext *)context;


@end
