//
//  MyLevelMeterView.m
//  AVAudioRecorderTest
//
//  Created by Mac on 2016/11/15.
//  Copyright © 2016年 Mac. All rights reserved.
//

#import "MyLevelMeterView.h"

@interface THLevelMeterColorThreshold : NSObject

@property (nonatomic, readonly) CGFloat maxValue;
@property (nonatomic, strong, readonly) UIColor *color;
@property (nonatomic, copy, readonly) NSString *name;

+ (instancetype)colorThresholdWithMaxValue:(CGFloat)maxValue color:(UIColor *)color name:(NSString *)name;

@end

@implementation THLevelMeterColorThreshold

+ (instancetype)colorThresholdWithMaxValue:(CGFloat)maxValue color:(UIColor *)color name:(NSString *)name {
    return [[self alloc] initWithMaxValue:maxValue color:color name:name];
}

- (instancetype)initWithMaxValue:(CGFloat)maxValue color:(UIColor *)color name:(NSString *)name {
    self = [super init];
    if (self) {
        _maxValue = maxValue;
        _color = color;
        _name = [name copy];
    }
    return self;
}

- (NSString *)description {
    return self.name;
}

@end

@interface MyLevelMeterView ()

@property (nonatomic) NSUInteger ledCount;
@property (strong, nonatomic) UIColor *ledBackgroundColor;
@property (strong, nonatomic) UIColor *ledBorderColor;
@property (strong, nonatomic) NSArray *colorThresholds;

@end

@implementation MyLevelMeterView

- (instancetype)init {
    if (self = [super init]) {
        [self setupView];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setupView];
    }
    return self;
}

- (void)setupView {
    self.backgroundColor = [UIColor clearColor];
    
    _ledCount = 20;
    _ledBackgroundColor = [UIColor colorWithWhite:0.0f alpha:0.35f];
    _ledBorderColor = [UIColor blackColor];
    
    UIColor *greenColor = [UIColor colorWithRed:0.458 green:1.000 blue:0.396 alpha:1.000];
    UIColor *yellowColor = [UIColor colorWithRed:1.000 green:0.930 blue:0.315 alpha:1.000];
    UIColor *redColor = [UIColor colorWithRed:1.000 green:0.325 blue:0.329 alpha:1.000];
    _colorThresholds = @[
                         [THLevelMeterColorThreshold colorThresholdWithMaxValue:0.5f color:greenColor name:@"green"],
                         [THLevelMeterColorThreshold colorThresholdWithMaxValue:0.8f color:yellowColor name:@"yellow"],
                         [THLevelMeterColorThreshold colorThresholdWithMaxValue:1.0f color:redColor name:@"red"]
                         ];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    NSLog(@"%f, %f", self.level, self.peakLevel);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat width = rect.size.width / self.ledCount;
    CGFloat height = rect.size.height;
    
    NSUInteger peakLed = self.peakLevel * self.ledCount;
    
    for (NSUInteger i=0; i<self.ledCount; i++) {
    
        float current = ((float)i) / self.ledCount;
        
        UIColor *ledColor = (UIColor *)[self.colorThresholds[0] color];
        for (NSInteger j=0; j<self.colorThresholds.count-1; j++) {
            THLevelMeterColorThreshold *threshold1 = self.colorThresholds[j];
            THLevelMeterColorThreshold *threshold2 = self.colorThresholds[j+1];
            if (current >= threshold1.maxValue) {
                ledColor = threshold2.color;
            }
        }
        
        CGRect ledRect = CGRectMake(i * width, 0, width, height);
    
        float intensity = 0.0f;
        if (peakLed-1 == i) {
            intensity = 1.0f;
        } else {
            intensity = clamp(self.level / current);
        }
        
        //背景
        CGContextAddRect(context, ledRect);
        CGContextSetFillColorWithColor(context, self.ledBackgroundColor.CGColor);
        CGContextFillPath(context);
        
        //透明度 //CGColorCreateCopyWithAlpha(ledColor.CGColor, intensity)
        CGContextSetFillColorWithColor(context, CGColorCreateCopyWithAlpha(ledColor.CGColor, intensity));
        UIBezierPath *fillPath;
#if 1
        //切所有的角
        fillPath = [UIBezierPath bezierPathWithRoundedRect:ledRect cornerRadius:2.0f];
#else
        //只切部分角为圆角
        fillPath = [UIBezierPath bezierPathWithRoundedRect:ledRect byRoundingCorners:UIRectCornerTopLeft cornerRadii:CGSizeMake(2.0f, 2.0f)];
#endif
        CGContextAddPath(context, fillPath.CGPath);
        // 这边可能会想一个问题： strokePath怎么就表示画笔了？ 应该是CGContextSetStrokeColorWithColor 和 strokePath是一同处理进context的原因
        CGContextSetStrokeColorWithColor(context, self.ledBorderColor.CGColor);
        UIBezierPath *strokePath = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(ledRect, 0.5, 0.5) cornerRadius:2.0f];
        CGContextAddPath(context, strokePath.CGPath);
        //
        CGContextDrawPath(context, kCGPathFillStroke);
    }
}

float clamp (float intensity) {
    
    if (intensity < 0) {
        intensity = 0.0f;
    } else if (intensity > 1) {
        intensity = 1.0f;
    }
    return intensity;
}

- (void)resetLevelMeter {
    self.level = 0.0f;
    self.peakLevel = 0.0f;
    [self setNeedsDisplay];
}

@end
