//
//  TweetCDTVC
//
// Main View Controller For App

/**
 see project readme.md file for notes on algorith
 ***/

#import "TweetCDTVC.h"

#import <NSLogger/NSLogger.h>
#import "GPCUtility.h"
#import "GPCTwitterAccountManager.h"
@import Social;     // Twitter and Facebook

// Custom uitableview cell
#import "GPCTweetTableViewCell.h"


#import <SDWebImage/UIImageView+WebCache.h> // async loading of images into tableview cells

// core data tweet class
#import "Tweet.h"
#import "Tweet+Helpers.h"

#pragma mark - Constants that define twitter search
//static NSString *const kPeekTwitterName = @"@peek";
static NSString *const kPeekTwitterName = @"@BarackObama";

// Number of tweets to ask for from Twitter API, max 100
static int const gpcTweetsPerTwitterRequest = 50;

//ask for next batch of tweets from twitter API when this number of rows left in UITableView
static NSUInteger gpckTableViewPrefetchAmount = (NSUInteger) gpcTweetsPerTwitterRequest / 2  ;

// size of fetch of coredata records from disk to memory
//static NSUInteger gpcCoreFetchDataBatchSize = (NSUInteger) gpcTweetsPerTwitterRequest;


#pragma mark - General Constants
static NSString * const kGPCManagedDocumentName = @"uiManagedDocument";
static NSString *const kCellIdentifier = @"tweetCell";
static NSString *const kStartIntakeSegueIdentifier = @"startIntakeSegue";


#pragma mark - Class Definition
@interface TweetCDTVC ()


// core data
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

// Twitter Api
@property (strong, nonatomic) GPCTwitterAccountManager *twitterAccountManager;
@property (nonatomic) BOOL twitterFetchInProgress;   //prevent simultaneous fetches

@property (nonatomic, strong) NSNumber *oldestTweetId;

@end


@implementation TweetCDTVC

#pragma mark - Property Getters and Setters

- (GPCTwitterAccountManager *)twitterAccountManager {
    if (!_twitterAccountManager) {
        _twitterAccountManager = [[GPCTwitterAccountManager alloc] init];
    }
    return _twitterAccountManager;
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    _managedObjectContext = managedObjectContext;
    if (managedObjectContext) {
        [self setupFetchResultsController];
        
    } else {
        self.fetchedResultsController = nil;
    }
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // prevent mutliple fetches
    self.twitterFetchInProgress = NO;
    
    // get notified when user returns to app:
    //maybe they authorized this app for twitter
    [self setupDidBecomeActiveNotification];
    
    //  sets the Refresh Control's target/action
    [self setupTableViewRefreshControl];
}

// Whenever the table is about to appear, if we have not yet opened/created or demo document, do so.

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!self.managedObjectContext) [self useDemoDocument];
}

- (void)dealloc
{
    [self removeDidBecomeActiveNotification];
}



#pragma mark - Core Data
// Either creates, opens or just uses the demo document
//
// Creating and opening are asynchronous, so in the completion handler we set our Model (managedObjectContext).

- (void)useDemoDocument
{
    NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    url = [url URLByAppendingPathComponent:kGPCManagedDocumentName];
    UIManagedDocument *document = [[UIManagedDocument alloc] initWithFileURL:url];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
        [document saveToURL:url
           forSaveOperation:UIDocumentSaveForCreating
          completionHandler:^(BOOL success) {
              if (success) {
                  self.managedObjectContext = document.managedObjectContext;
                  [self getFirstBatchOfTweetsFromServer];
              }
          }];
    } else if (document.documentState == UIDocumentStateClosed) {
        [document openWithCompletionHandler:^(BOOL success) {
            if (success) {
                self.managedObjectContext = document.managedObjectContext;
            }
        }];
    } else {
        self.managedObjectContext = document.managedObjectContext;
    }
}

