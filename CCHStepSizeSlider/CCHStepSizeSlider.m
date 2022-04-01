//
//  CCHStepSizeSlider.m
//  蓝媒智能家居系统
//
//  Created by cchhjj on 16/10/25.
//  Copyright © 2016年 BlueMedia. All rights reserved.
//

#import "CCHStepSizeSlider.h"

@implementation CCHStepSizeSlider {
    
    CGPoint touchPoint;
    
    CGPoint thumbPoint;
    CGRect thumbRect;
    
    NSMutableArray *stepRectArray;
    
    CGFloat startPoint;
    CGFloat endPoint;
    
    CGFloat y;
    
    BOOL istap;
    BOOL isrun;
    
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}


- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}


- (void)setup {
    self.backgroundColor = [UIColor whiteColor];
    
    _thumbBordColor = [UIColor colorWithWhite:0.99 alpha:1];
    _thumbColor = [UIColor whiteColor];
    _lineColor = [UIColor colorWithWhite:0.9 alpha:1];
    _stepColor = [UIColor cyanColor];
    
    _minTrackColor = [UIColor cyanColor];
    _maxTrackColor = _lineColor;
    
    _minimumValue = 0;
    _maximumValue = 1;
    
    _value = 0;
    _index = 0;
    
    _thumbTouchRate = 2;
    _stepTouchRate = 2;
    
    _type = CCHStepSizeSliderTypeStep;
    _continuous = YES;
    
    
    _margin = 30;
    _lineWidth = 8;
    
    _numberOfStep = 5;
    
    
    _titleOffset = 20;
    _sliderOffset = 0;
    
    _thumbSize = CGSizeMake(25, 25);
    
}


