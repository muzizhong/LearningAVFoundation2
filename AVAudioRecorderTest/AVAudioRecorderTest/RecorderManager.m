//
//  RecorderManager.m
//  AVAudioRecorderTest
//
//  Created by Mac on 2016/11/8.
//  Copyright © 2016年 Mac. All rights reserved.
//

#import "RecorderManager.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
//#import <AVFoundation/AVAudioSettings.h>

/*
     AVAudioRecorder 和 AVAudioPlayer 一样都是构建与 Audio Queue Services 之上
 
     属性	说明
         @property(readonly, getter=isRecording) BOOL recording;	是否正在录音，只读
         @property(readonly) NSURL *url	录音文件地址，只读
         @property(readonly) NSDictionary *settings	录音文件设置，只读
         @property(readonly) NSTimeInterval currentTime	录音时长，只读，注意仅仅在录音状态可用
         @property(readonly) NSTimeInterval deviceCurrentTime	输入当前设备的时间，只读，注意此属性一直可访问
         @property(getter=isMeteringEnabled) BOOL meteringEnabled;	是否启用录音测量，如果启用录音测量可以获得录音分贝等数据信息
         @property(nonatomic, copy) NSArray *channelAssignments	当前录音的通道
     
     对象方法	说明
         - (instancetype)initWithURL:(NSURL *)url settings:(NSDictionary *)settings error:(NSError **)outError	录音机对象初始化方法，注意其中的url必须是本地文件url，settings是录音格式、编码等设置
         - (BOOL)prepareToRecord	准备录音，主要用于创建缓冲区，如果不手动调用，在调用record录音时也会自动调用
         - (BOOL)record	开始录音
         - (BOOL)recordAtTime:(NSTimeInterval)time	在指定的时间开始录音，一般用于录音暂停再恢复录音
         - (BOOL)recordForDuration:(NSTimeInterval) duration	按指定的时长开始录音
         - (BOOL)recordAtTime:(NSTimeInterval)time forDuration:(NSTimeInterval) duration	在指定的时间开始录音，并指定录音时长
         - (void)pause;	暂停录音
         - (void)stop;	停止录音
         - (BOOL)deleteRecording;	删除录音，注意要删除录音此时录音机必须处于停止状态
         - (void)updateMeters;	更新测量数据，注意只有meteringEnabled为YES此方法才可用
         - (float)peakPowerForChannel:(NSUInteger)channelNumber;	指定通道的测量峰值，注意只有调用完updateMeters才有值
         - (float)averagePowerForChannel:(NSUInteger)channelNumber	指定通道的测量平均值，注意只有调用完updateMeters才有值
     
     代理方法	说明
         - (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag	完成录音
         - (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error	录音编码发生错误
     
     AVAudioRecorder创建录音机时除了指定路径外还必须指定录音设置信息，因为录音机必须知道录音文件的格式、采样率、通道数、每个采样点的位数等信息，通常只需要几个常用设置。关于录音设置详见帮助文档中的“AV Foundation Audio Settings Constants”。
 */
#define DefaultRecordingCacheDirectory @"RecordingCacheDirectory"
#define DefaultRecordingDirectory @"RecordingDirectory"
#define DefaultRecordingFileName  @"voice.caf"

#define AlertOpenMicrophoneTag 1000

@interface RecorderManager () <AVAudioRecorderDelegate, UIAlertViewDelegate>
@property (strong, nonatomic) AVAudioRecorder *recorder;
@property (strong, nonatomic) AVAudioPlayer *player;

@property (assign, nonatomic) NSTimeInterval recordingDuration;

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
        [self initRecorder];
    }
    return self;
}

- (void)initRecorder {
    
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
    
    /* 
     fileURLWithPath: 和 URLWithString: 区别
     
         通过URL加载本地数据，使用方法
            NSURL *fileURL = [NSURL fileURLWithPath: path];
         
         通过URL加载远程服务器，使用方法
            NSURL *fileURL = [NSURL URLWithString: path];
     eg: 
     
     NSString *str = @"http://t3.qpic.cn/mblogpic/d05a8de7423b76095d7c/460";
     NSURL *url1 = [NSURL fileURLWithPath: str];
     NSURL *url2 = [NSURL URLWithString: str];
     NSLog(@"url1=%@",url1);
     NSLog(@"url2=%@",url2);
     
     输出结果为：
     url1=http:/t3.qpic.cn/mblogpic/d05a8de7423b76095d7c/460 -- file://localhost/
     url2=http://t3.qpic.cn/mblogpic/d05a8de7423b76095d7c/460
     
     我们可以通过上面的输出结果可知，fileURLWithPath是将str转化为文件路径，可以自动的去掉“/”。而URLWithString紧紧是将url2转化成NSURL类型，对于它的内容没有任何的改变。
     */
    
    NSURL *url = [NSURL fileURLWithPath:[self cacheRecorderFile]];
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
        self.recorder.meteringEnabled = YES; //表示可以测量
        [self.recorder prepareToRecord];
    } else {
        NSLog(@"error: %@", error.localizedDescription);
    }
}

