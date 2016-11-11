//
//  MemoModel.m
//  AVAudioRecorderTest
//
//  Created by Mac on 2016/11/10.
//  Copyright © 2016年 Mac. All rights reserved.
//

#import "MemoModel.h"

#define TITLE_KEY       @"title"
#define PATH_EXTENSION  @"pathExtension"
#define DATE_STRING_KEY @"dateString"
#define TIME_STRING_KEY @"timeString"
#define DURATION_KEY    @"duration"

@interface MemoModel ()

@property (copy, nonatomic, readwrite) NSString *title;
@property (copy, nonatomic, readwrite) NSString *pathExtension;
@property (copy, nonatomic, readwrite) NSString *dateString;
@property (copy, nonatomic, readwrite) NSString *timeString;
@property (assign, nonatomic, readwrite) NSTimeInterval duration;

@end

@implementation MemoModel

+ (instancetype)initWithTitle:(NSString *)title pathExtension:(NSString *)pathExtension duration:(NSTimeInterval)duration {
    return [[self alloc] initWithTitle:title pathExtension:pathExtension duration:duration];
}

- (instancetype)initWithTitle:(NSString *)title pathExtension:(NSString *)pathExtension duration:(NSTimeInterval)duration {
    if (self = [super init]) {
        
        _title = [title copy];
        _pathExtension = [pathExtension copy];
        
        NSDate *date = [NSDate date];
        _dateString = [self dateStringWithDate:date];
        _timeString = [self timeStringWithDate:date];
        
        _duration = duration;
    }
    return self;
}

- (NSString *)dateStringWithDate:(NSDate *)date {
    NSDateFormatter *formatter = [self formatterWithFormat:@"MMddyyyy"];
    return [formatter stringFromDate:date];
}

- (NSString *)timeStringWithDate:(NSDate *)date {
    NSDateFormatter *formatter = [self formatterWithFormat:@"HHmmss"];
    return [formatter stringFromDate:date];
}

- (NSDateFormatter *)formatterWithFormat:(NSString *)template {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:[NSLocale currentLocale]]; //获取当前设备语言环境，不过默认也是这样的，除非我们只显示为某一种语言的环境，才要单另设置
    NSString *format = [NSDateFormatter dateFormatFromTemplate:template options:0 locale:[NSLocale currentLocale]];
    [formatter setDateFormat:format];
    return formatter;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.title forKey:TITLE_KEY];
    [aCoder encodeObject:self.pathExtension forKey:PATH_EXTENSION];
    [aCoder encodeObject:self.dateString forKey:DATE_STRING_KEY];
    [aCoder encodeObject:self.timeString forKey:TIME_STRING_KEY];
    [aCoder encodeDouble:self.duration forKey:DURATION_KEY];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        _title = [aDecoder decodeObjectForKey:TITLE_KEY];
        _pathExtension = [aDecoder decodeObjectForKey:PATH_EXTENSION];
        _dateString = [aDecoder decodeObjectForKey:DATE_STRING_KEY];
        _timeString = [aDecoder decodeObjectForKey:TIME_STRING_KEY];
        _duration = [aDecoder decodeDoubleForKey:DURATION_KEY];
    }
    return self;
}


@end
