//
//  TestViewController.m
//  PictureInPictureDemo
//
//  Created by HN on 2022/3/31.
//

#import "TestViewController.h"
#import "VideoPlayer.h"
#import "LiveReplayVideoToolView.h"
#import <AVKit/AVKit.h>
#import "AppDelegate.h"

// 手动滑动状态
typedef NS_ENUM(NSInteger, VideoSeekStatus) {
   VideoSeekStatus_Begin      = 0,
   VideoSeekStatus_Changing,
   VideoSeekStatus_End
};

@interface TestViewController ()<AVPictureInPictureControllerDelegate>
@property (weak, nonatomic) IBOutlet UIStackView *stackView;
@property (weak, nonatomic) IBOutlet UILabel *startL;
@property (weak, nonatomic) IBOutlet UILabel *totalL;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UIButton *pipButton;

@property (strong, nonatomic) VideoPlayer *player;
@property (nonatomic, strong) AVPictureInPictureController *pipController;

@property (strong, nonatomic) LiveReplayVideoToolView *videoToolView;

@property (assign, nonatomic) VideoSeekStatus seekStatus;
@property (weak, nonatomic) UINavigationController *navCtr;
@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    [self settingPlayer];
    [self.view addSubview:self.videoToolView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navCtr = self.navigationController;
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if ([delegate.testVC isKindOfClass:self.class]) {
        [self.pipController stopPictureInPicture];
    }
}

- (void)dealloc {
    NSLog(@"%s_ 释放了",__func__);
}


- (void)settingPlayer {
    NSString *str27 = @"https://video.cnhnb.com/video/mp4/douhuo/2021/01/09/d64965c85ab64389b0b4ee7c39b4ae97.mp4";
    NSString *str5 = @"https://video.cnhnb.com/video/mp4/douhuo/2020/12/09/58a4fc9cb83e4a268411245058f88ab1.mp4";
    self.player = [[VideoPlayer alloc]initWithUrl:[NSURL URLWithString:str27]];
//    self.player.autoPlayCount = 1;
    self.player.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
    [self.view addSubview:self.player];
    __weak typeof(self) weakSelf = self;
    self.player.progressBlock = ^(NSString *currentTime, NSString *totalTime, CGFloat progress) {
        weakSelf.startL.text = currentTime;
        weakSelf.totalL.text = totalTime;
        weakSelf.slider.value = progress;
        
        weakSelf.videoToolView.startTimeLabel.text = currentTime;
        weakSelf.videoToolView.totalTimeLabel.text = totalTime;
        if (weakSelf.seekStatus != VideoSeekStatus_Changing) {
            [weakSelf.videoToolView.slider setSliderValue:progress];
        }
    };
    [self.player play];
    [self.view bringSubviewToFront:self.stackView];
    
#warning 在此处添加AVPictureInPictureController会有问题：正在播放视频时，APP进入后台后画中画会自动弹出
    if ([AVPictureInPictureController isPictureInPictureSupported]) {
        self.pipController = [[AVPictureInPictureController alloc] initWithPlayerLayer:self.player.avPlayerLayer];
        self.pipController.delegate = self;
        self.player.autoControlBackground = NO;
    }
    [self.view bringSubviewToFront:self.videoToolView];
    [self.view bringSubviewToFront:self.pipButton];
    
}

- (IBAction)onActionPictureInPicture:(UIButton *)sender {
    if ([AVPictureInPictureController isPictureInPictureSupported]) {

        if (self.pipController.isPictureInPictureActive) {
            [self.pipController stopPictureInPicture];
            self.player.autoControlBackground = YES;
        } else {
            self.pipController = [[AVPictureInPictureController alloc] initWithPlayerLayer:self.player.avPlayerLayer];
            self.pipController.delegate = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.pipController startPictureInPicture];
                self.player.autoControlBackground = NO;
            });
        }
    }
}


#pragma mark ------- 画中画代理，和画中画状态有关的逻辑 在代理中处理
// 将开启画中画
- (void)pictureInPictureControllerWillStartPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    // 处理 pipBtn 的选中状态、储存当前控制器
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    delegate.testVC = self;
    [self.navigationController popViewControllerAnimated:YES];
}

// 将关闭画中画
- (void)pictureInPictureControllerWillStopPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    //
}

// 已经关闭画中画
- (void)pictureInPictureControllerDidStopPictureInPicture:(AVPictureInPictureController *)pictureInPictureController {
    // 处理 pipBtn 的选中状态、当前控制器置空
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    delegate.testVC = nil;
}

// 点击视频悬浮窗的复原按钮打开控制器
- (void)pictureInPictureController:(AVPictureInPictureController *)pictureInPictureController restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:(void (^)(BOOL))completionHandler {
    // 处理控制器的跳转等
    if (self.navCtr != nil && [self.navCtr.viewControllers containsObject:self] == NO) {
        
        AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        delegate.testVC = nil;
        [self.navCtr pushViewController:self animated:YES];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            completionHandler(YES);
        });
        return;
    }
    
    completionHandler(YES);
}


- (LiveReplayVideoToolView *)videoToolView {
    if (!_videoToolView) {
        _videoToolView = [LiveReplayVideoToolView contentView];
        _videoToolView.backgroundColor = UIColor.redColor;
        _videoToolView.frame = CGRectMake(0, 200, self.view.frame.size.width, 50);
        _videoToolView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
//        [self upateTimeLabelUIWithTime:0];

        __weak typeof(self) selfWeakRef = self;
        _videoToolView.LiveReplayVideoToolViewBeginBlock = ^(CGFloat sliderValue) {
//            [selfWeakRef hideReportButton];
            selfWeakRef.seekStatus = VideoSeekStatus_Begin;
        };
        _videoToolView.LiveReplayVideoToolViewChangeBlock = ^(CGFloat sliderValue) {
//            [selfWeakRef hideReportButton];
            selfWeakRef.seekStatus = VideoSeekStatus_Changing;

//            NSTimeInterval timeInSecond = sliderValue * selfWeakRef.txVodPlayer.duration;
//            [selfWeakRef upateTimeLabelUIWithTime:timeInSecond];
        };
        _videoToolView.LiveReplayVideoToolViewEndBlock = ^(CGFloat sliderValue) {
//            [selfWeakRef hideReportButton];
            selfWeakRef.seekStatus = VideoSeekStatus_End;
//
            NSTimeInterval timeInSecond = sliderValue * selfWeakRef.player.totalTime;
            [selfWeakRef.player seekToTimeTo:timeInSecond];
//            [selfWeakRef upateTimeLabelUIWithTime:timeInSecond];
        };
        _videoToolView.LiveReplayVideoToolViewPlayBlock = ^(UIButton * _Nonnull sender) {
//            [selfWeakRef hideReportButton];
            if (sender.selected) {
                [selfWeakRef.player pause];
            } else {
                [selfWeakRef.player play];
//                if (selfWeakRef.player.status == VideoPlayerStatusFinished) {
//                    [selfWeakRef.player play];
//                } else {
////                    [HUDUtils showHud:nil];
//                    [selfWeakRef startPlay:selfWeakRef.liveReplayModel.url];
//                }
            }
        };
    }
    return _videoToolView;
}
@end
