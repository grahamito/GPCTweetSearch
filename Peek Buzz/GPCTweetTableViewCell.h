//
//  GPCTweetTableViewCell.h
//  Peek Buzz
//
//  Created by Graham Conway on 9/2/14.
//  Copyright (c) 2014 Graham Conway. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GPCTweetTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *tweetUserImageView;
@property (weak, nonatomic) IBOutlet UILabel *userTwitterNameLabel;

@property (weak, nonatomic) IBOutlet UILabel *tweetTextLabel;

@end
