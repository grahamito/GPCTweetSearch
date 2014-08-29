//
//  GPCTwitterAccountManager.h
//  Peek Buzz
//
//  Created by Graham Conway on 8/23/14.
//  Copyright (c) 2014 Graham Conway. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Accounts/Accounts.h>
@import Social;

typedef NS_ENUM(NSInteger, TwitterAuthorizationStatus)  {
    Authorized,
    UserNeedsToSetup,
    UserDeniedAccessToThisApp,
    Unknown
};

@interface GPCTwitterAccountManager : NSObject

@property (atomic, readonly) TwitterAuthorizationStatus twitterAuthorizationStatus;
@property (nonatomic, strong) ACAccount *twitterAccount;


- (void)authTwitterWithCompletion:(void (^)(TwitterAuthorizationStatus authorizationStatus))requestCompletion;

- (SLRequest *)requestForSearchString:(NSString *)searchString
                            tweetsPerRequest:(NSInteger)tweetsPerRequest
                                olderThanId:(NSNumber *)maxTweetId;


- (void)authTwitterWithSuccess:(void (^)())successBlock;

@end
