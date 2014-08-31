//
//  GPCTwitterAccountManager.h
//  Peek Buzz
//
//  Created by Graham Conway on 8/23/14.
//  Copyright (c) 2014 Graham Conway. All rights reserved.
//

#import "GPCTwitterAccountManager.h"
#import <Accounts/Accounts.h>
#import <NSLogger/NSLogger.h>



/* Twitter result_type from api doc: https://dev.twitter.com/docs/api/1.1/get/search/tweets
 Optional. Specifies what type of search results you would prefer to receive. The current default is "mixed." Valid values include:
* mixed: Include both popular and real time results in the response.
* recent: return only the most recent results in the response
* popular: return only the most popular results in the response.

Example Values: mixed, recent, popular *?

Mixed seems to work ok, even though there was an issue reported by twitter:
 
 Twitter Issue #1208: Search API: Count param does not work when result type is set to mixed.
 https://dev.twitter.com/issues/1208
*/
static NSString *const kGPCResult_type = @"@mixed";
//static NSString *const kGPCResult_type = @"@recent";
//static NSString *const kGPCResult_type = @"@mixed";


@interface GPCTwitterAccountManager  () {

}

// Private write version of
@property (atomic, assign) TwitterAuthorizationStatus twitterAuthorizationStatus;
@property (nonatomic, strong) ACAccountStore *accountStore;

@end



@implementation GPCTwitterAccountManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        _twitterAuthorizationStatus = Unknown;
    }
    return self;
}

//+ (GPCTwitterAccountManager *)sharedInstance {
//	static GPCTwitterAccountManager *sharedInstance = nil;
//	static dispatch_once_t onceToken;
//	
//	dispatch_once(&onceToken, ^{
//		sharedInstance = [[GPCTwitterAccountManager alloc] init];
//	});
//	
//	return sharedInstance;
//}


//- (void)authTwitter {
//}


- (void)authTwitterWithSuccess:(void (^)())successBlock
{
    [self authTwitterWithCompletion:^(TwitterAuthorizationStatus authorizationStatus) {
        if (authorizationStatus == Authorized) {
            successBlock();
        }
    }];
}

- (void)authTwitterWithCompletion:(void (^)(TwitterAuthorizationStatus authorizationStatus))requestCompletion
{
    self.accountStore = [[ACAccountStore alloc] init];
    ACAccountType *twitterAccountType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [self.accountStore requestAccessToAccountsWithType:twitterAccountType
                                          options:nil
                                       completion:^(BOOL granted, NSError *error)
     {
         // (This completion handler is executed on an arbitrary queue)
         
         TwitterAuthorizationStatus twitterAuthorizationStatus = Unknown;
         NSArray *accounts = [self.accountStore accountsWithAccountType:twitterAccountType];
         
         if (!granted) {
             if (error) {
                 // the user has no system account
                 twitterAuthorizationStatus = UserNeedsToSetup;
                 
             } else {
                 //the user has a system account but denied access to this app
                 twitterAuthorizationStatus = UserDeniedAccessToThisApp;
             }
         }
         else  {
             // granted == True
             if (!accounts || ([accounts count] == 0)) {
                 twitterAuthorizationStatus = UserNeedsToSetup;
             
             } else {
                 twitterAuthorizationStatus = Authorized;
                 self.twitterAccount = [accounts firstObject];
                 /*If you wish to see the username of the account being used uncomment out the next line of code
                 */
                 LoggerView(1, @"Username: %@", self.twitterAccount.username);
             }
         }
         // update instance variable and pass status to completionblock
         self.twitterAuthorizationStatus = twitterAuthorizationStatus;
         
         requestCompletion(twitterAuthorizationStatus);
     }];
}

/****
* example api call:
* https://api.twitter.com/1.1/search/tweets.json?q=%40peek&result_type=mixed&count=15&include_entities=false
**/

- (SLRequest *)requestForSearchString:(NSString *)searchString
                     tweetsPerRequest:(NSInteger)tweetsPerRequest
                          olderThanId:(NSNumber *)maxTweetId;
{
    LoggerView(1, @"request for search string maxTweetId = %@", maxTweetId);
    NSURL *timelineURL = [NSURL URLWithString:@"https://api.twitter.com/1.1/search/tweets.json"];
    
    NSString *tweetsPerRequestString = [NSString stringWithFormat:@"%ld",(long)tweetsPerRequest];
    NSMutableDictionary *twitterParams = [@{@"count": tweetsPerRequestString,
                                           @"q": searchString,
                                           @"result_type": kGPCResult_type,
                                            @"include_entities": @"false"} mutableCopy];
    
    // if asking to return tweets older (> = ) maxTweetId: add max_id to params
    if (maxTweetId) {
        NSString *maxTweetsIdString = [maxTweetId stringValue];
//        [NSString stringWithFormat:@"%ld",(long)maxTweetId];
        LoggerView(1, @"maxTweetId Param string %@", maxTweetsIdString);
        twitterParams[@"max_id"] = maxTweetsIdString;
    }
    
    LoggerView(1, @"twitter params: %@", twitterParams);
    
    // Create a request
    SLRequest *twitterGetRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                      requestMethod:SLRequestMethodGET
                                                                URL:timelineURL
                                                         parameters:twitterParams];
    // Set the account for the request
    [twitterGetRequest setAccount:self.twitterAccount];
    
    return twitterGetRequest;
}




@end
