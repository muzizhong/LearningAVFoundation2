//
//  MemoModel.h
//  AVAudioRecorderTest
//
//  Created by Mac on 2016/11/10.
//  Copyright © 2016年 Mac. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MemoModel : NSObject <NSCoding>

@property (copy, nonatomic, readonly) NSString *title;
@property (copy, nonatomic, readonly) NSString *pathExtension;
@property (copy, nonatomic, readonly) NSString *dateString;
@property (copy, nonatomic, readonly) NSString *timeString;
@property (assign, nonatomic, readonly) NSTimeInterval duration;

+ (instancetype)initWithTitle:(NSString *)title pathExtension:(NSString *)pathExtension duration:(NSTimeInterval)duration;

@end