// This is called in the setter of the managedObjectContext
//Create an NSFetchRequest to that get all Tweets in the database
// Then we hook that NSFetchRequest up to the table view using an NSFetchedResultsController.

- (void)setupFetchResultsController
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Tweet"];
    
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"tweetId" ascending:NO]];
    
    request.predicate = nil; // all Tweets
    
    // this is batching for the transfer from coredata file system to coredata memory
    // not quite sure how this affects the data returned. turn it off till further testing.
    //    [request setFetchBatchSize:gpcCoreFetchDataBatchSize];
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:self.managedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
}

#pragma mark - App Active Notification

//******
// App became active
//
// Maybe user has come back from settings screen, and authorized app to use twitter
//***********
- (void) appDidBecomeActive:(NSNotification*)notification
{
    // if the user hasn't yet been authorized. try authorization again.
    // get on main queue to do ui stuff (this might be called from off the main queue)
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.twitterAccountManager.twitterAuthorizationStatus != Authorized) {
            [self getFirstBatchOfTweetsFromServer];
        }
    });
}

- (void)setupDidBecomeActiveNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
}
- (void)removeDidBecomeActiveNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
}


#pragma mark - UIRefreshControl Action

/*
 override of superclass method
 */
- (void)coreDataTableviewRefreshAction:(id)sender
{
    // Reload logic
    [self getFirstBatchOfTweetsFromServer];
    
    //    [self.refreshControl endRefreshing];
    // (this is done by calling getFirstPageOfTweetsFromServer)
}


#pragma mark - Get Data from Twitter

// Get First tweets from twitter server
// load them into local database
//
- (IBAction)getFirstBatchOfTweetsFromServer
{
    [self authorizeAndGetTweetsContaining:kPeekTwitterName
                                withCount:gpcTweetsPerTwitterRequest
                              olderThanId:nil];
}

- (IBAction)getNextBatchOfTweetsFromServer
{
    [self authorizeAndGetTweetsContaining:kPeekTwitterName
                                withCount:gpcTweetsPerTwitterRequest
                              olderThanId:self.oldestTweetId];
}


/**
 * Get tweets from twitter server, load them into local database
 * @param searchName e.g.  @"@peek"
 * @param tweetsPerRequest maxNum of tweets to return from server
 * @param olderThanId - only return tweets equal or older than this tweetId, used for cursoring
 *
 * Fires off a block on a queue to to get authorization for twitter.
 *
 * When the authorized,  getTweet asynchronously ,
 *      they are returned in an array of tweet dictionaries
 *
 * The tweet dictionaries are loaded into Core Data by posting a block to do so on
 *   self.managedObjectContext's proper queue (using performBlock:).
 *
 * Data is loaded into Core Data by calling tweetWithApiObject:inManagedObjectContext: category method.
 **/

- (void)authorizeAndGetTweetsContaining:(NSString *)searchString
                              withCount:(NSInteger)tweetsPerRequest
                            olderThanId:(NSNumber *)maxTweetId
{
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.refreshControl beginRefreshing];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES; //not great
        
        self.twitterFetchInProgress = YES;
    });
    
    // get authority for this app to access twitter
    [self.twitterAccountManager authTwitterWithSuccess:^{
        
        // (This completion handler happens on arbitrary queue)
        LoggerApp(1, @"after call to auth: maxTweetId = %@", maxTweetId);
        
        /// Get a batch of tweets from twitter
        [self getTweetsContaining:searchString
                        withCount:(NSInteger)tweetsPerRequest
                      olderThanId:(NSNumber *)maxTweetId
                       completion:^(NSArray *tweetArray, NSDictionary *requestMetaData)
         {
             // save the id of the last tweet retreived from this request. (so we can pass it as param to next request)
             self.oldestTweetId = [self extractNextMaxIdFromQueryString:requestMetaData[@"next_results"]];
             
             // we have an array of tweets load them into coredata
             // start coredata operation from main queue
             
             dispatch_async(dispatch_get_main_queue(), ^{
                 
                 [self.managedObjectContext performBlock:^{
                     for (NSDictionary *tweet in tweetArray) {
                         
                         [Tweet tweetWithApiObject:tweet
                            inManagedObjectContext:self.managedObjectContext];
                     }
                     dispatch_async(dispatch_get_main_queue(), ^{
                         [self.managedObjectContext save:NULL];
                         
                         self.twitterFetchInProgress = NO;
                         [self.refreshControl endRefreshing];
                         [UIApplication sharedApplication].networkActivityIndicatorVisible = NO; // not great
                         
                     });
                 }];
             });
         }];
    }];
}