- (void)saveRecordingWithFileName:(NSString *)fileName completionHandler:(RecordingSaveCompletionHandler)completionHandler {
    NSInteger timestamp = [NSDate timeIntervalSinceReferenceDate];
    NSString *fn = [NSString stringWithFormat:@"%@_%ld.m4a", fileName, timestamp];
    
    NSURL *desURL = [NSURL fileURLWithPath: [self recorderFilePathWithFileName:fn]];
    NSURL *srcURL = self.recorder.url;
    
    NSError *error;
    BOOL isSuccess = [[NSFileManager defaultManager] copyItemAtURL:srcURL toURL:desURL error:&error];
    if (isSuccess) {
        NSLog(@"success");
        if (completionHandler) {
            
#warning //1 获取录音时长失败 ,所以先用 //2
            NSTimeInterval recordingDuration = 0.0f;
#if 0   
            //1
            AVURLAsset *recordingAsset = [AVURLAsset URLAssetWithURL:desURL options:nil];
            CMTime recordingDurationCMT = recordingAsset.duration;
            float recordingDuration = CMTimeGetSeconds(recordingDurationCMT);
#else
            //2
            recordingDuration = self.recordingDuration;
#endif
            completionHandler(YES, [MemoModel initWithTitle:fileName pathExtension:fn duration:recordingDuration]);
        }
        [self.recorder prepareToRecord]; //更新缓存
    } else {
        NSLog(@"error: %@", error.localizedDescription);
        if (completionHandler) {
            completionHandler(NO, error.localizedDescription);
        }
    }
}

- (NSTimeInterval)currentRecordedDuration {
    return self.recorder.currentTime;
}

#pragma mark - RecordingFile Cache Path

+ (NSString *)cacheRootPath {
    return NSTemporaryDirectory();
}

+ (NSString *)cacheRecorderDirectory {
    NSString *path = [[self cacheRootPath] stringByAppendingPathComponent:DefaultRecordingCacheDirectory];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![self fileExists:path]) {
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return path;
}

- (NSString *)cacheRecorderFile {
    return [[RecorderManager cacheRecorderDirectory] stringByAppendingPathComponent:DefaultRecordingFileName];
}

+ (NSString *)cacheRecorderFile {
    return [[self cacheRecorderDirectory] stringByAppendingPathComponent:DefaultRecordingFileName];
}

#pragma mark - RecordingFile Saved Path

+ (NSString *)rootPath {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
}

+ (NSString *)recorderDirectory {
    NSString *path = [[self rootPath] stringByAppendingPathComponent:DefaultRecordingDirectory];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![self fileExists:path]) {
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return path;
}

+ (NSString *)recorderFilePathWithFileName:(NSString *)fileName {
    return [[self recorderDirectory] stringByAppendingPathComponent:fileName];
}

- (NSString *)recorderFilePathWithFileName:(NSString *)fileName {
    return [[RecorderManager recorderDirectory] stringByAppendingPathComponent:fileName];
}

+ (BOOL)fileExists:(NSString *)file {
    BOOL exists = NO;
    if (file && [file isKindOfClass:[NSString class]] && ![file isEqualToString:@""]) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        exists = [fileManager fileExistsAtPath:file];
    }
    return exists;
}

#pragma mak - Record Methods

- (void)startRecord:(RecorderManagerResponer)responder {
    if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)]) {
        [[AVAudioSession sharedInstance] performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
            if (responder) {
                responder(granted);
            }
            
            if (granted) {
                [self.recorder record];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                                    message:NSLocalizedString(@"please change setting that allow Videoshow to use Microphone", nil)
                                                                   delegate:self
                                                          cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                                          otherButtonTitles:NSLocalizedString(@"Setting", nil), nil];
                    alert.tag = AlertOpenMicrophoneTag;
                    [alert show];
                });
            }
        }];
    }
}

- (void)pauseRecord {
    [self.recorder pause];
}

- (void)stopRecord {
    self.recordingDuration = [self currentRecordedDuration];
    [self.recorder stop];
}

- (void)playbackWithModel:(MemoModel *)model {
    [self.player stop];
    self.player = nil;
    
    NSError *error;
    NSURL *url = [NSURL fileURLWithPath:[self recorderFilePathWithFileName:model.pathExtension]];
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    if (self.player) {
        [self.player play];
        NSLog(@"%d, duration: %f", self.player.isPlaying, self.player.duration);
    } else {
        NSLog(@"error: %@", error.localizedDescription);
    }
}

#pragma mark - AlertViewDelegate 

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex==0) {//取消
        
        if (alertView.tag == AlertOpenMicrophoneTag) {
            
        }
        
    } else if(buttonIndex==1) {//确定
        if (alertView.tag == AlertOpenMicrophoneTag) {
            NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            if ([[UIApplication sharedApplication] canOpenURL:url]) {
                [[UIApplication sharedApplication] openURL:url];
            }
        }
    }
    [alertView removeFromSuperview];
    alertView = nil;
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
