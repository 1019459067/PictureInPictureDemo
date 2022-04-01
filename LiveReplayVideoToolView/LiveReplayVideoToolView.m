//
//  LiveReplayVideoToolView.m
//  HN
//
//  Created by HN on 2020/9/22.
//  Copyright © 2020 HN. All rights reserved.
//

#import "LiveReplayVideoToolView.h"
#define HNWLoadViewFromNibInMainBundle(nibNameStr, indexInteger) [[NSBundle mainBundle] loadNibNamed:nibNameStr owner:nil options:nil][indexInteger]
#define HNWLoadFirstViewFromNibInMainBundle(nibNameStr) HNWLoadViewFromNibInMainBundle(nibNameStr, 0)

@interface LiveReplayVideoToolView ()

@property (weak, nonatomic) IBOutlet UIView *progressSliderBgView;

@end

@implementation LiveReplayVideoToolView

+ (instancetype)contentView {
    LiveReplayVideoToolView *contentView = HNWLoadFirstViewFromNibInMainBundle(NSStringFromClass(self.class));
    contentView.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 50);
//    contentView.backgroundColor = UIColor.clearColor;
    return contentView;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self settingUI];
}

#pragma mark - UI
- (void)settingUI {
    self.slider = [[CCHStepSizeSlider alloc]init];
    self.slider.backgroundColor = UIColor.clearColor;
    self.slider.value = 0;
    self.slider.margin = 8;
    self.slider.thumbSize = CGSizeMake(14, 14);
    self.slider.lineWidth = 3;
    self.slider.minimumValue = 0;
    self.slider.maximumValue = 1;
    self.slider.minTrackColor = UIColor.redColor;
    self.slider.type = CCHStepSizeSliderTypeNormal;
    [self.progressSliderBgView addSubview:self.slider];
    
    [self.slider addTarget:self action:@selector(onActionChangeBegin:) forControlEvents:UIControlEventTouchDown];
    [self.slider addTarget:self action:@selector(onActionChangeValue:) forControlEvents:UIControlEventValueChanged];
    [self.slider addTarget:self action:@selector(onActionChangeEnd:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.slider.frame = CGRectMake(0, 0, self.progressSliderBgView.frame.size.width, self.progressSliderBgView.frame.size.height);
}

#pragma mark - other
- (void)onActionChangeBegin:(CCHStepSizeSlider *)slider {
    if (self.LiveReplayVideoToolViewBeginBlock) {
        self.LiveReplayVideoToolViewBeginBlock(slider.value);
    }
}

- (void)onActionChangeValue:(CCHStepSizeSlider *)slider {
    if (self.LiveReplayVideoToolViewChangeBlock) {
        self.LiveReplayVideoToolViewChangeBlock(slider.value);
    }
}

- (void)onActionChangeEnd:(CCHStepSizeSlider *)slider {
    if (self.LiveReplayVideoToolViewEndBlock) {
        self.LiveReplayVideoToolViewEndBlock(slider.value);
    }
}

- (IBAction)onActionPlayEvent:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (self.LiveReplayVideoToolViewPlayBlock) {
        self.LiveReplayVideoToolViewPlayBlock(sender);
    }
}

@end
