//
//  MyLevelMeterView.h
//  AVAudioRecorderTest
//
//  Created by Mac on 2016/11/15.
//  Copyright © 2016年 Mac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "THLevelPair.h"

@interface MyLevelMeterView : UIView

@property (nonatomic) CGFloat level;
@property (nonatomic) CGFloat peakLevel;

- (void)resetLevelMeter;

@end