- (void)drawRect:(CGRect)rect {
    // Drawing code
    
    NSAssert(_maximumValue > _minimumValue, @"最大值要大于最小值");
    
    if (_maximumValue <= _minimumValue) {
        _minimumValue = 0;
        _maximumValue = 1;
    }
    
    
    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseIn animations:^{
        
        stepRectArray = [NSMutableArray array];
        
        CGFloat width = rect.size.width - _margin*2;
        
        y = CGRectGetMidY(rect);
        y+=_sliderOffset;
        
        
        startPoint = _margin;
        endPoint = rect.size.width - _margin;
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        if (_lineImage) {
            
            [_lineImage drawInRect:CGRectMake(startPoint, y  - _lineWidth/2,  endPoint -startPoint, _lineWidth)];
            
            
        } else {
            [self drawLine:context startX:startPoint endX:endPoint lineColor:self.lineColor];
        }
        
        
        if (_type == CCHStepSizeSliderTypeStep) {
            
            CGFloat stWidth = _stepWidth?_stepWidth:_lineWidth;
            for (int i = 0; i < _numberOfStep; i++) {
                CGRect stepOvalRect = CGRectMake(startPoint + width/(_numberOfStep-1)*i - stWidth/2, y - stWidth/2,stWidth, stWidth);
                CGContextAddEllipseInRect(context, stepOvalRect);
                
                [self.stepColor set];
                CGContextFillPath(context);
                
                [stepRectArray addObject:[NSValue valueWithCGRect:stepOvalRect]];
                
                
                NSString *title = @"";
            
                if (self.titleArray.count > i) {
                    title = self.titleArray[i];
                }
                
                
                CGPoint titlePoint = CGPointMake(CGRectGetMidX(stepOvalRect), CGRectGetMinY(stepOvalRect));
                
                CGSize titleSize = [title sizeWithAttributes:self.titleAttributes];
                
                titlePoint.y += _titleOffset;
                titlePoint.x -= titleSize.width/2;
                
                CGRect titleRect = {titlePoint,titleSize};
                
                
                [title drawInRect:titleRect  withAttributes:self.titleAttributes];
                
            }
            
            if (!isrun) {
                if (_index >= stepRectArray.count) {
                    _index = stepRectArray.count - 1;
                    if (_index < 0) {
                        _index = 0;
                    }
                }
                
                NSValue *cvalue = stepRectArray[_index];
                CGRect crect = [cvalue CGRectValue];
                thumbPoint = CGPointMake(CGRectGetMidX(crect) - _thumbSize.width/2, CGRectGetMidY(crect) - _thumbSize.height/2);
                isrun = YES;
            }
            
            CGFloat startx;
            CGFloat endx;
            if (self.minTrackColor) {
                
                startx = startPoint;
                //                endx = (endPoint)*distanceRatio + startPoint;
                endx = thumbPoint.x + _thumbSize.width/2;
                
                
                //                if (startx > endx) {
                //                    startx = endx;
                //                }
                
                [self drawLine:context startX:startx endX:endx lineColor:self.minTrackColor];
                
            }
            
            if (self.maxTrackColor) {
                
                //                startx = (endPoint)*distanceRatio + startPoint;
                startx = thumbPoint.x + _thumbSize.width/2;
                endx = endPoint;
                
                //                if (startx > endx) {
                //                    startx = endx;
                //                }
                
                [self drawLine:context startX:startx endX:endx lineColor:self.maxTrackColor];
                
            }
            
        }
        else if (_type == CCHStepSizeSliderTypeNormal) {
            
            if (!isrun) {
                
                thumbPoint = CGPointMake([self ChangeX] - _thumbSize.width/2, y - _thumbSize.height/2);
                
                
                isrun = YES;
            }
            
            
            CGFloat maximumDistance;
            CGFloat distanceRatio = 0.0;
            
            
            if (_minimumValue >= 0 && _maximumValue > 0) {
                
                maximumDistance = _maximumValue - _minimumValue;
                distanceRatio = (self.value - _minimumValue)/maximumDistance;
                
            } else if (_minimumValue < 0 && _maximumValue < 0) {
                
                 maximumDistance = fabs(_minimumValue) - fabs(_maximumValue);
                 distanceRatio =  fabs(self.value - _maximumValue)/maximumDistance;
                
            } else if (_minimumValue < 0 && _maximumValue > 0) {
                
                maximumDistance = fabs(_minimumValue) + fabs(_maximumValue);
                
                CGFloat cvalue = self.value;
                if (self.value >= 0) {
                    cvalue += fabs(_minimumValue);
                }
                
                distanceRatio =  fabs(cvalue)/maximumDistance;
                
            }
            

            CGFloat startx;
            CGFloat endx;
            
            
            if (_lineImage) {
                
            } else {
                if (self.minTrackColor) {
                    
                    startx = startPoint;
                    //                endx = (endPoint)*distanceRatio + startPoint;
                    endx = thumbPoint.x + _thumbSize.width/2;
                    
                    
                    //                if (startx > endx) {
                    //                    startx = endx;
                    //                }
                    
                    [self drawLine:context startX:startx endX:endx lineColor:self.minTrackColor];
                    
                }
                
                if (self.maxTrackColor) {
                    
                    //                startx = (endPoint)*distanceRatio + startPoint;
                    startx = thumbPoint.x + _thumbSize.width/2;
                    endx = endPoint;
                    
                    //                if (startx > endx) {
                    //                    startx = endx;
                    //                }
                    
                    [self drawLine:context startX:startx endX:endx lineColor:self.maxTrackColor];
                    
                }
            }
            
        }

        
        thumbRect = CGRectMake(thumbPoint.x, thumbPoint.y  , _thumbSize.width, _thumbSize.height);
        
        if (_thumbImage) {
            [_thumbImage drawInRect:thumbRect];
        } else {
            CGContextAddEllipseInRect(context, thumbRect);

            [self.thumbColor set];
            CGContextSetLineWidth(context, 2);
            CGContextSetStrokeColorWithColor(context, self.thumbBordColor.CGColor);
            CGContextSetFillColorWithColor(context, self.thumbColor.CGColor);
            CGContextDrawPath(context, kCGPathFillStroke);
            
        }
        
        
        
        
    } completion:nil];
    
    
}


