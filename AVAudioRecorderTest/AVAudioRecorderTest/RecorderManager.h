//
//  RecorderManager.h
//  AVAudioRecorderTest
//
//  Created by Mac on 2016/11/8.
//  Copyright © 2016年 Mac. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "MemoModel.h"
#import "THLevelPair.h"

@protocol RecorderManagerDelegate <NSObject>

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag;
- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error;
- (void)audioRecorderBeginInterruption:(AVAudioRecorder *)recorder;
- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder withOptions:(NSUInteger)flags;

@end

typedef void (^RecordingSaveCompletionHandler) (BOOL isSuccess, id message);
typedef void (^RecorderManagerResponer) (BOOL ret);

@interface RecorderManager : NSObject

@property (nonatomic, weak) id <RecorderManagerDelegate>delegate;
@property (nonatomic, assign) NSTimeInterval currentRecordedDuration;

+ (instancetype)shareRecorderManger;

- (void)startRecord:(RecorderManagerResponer)responder;
- (void)pauseRecord;
- (void)stopRecord;

- (void)saveRecordingWithFileName:(NSString *)fileName completionHandler:(RecordingSaveCompletionHandler)completionHandler;
- (void)playbackWithModel:(MemoModel *)model;
- (THLevelPair *)levels;

@end
