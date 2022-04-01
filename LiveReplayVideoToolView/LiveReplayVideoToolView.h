//
//  LiveReplayVideoToolView.h
//  HN
//
//  Created by HN on 2020/9/22.
//  Copyright © 2020 HN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CCHStepSizeSlider.h"

NS_ASSUME_NONNULL_BEGIN

@interface LiveReplayVideoToolView : UIView
@property (nonatomic, copy) void(^LiveReplayVideoToolViewBeginBlock)(CGFloat sliderValue);
@property (nonatomic, copy) void(^LiveReplayVideoToolViewChangeBlock)(CGFloat sliderValue);
@property (nonatomic, copy) void(^LiveReplayVideoToolViewEndBlock)(CGFloat sliderValue);
@property (nonatomic, copy) void(^LiveReplayVideoToolViewPlayBlock)(UIButton *sender);

@property (weak, nonatomic) IBOutlet UILabel *startTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalTimeLabel;
@property (weak, nonatomic) IBOutlet UIButton *playButton;

@property (strong, nonatomic) CCHStepSizeSlider *slider;

+ (instancetype)contentView;

@end

NS_ASSUME_NONNULL_END