/**
 * Get tweets containing searchString from twitter server, if successful, return them as an array in completionblock
 *
 * @param searchString e.g.  @"@peek"
 * @param tweetsPerRequest maxNum of tweets to return from server
 * @param maxTweedId - only return tweets equal or older than this tweetId, (used for cursoring)
 * @param completion - results are passed to this
 *
 * Fires off a block on a queue to fetch data from Twitter.
 * When the data comes back, it is loaded into an array of Tweet Dicts
 *   self.managedObjectContext's proper queue (using performBlock:).
 * Data is loaded into Core Data by calling tweetWithApiObject:inManagedObjectContext: category method.
 **/
- (void)getTweetsContaining:(NSString *)searchString
                  withCount:(NSInteger)tweetsPerRequest
                olderThanId:(NSNumber *)maxTweetId
                 completion:(void (^)(NSArray *tweetArray, NSDictionary *requestMetaData))completion
{
    // (This could be on an arbitrary queue)
    LoggerView(1, @"getTweets, maxTweetId = %@", maxTweetId);
    // Create a request
    SLRequest *twitterGetRequest = [self.twitterAccountManager requestForSearchString:searchString
                                                                     tweetsPerRequest:tweetsPerRequest
                                                                          olderThanId:maxTweetId];
    // perform request
    [twitterGetRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
     {
         NSArray *arrayOfTweetDicts = nil;
         NSDictionary *searchMetaData = nil;
         
         if (!error) {
             NSDictionary *jsonResponseDict = [NSJSONSerialization JSONObjectWithData:responseData
                                                                              options:NSJSONReadingAllowFragments
                                                                                error:nil];
             // returns entries for two keys: search_metadata and statuses
             arrayOfTweetDicts = [jsonResponseDict valueForKeyPath:@"statuses"];
             searchMetaData = [jsonResponseDict valueForKeyPath:@"search_metadata"];
             
             //             LoggerView(1, @"twitterGetRequest: tweet Array: %@\nsearch_metadata: %@", arrayOfTweetDicts, searchMetaData  );
         }
         else {
             LoggerView(1, @"There was an error performing twitter request: %@", [error localizedDescription]);
         }
         completion(arrayOfTweetDicts, searchMetaData);
     }];
}


/**
 * Extract MaxId from next_results
 * sample input string:
 * "next_results" = "?max_id=505224929621843967&q=%40BarackObama&result_type=%40recent";
 *
 *  ;
 *
 *
 **/
- (NSNumber *)extractNextMaxIdFromQueryString:(NSString *)queryString
{
    LoggerView(1, @"extractNextMaxIdFromNextResultsUrl, nextResltsString = %@", queryString);
    
    if (!queryString) return nil;
    
    NSMutableDictionary *queryStringDictionary = [[NSMutableDictionary alloc] init];
    NSArray *urlComponents = [queryString componentsSeparatedByString:@"&"];
    
    for (NSString *keyValuePair in urlComponents)
    {
        NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
        NSString *rawKey = pairComponents[0];
        
        // remove  extra "?" char from front of string if it exists
        NSString *key = [self stripQuestionMarkFromFirstCharOfString:rawKey];
        NSString *value = [pairComponents objectAtIndex:1];
        
        [queryStringDictionary setObject:value forKey:key];
    }
    
    
    NSString *maxIdString = queryStringDictionary[@"max_id"];
    
    LoggerView(1, @"extractNextMaxIdFromNextResultsUrl, maxId = %@", maxIdString);
    
    if (maxIdString)  {
        return [GPCUtility nsnumberFromLargeIntString:maxIdString];
    }
    else {
        return nil;
    }
    
}


