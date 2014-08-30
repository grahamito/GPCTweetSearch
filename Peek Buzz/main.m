//
//  main.m
//  Peek Buzz
//
//  Created by Graham Conway on 8/22/14.
//  Copyright (c) 2014 Graham Conway. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPCAppDelegate.h"

// Start Logging for NSLogger msgs
// See https://github.com/fpillet/NSLogger#podfile

#import <NSLogger/NSLogger.h>

int main(int argc, char * argv[])
{
    LoggerStartForBuildUser();
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([GPCAppDelegate class]));
    }
}
