//
//  RecorderManager.h
//  AVAudioRecorderTest
//
//  Created by Mac on 2016/11/8.
//  Copyright © 2016年 Mac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MemoModel.h"

typedef void (^RecordingSaveCompletionHandler) (BOOL isSuccess, id message);
typedef void (^RecorderManagerResponer) (BOOL ret);

@interface RecorderManager : NSObject

@property (nonatomic, assign) NSTimeInterval currentRecordedDuration;

+ (instancetype)shareRecorderManger;

- (void)startRecord:(RecorderManagerResponer)responder;
- (void)pauseRecord;
- (void)stopRecord;

- (void)saveRecordingWithFileName:(NSString *)fileName completionHandler:(RecordingSaveCompletionHandler)completionHandler;
- (void)playbackWithModel:(MemoModel *)model;

@end
