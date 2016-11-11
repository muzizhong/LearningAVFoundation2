//
//  RecordingMessageTableViewCell.h
//  AVAudioRecorderTest
//
//  Created by Mac on 2016/11/10.
//  Copyright © 2016年 Mac. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RecordingMessageTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLB;
@property (weak, nonatomic) IBOutlet UILabel *dateLB;
@property (weak, nonatomic) IBOutlet UILabel *timeLB;
@property (weak, nonatomic) IBOutlet UILabel *durationLB;

@end
