//
//  RecorderManager.m
//  AVAudioRecorderTest
//
//  Created by Mac on 2016/11/8.
//  Copyright © 2016年 Mac. All rights reserved.
//

#import "RecorderManager.h"
#import <AVFoundation/AVFoundation.h>
//#import <AVFoundation/AVAudioSettings.h>

/*
    AVAudioRecorder 和 AVAudioPlayer 一样都是构建与 Audio Queue Services 之上
 */

#define DefaultRecorderFileName @"voice.caf"

@interface RecorderManager () <AVAudioRecorderDelegate> 
@property (strong, nonatomic) AVAudioRecorder *recorder;
@property (strong, nonatomic) AVAudioPlayer *player;
@end

@implementation RecorderManager

+ (instancetype)shareRecorderManger {
    static id share = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        if (!share) {
            share = [[self alloc] init];
        }
    });
    return share;
}

- (instancetype)init {
    if (self = [super init]) {
        
    }
    return self;
}

+ (NSString *)rootPath {
    return NSTemporaryDirectory();
}

+ (NSString *)recorderDirectory {
    NSString *path = [[self rootPath] stringByAppendingString:@"RecorderDirectory"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![self fileExists:path]) {
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return path;
}

- (NSString *)recorderFile {
    return [[RecorderManager recorderDirectory] stringByAppendingString:DefaultRecorderFileName];
}

+ (NSString *)recorderFile {
    return [[self recorderDirectory] stringByAppendingString:DefaultRecorderFileName];
}

+ (BOOL)fileExists:(NSString *)file {
    BOOL exists = NO;
    if (file && [file isKindOfClass:[NSString class]] && ![file isEqualToString:@""]) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        exists = [fileManager fileExistsAtPath:file];
    }
    return exists;
}

- (void)initRecorder {
    
    NSURL *url = [NSURL URLWithString:[self recorderFile]];
    /*
     AVFormatIDKey //定义了写入内容的音频格式
         kAudioFormatLinearPCM      // 将未压缩的音频流写入到文件中，这种格式的保真度最好，不过相应的文件也最大。
         kAudioFormatMPEG4AAC       // 会显著缩小文件，还能保证高质量的音频内容
         kAudioFormatAppleIMA4      // 会显著缩小文件，还能保证高质量的音频内容
         kAudioFormatAppleLossless
         kAudioFormatiLBC
         kAudioFormatULaw
         
         Note:
             所指定的音频格式一定要和URL参数定义的文件类型兼容；否则会报错，打印error.localizedDescription：
             The operator couldn't be completed. (OSStatus error 1718449215.)
             1718449215 是4字节编码的整数值，'fmt?': 指定了一种不兼容的音频格式。
     
     AVSampleRateKey //定义了录音器的采样率(采样率定义了对输入的模拟音频信号每一秒内的采样数)
         使用低采样率(eg: 8kHz)会导致粗粒度、AM广播类型的录制效果，不过文件会比较小；
         使用44.1kHz的采样率(CD质量的采样率)会得到非常高质量的内容，不过文件就比较大；
         对于使用多少采样率最好，没有一个明确的定义，不过开发者应该尽量使用标准的采样率，eg：8000、16000、22050、44100。最终是我们的耳朵在进行判断。
     
     
     AVNumberOfChannelsKey //定义了记录音频内容的通道数
         指定默认值 1 意味着使用单声道录制，设置 2 意味着使用立体声录制。除非使用外部硬件进行录制，否则通常应该创建单声道录音。
     
     AVEncoderBitDepthHintKey //编码时候的采样位数 值从 8-32
     
     AVEncoderAudioQualityKey //编码质量
     
         typedef NS_ENUM(NSInteger, AVAudioQuality) {
             AVAudioQualityMin    = 0,
             AVAudioQualityLow    = 0x20,
             AVAudioQualityMedium = 0x40,
             AVAudioQualityHigh   = 0x60,
             AVAudioQualityMax    = 0x7F
         };
     
     处理Linear PCM 或 压缩音频格式时，可以定义一些其他指定格式的键。可在Xcode帮助文档中的AV Fondation Audio Settings Constants引用中找到完整的列表。
     */
    
    NSDictionary *sets = @{ AVFormatIDKey : @(kAudioFormatAppleIMA4),
                            AVSampleRateKey : @(44100.0f),
                            AVNumberOfChannelsKey : @(1),
                            AVEncoderBitDepthHintKey : @(16),
                            AVEncoderAudioQualityKey : @(AVAudioQualityMedium)
                           };
    NSError *error;
    self.recorder = [[AVAudioRecorder alloc] initWithURL:url settings:sets error:&error];
    if (self.recorder) {
        self.recorder.delegate = self;
        [self.recorder prepareToRecord];
    } else {
        NSLog(@"error: %@", error.localizedDescription);
    }
}

- (void)createRecorder {
    
}

#pragma mak - Record Methods

- (void)startRecord {
    
}

- (void)pauseRecord {
    
}

- (void)stopRecord {
    
}

- (void)playRecordWithPath:(NSString *)recordPath {
    
}

- (void)playRecord {
    
}

- (void)pausePlayRecord {
    
}

- (void)stopPlayRecord {
    
}

#pragma mark - AVAudioRecorderDelegate

/* audioRecorderDidFinishRecording:successfully: is called when a recording has been finished or stopped. This method is NOT called if the recorder is stopped due to an interruption. */
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    
}

/* if an error occurs while encoding it will be reported to the delegate. */
- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError * __nullable)error {
    
}

/* AVAudioRecorder INTERRUPTION NOTIFICATIONS ARE DEPRECATED - Use AVAudioSession instead. */

/* audioRecorderBeginInterruption: is called when the audio session has been interrupted while the recorder was recording. The recorded file will be closed. */
- (void)audioRecorderBeginInterruption:(AVAudioRecorder *)recorder {

}

/* audioRecorderEndInterruption:withOptions: is called when the audio session interruption has ended and this recorder had been interrupted while recording. */
/* Currently the only flag is AVAudioSessionInterruptionFlags_ShouldResume. */
- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder withOptions:(NSUInteger)flags {

}

- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder withFlags:(NSUInteger)flags {

}

/* audioRecorderEndInterruption: is called when the preferred method, audioRecorderEndInterruption:withFlags:, is not implemented. */
- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder {
    
}

@end