- (NSString *)stripQuestionMarkFromFirstCharOfString:(NSString *)inputString
{
    unichar firstChar = [inputString characterAtIndex:0];
    
    if (firstChar == '?') {
        // return rest of string after 1st character
        return [inputString substringFromIndex:1];
    }
    else {
        return inputString;
    }
    
}


#pragma mark - UITableViewDataSource

// Uses NSFetchedResultsController's objectAtIndexPath: to find the Tweet for this row in the table.
// Then uses that Tweet to set the cell up.

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    GPCTweetTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier forIndexPath:indexPath];
    
    Tweet *tweet = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    // update UILabels in the UITableViewCell
    cell.userTwitterNameLabel.text = [NSString stringWithFormat:@"@%@",tweet.twitterScreenName];
    cell.tweetTextLabel.text = tweet.tweetText;
    
    // for size of twitter profile images:
    //https://dev.twitter.com/docs/user-profile-images-and-banners
    // bigger = 73 x 73, 
    [cell.tweetUserImageView sd_setImageWithURL:tweet.biggerImageURL
                      placeholderImage:[UIImage imageNamed:@"placeholder.png"]];
    

    // check if we are near the end of the tableview
    // Get index of the  row in fetchResults controller
    NSInteger indexOfLastRowOfDataInSection = [[[self.fetchedResultsController sections] objectAtIndex:indexPath.section] numberOfObjects];
    NSInteger indexWhenToAskForMoreRows = indexOfLastRowOfDataInSection - gpckTableViewPrefetchAmount;
    
    LoggerView(1, @"tableview:currentIdx: %d lastrow = %ld, ask for more at %ld", indexPath.row, (long)indexOfLastRowOfDataInSection, (long)indexWhenToAskForMoreRows);
    
    // trigger fetch before we have displayed the last row that we have data for:
    if (indexPath.row  ==  indexWhenToAskForMoreRows) {
        [self getNextBatchOfTweetsFromServer];
    }
    return cell;
}


/***
 * Alternating the background color of cells
 *
 *
 * adapted from Apple example (added else clause to if 
 * statement)
 * https://developer.apple.com/library/ios/documentation/userexperience/conceptual/TableView_iPhone/TableViewCells/TableViewCells.html
 
 */
 
 - (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row%2 == 0) {

        cell.backgroundColor = [UIColor colorWithWhite:0.7 alpha:0.1];

    }
    else {
        cell.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
        
    }
    
}

#pragma mark - Navigation

// Gets the NSIndexPath of the UITableViewCell which is sender.
// Then uses that NSIndexPath to find the Tweet in question using NSFetchedResultsController.
// Prepares a destination view controller through the "setTweet:" segue by sending that to it.

#warning uncomment and correct when detail view done
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //    NSIndexPath *indexPath = nil;
    //
    //    if ([sender isKindOfClass:[UITableViewCell class]]) {
    //        indexPath = [self.tableView indexPathForCell:sender];
    //    }
    //
    //    if (indexPath) {
    //        if ([segue.identifier isEqualToString:@"setTweet:"]) {
    //            Tweet *tweet = [self.fetchedResultsController objectAtIndexPath:indexPath];
    //            if ([segue.destinationViewController respondsToSelector:@selector(setTweet:)]) {
    //                [segue.destinationViewController performSelector:@selector(setTweet:) withObject:tweet];
    //            }
    //        }
    //    }
}

@end