- (void)drawLine:(CGContextRef) context startX:(CGFloat)startX endX:(CGFloat)endX lineColor:(UIColor *)lineColor {
    
    CGContextMoveToPoint(context, startX, y);
    CGContextAddLineToPoint(context, endX, y);
    CGContextSetLineWidth(context, _lineWidth); // 线的宽度
    CGContextSetLineCap(context, kCGLineCapRound); // 起点和重点圆角
    CGContextSetLineJoin(context, kCGLineJoinRound); // 转角圆角
    CGContextSetStrokeColorWithColor(context, lineColor.CGColor);
    
    CGContextStrokePath(context);
    
    
    
}


- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(nullable UIEvent *)event {
    
    touchPoint = [touch locationInView:self];
//    touchPoint = [self convertPoint:touchPoint toView:self];
//    NSInteger tempIndex = 0;
    
    CGRect tempThumbRect = thumbRect;
    tempThumbRect.size.width = tempThumbRect.size.width*_thumbTouchRate;
    tempThumbRect.size.height = tempThumbRect.size.height*_thumbTouchRate;
    tempThumbRect.origin.x -= (tempThumbRect.size.width - thumbRect.size.width)/2;
    tempThumbRect.origin.y -= (tempThumbRect.size.height - thumbRect.size.height)/2;
    
    if (CCHStepSizeSliderTypeStep == _type) {
        istap = YES;
        
        for (NSValue *value in stepRectArray) {
            CGRect oldrect = [value CGRectValue];
//            CGRect orgin = oldrect;

            CGRect newrect = oldrect;
            newrect.size.width = newrect.size.width*_stepTouchRate;
            newrect.size.height = newrect.size.height*_stepTouchRate;
            newrect.origin.x -= (newrect.size.width - oldrect.size.width)/2;
            newrect.origin.y -= (newrect.size.height - oldrect.size.height)/2;
//            tempIndex++;
            if (CGRectContainsPoint(newrect, touchPoint)) {
                thumbPoint = CGPointMake(CGRectGetMidX(newrect) - _thumbSize.width/2, CGRectGetMidY(newrect) - _thumbSize.height/2);
                //[self setNeedsDisplay];
                return YES;

            }

        }
        
        return CGRectContainsPoint(tempThumbRect, touchPoint);
        
    } else if (CCHStepSizeSliderTypeNormal == _type) {
        
        return CGRectContainsPoint(tempThumbRect, touchPoint);
    }

    return NO;
    
}

- (void)resetThumPoint
{
    self.value = 0;
    self.index = 0;
    thumbPoint.x = [self ChangeX] - _thumbSize.width/2;
    [self valueRefresh];
}


- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(nullable UIEvent *)event {
    
    touchPoint = [touch locationInView:self];
    
    CGFloat x = touchPoint.x;
    
    thumbPoint.x = x - _thumbSize.width/2;
    
    if (x < startPoint ) {
        thumbPoint.x = startPoint - _thumbSize.width/2;
    }
    
    if (x > endPoint) {
        thumbPoint.x = endPoint - _thumbSize.width/2;
    }
    
    

    [self valueChangeForX:x];
    

    [self setNeedsDisplay];
    
    
    if (_continuous) {
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
    

    istap = NO;
    
    return YES;
}
- (void)endTrackingWithTouch:(nullable UITouch *)touch withEvent:(nullable UIEvent *)event {
    
    touchPoint = [touch locationInView:self];
    NSInteger tempIndex = 0;
    if (istap) {
        
        for (NSValue *value in stepRectArray) {
            CGRect rect = [value CGRectValue];
            CGRect orgin = rect;
            
            rect.size.width =rect.size.width *_stepTouchRate;
            rect.size.height =rect.size.height*_stepTouchRate;
            rect.origin.x -= rect.size.width/2;
            rect.origin.y -= rect.size.height/2;
            tempIndex++;
            
            if (CGRectContainsPoint(rect, touchPoint)) {
                thumbPoint = CGPointMake(CGRectGetMidX(orgin) - _thumbSize.width/2, CGRectGetMidY(orgin) - _thumbSize.height/2);
                
                _index = tempIndex - 1;
                
//                NSLog(@"index : %ld",(long)_index);
                
                [self valueRefresh];
                
                break;
                
            }
            
        }
        
        
    }
    else {
        
        if (_type == CCHStepSizeSliderTypeStep) {
            
            CGFloat x = thumbPoint.x + _thumbSize.width/2;
            
            CGFloat tempValue = 0;
            for (int i = 0; i < stepRectArray.count; i++) {
                NSValue *value = stepRectArray[i];
                CGRect rect = [value CGRectValue];
                CGFloat x1 = rect.origin.x;
                x1 += rect.size.width/2;
                
                CGFloat absvalue = fabs(x - x1);
                if (i == 0) {
                    tempValue = absvalue;
                } else {
                    
                    if (absvalue < tempValue) {
                        tempValue = absvalue;
                        tempIndex = i;
                    }
                    
                }
                
            }
            
            NSValue *cvalue = stepRectArray[tempIndex];
            CGRect crect = [cvalue CGRectValue];
            thumbPoint = CGPointMake(CGRectGetMidX(crect) - _thumbSize.width/2, CGRectGetMidY(crect) - _thumbSize.height/2);
            
            
            _index = tempIndex;
            
//            NSLog(@"index : %ld",(long)_index);
        }
        
        
        
        [self valueRefresh];
        
    }
    
    

    
}


- (CGFloat)ChangeX {
    
//    CGFloat rale;
//    if (_minimumValue >= 0 ) {
    
    if (self.value == _minimumValue) {
        return startPoint;
    }
    
    if (self.value == _maximumValue) {
        return endPoint;
    }
    
    
    return fabs(self.value)/(_maximumValue - _minimumValue)*(endPoint - startPoint)+ startPoint;
        
        
//    } else {
    

        

        
//    }
    
    
}


- (void)valueChangeForX:(CGFloat)x {
    
    CGFloat changeRale = (x - startPoint)/(endPoint - startPoint);
    
    CGFloat temp = changeRale * (_maximumValue - _minimumValue);
    
    if (_minimumValue >= 0 ) {
        self.value = temp;
    } else {
        
        if (temp < fabs(_minimumValue)) {
            self.value = -temp;
        }
        
        self.value = temp - fabs(_minimumValue);
        
    }
    
//    NSLog(@"current value : %f",self.value);
    
}

- (void)valueRefresh {
    
    [self setNeedsDisplay];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    
}


- (CGFloat)value {
    
    if (_value <= _minimumValue) {
        _value = _minimumValue;
    }
    
    if (_value >= _maximumValue) {
        _value = _maximumValue;
    }
    return _value;
}

- (void)setSliderValue:(CGFloat)value;
{
    self.value = value;
    
    thumbPoint.x = [self ChangeX] - _thumbSize.width/2;
    [self setNeedsDisplay];
}

- (NSInteger)index {
    
    
    if (_index >= _numberOfStep) {
        _index = _numberOfStep - 1;
    }
    
    if (_index < 0) {
        _index = 0;
    }
    

    return _index;
    
}

- (void)setNumberOfStep:(NSInteger)numberOfStep {
    
    if (numberOfStep < 2) {
        numberOfStep = 2;
    }
    
    _numberOfStep = numberOfStep;
    
    
}

- (NSDictionary *)titleAttributes {
    
    if (!_titleAttributes) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSForegroundColorAttributeName] = self.titleColor?self.titleColor:[UIColor lightGrayColor]; // 文字颜色
        dict[NSFontAttributeName] = self.titleFont?self.titleFont:[UIFont systemFontOfSize:14]; // 字体
        _titleAttributes = dict;
    }
    
    return _titleAttributes;
    
}


@end
