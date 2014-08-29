//
//  GPCUtility.h
//  Peek Buzz
//
//  Created by Graham Conway on 8/24/14.
//  Copyright (c) 2014 Graham Conway. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GPCUtility : NSObject
+ (void)showAlertViewWithTitle:(NSString *)title
                       message:(NSString *)message;

//****
//
// @returns  NSNumber, or nil if it can't convert
//
//***
+ (NSNumber *)nsnumberFromLargeIntString:(NSString *)inputString;

@end
