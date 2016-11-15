//
//  ViewController.m
//  AVAudioRecorderTest
//
//  Created by Mac on 2016/11/8.
//  Copyright © 2016年 Mac. All rights reserved.
//

#import "ViewController.h"
#import "RecorderManager.h"
#import "RecordingMessageTableViewCell.h"
#import "MemoModel.h"
#import "MyLevelMeterView.h"


#define MEMOS_ARCHIVE @"memos.archive"
#define CELLID        @"RecordingMessageTableViewCell"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource, RecorderManagerDelegate>
@property (strong, nonatomic) RecorderManager *recorderManager;

@property (weak, nonatomic) IBOutlet UILabel *timeLB;
@property (weak, nonatomic) IBOutlet UIButton *recordBtn;
@property (weak, nonatomic) IBOutlet UIButton *stopBtn;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *memos;

@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) CADisplayLink *levelTimer;
@property (weak, nonatomic) IBOutlet MyLevelMeterView *levelMeterView;

@end

@implementation ViewController

- (void)dealloc {
    [self stopTimer];
    [self stopMeterTimer];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.stopBtn.enabled = NO;
    self.tableView.tableFooterView = [[UIView alloc] init];
}

#pragma mark - Events

- (IBAction)record:(UIButton *)sender {
    
    __weak typeof(self) selfWeak = self;
    [self.recorderManager startRecord:^(BOOL ret) {
        if (ret) {
            selfWeak.stopBtn.enabled = YES;
            selfWeak.recordBtn.enabled = YES;
            selfWeak.recordBtn.selected = !selfWeak.recordBtn.selected;
            
            if (selfWeak.recordBtn.selected) {
                [selfWeak.timer setFireDate:[NSDate distantPast]];
                [self startMeterTimer];
            } else {
                [selfWeak.recorderManager pauseRecord];
                [selfWeak.timer setFireDate:[NSDate distantFuture]];
                [self stopMeterTimer];
            }
        }
    }];
}

- (IBAction)stopRecording:(UIButton *)sender {
    
    self.recordBtn.selected = NO;
    self.recordBtn.enabled = NO;
    self.stopBtn.enabled = NO;

    [self.recorderManager stopRecord];
    [self stopTimer];
    [self stopMeterTimer];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Save Recording" message:@"Please provide a name" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
#warning NSLocalizedString(@"My Recording", @"Login")
        textField.placeholder = NSLocalizedString(@"My Recording", @"Login");
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"cancel");
    }];
    
    __weak typeof(self) selfWeak = self;
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"ok");
        
        NSString *fileName = [alertController.textFields.firstObject text];
        [selfWeak.recorderManager saveRecordingWithFileName:fileName completionHandler:^(BOOL isSuccess, id message) {
            
            if (isSuccess) {
                [selfWeak.memos addObject:message];
                [selfWeak saveMemos];
                [selfWeak.tableView reloadData];
            } else {
                NSLog(@"message: %@", message);
            }
        }];
    }];
    
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    
    [self presentViewController:alertController animated:YES completion:^{
        selfWeak.recordBtn.enabled = YES;
        //selfWeak.recordBtn.selected = NO;
        selfWeak.stopBtn.enabled = NO;
        
        selfWeak.timeLB.text = @"00:00:00";
    }];
}

- (void)saveMemos {
    NSData *fileData = [NSKeyedArchiver archivedDataWithRootObject:self.memos];
    [fileData writeToURL:[self archieveURL] atomically:YES];
}

#pragma mark - Timer

- (void)updateRecordingDuration:(NSTimer *)timer {
    //
    self.timeLB.text = [self stringWithTime:[self.recorderManager currentRecordedDuration]];
}

- (void)updateLevel:(CADisplayLink *)timer {
    //
    THLevelPair *pair = [self.recorderManager levels];
    self.levelMeterView.level = pair.level;
    self.levelMeterView.peakLevel = pair.peakLevel;
    [self.levelMeterView setNeedsDisplay];
}

- (void)stopTimer {
    [_timer invalidate];
    _timer = nil;
}

- (void)startMeterTimer {
    [self.levelTimer invalidate];
    
    self.levelTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateLevel:)];
    self.levelTimer.frameInterval = 5;
    [self.levelTimer addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)stopMeterTimer {
    [self.levelTimer invalidate];
    self.levelTimer = nil;
    [self.levelMeterView resetLevelMeter];
}

- (NSString *)stringWithTime:(NSTimeInterval)time {
    NSInteger currentRecordedDuration = time;
    
    NSInteger hours = (currentRecordedDuration / 3600);
    NSInteger minutes = (currentRecordedDuration / 60) % 60;
    NSInteger seconds = (currentRecordedDuration % 60);
    
    return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", hours, minutes, seconds];
}

#pragma mark - RecorderMangerDelegate

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    NSLog(@"success");
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error {
    NSLog(@"error: %@", error.localizedDescription);
}

- (void)audioRecorderBeginInterruption:(AVAudioRecorder *)recorder {
    NSLog(@"interruption begin");
    [self.recorderManager stopRecord];
    
    self.recordBtn.selected = NO;
    self.recordBtn.enabled = NO;
    self.stopBtn.enabled = NO;
    
    [self.timer setFireDate:[NSDate distantFuture]];
}

- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder withOptions:(NSUInteger)flags {
    NSLog(@"interruption end");
    if (flags == AVAudioSessionInterruptionOptionShouldResume) {
        [self record:nil];
    }
}

#pragma mark - UITableView Delegate 

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.memos.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RecordingMessageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CELLID];
    MemoModel *model = self.memos[indexPath.row];
    cell.titleLB.text = model.title;
    cell.durationLB.text = [self stringWithTime:model.duration];
    cell.dateLB.text = model.dateString;
    cell.timeLB.text = model.timeString;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.recorderManager playbackWithModel:self.memos[indexPath.row]];
}

#pragma mark - Member Vars

- (RecorderManager *)recorderManager {
    if (!_recorderManager) {
        _recorderManager = [RecorderManager shareRecorderManger];
        _recorderManager.delegate = self;
    }
    return _recorderManager;
}

- (NSMutableArray *)memos {
    if (!_memos) {
        _memos = [NSMutableArray array];
        
        NSData *data = [NSData dataWithContentsOfURL:[self archieveURL]];
        if (data) {
            [_memos addObjectsFromArray:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
        }
    }
    return _memos;
}

- (NSTimer *)timer {
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(updateRecordingDuration:) userInfo:nil repeats:YES];
        _timer.fireDate = [NSDate distantFuture];
    }
    return _timer;
}

- (NSURL *)archieveURL {
    NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *archievePath = [docsDir stringByAppendingPathComponent:MEMOS_ARCHIVE];
    return [NSURL fileURLWithPath:archievePath];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
