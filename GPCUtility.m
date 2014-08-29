//
//  GPCUtility.m
//  Peek Buzz
//
//  Created by Graham Conway on 8/24/14.
//  Copyright (c) 2014 Graham Conway. All rights reserved.
//

#import "GPCUtility.h"

@implementation GPCUtility

+ (void)showAlertViewWithTitle:(NSString *)title
                       message:(NSString *)message
{
    
    // jump to main queue for user interface stuff.
    [[NSOperationQueue mainQueue] addOperationWithBlock:^
     {
         UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:title
                                                            message:message
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
         [alertView show];
         alertView = nil;
         
     }];
    
}


+ (NSNumber *)nsnumberFromLargeIntString:(NSString *)inputString
{
    if (!inputString) {
        [self showAlertViewWithTitle:@"Error gpcNSNumberFromStringContainingBigInt: "
         "null string passed to nsnumber for string"
                             message:@"In gpcNSNumberFromStringContainingBigInt"];
        
        NSLog(@"**** nsnumberFromString: null string passed to nsnumber for string"
              "An input string of nil was passed to the routine that"
              "converts strings to numbers");
        return nil;
    }
    
    NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
    [f setNumberStyle:NSNumberFormatterNoStyle];
    // will return nil if invalid format
    NSNumber *nsNum = [f numberFromString:inputString];
    
    if (!nsNum) {
        [self showAlertViewWithTitle:@"Error gpcNSNumberFromStringContainingBigInt: "
         
                             message:@"In gpcNSNumberFromStringContainingBigInt"
         "invalid format see log"];
        NSLog(@"Error gpcNSNumberFromStringContainingVeryLargeInt: Invalid num format %@", inputString);
    }
    //    NSLog(@"nsnum from string: %@, numeric equivalent: %@", inputString, nsNum );
    
    return nsNum;
}

@end
