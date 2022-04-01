//
//  VideoPlayer.h
//
//  Created by HN on 2021/6/30.
// 参考：https://github.com/czhen09/ScrollPlayVideo

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

//填充模式枚举值
typedef NS_ENUM(NSInteger, VideoPlayerGravity) {
   VideoPlayerGravityResizeAspect,
   VideoPlayerGravityResizeAspectFill,
   VideoPlayerGravityResize,
};

//播放状态枚举值
typedef NS_ENUM(NSInteger, VideoPlayerStatus) {
    VideoPlayerStatusReady,
//    VideoPlayerStatusLoading,
    VideoPlayerStatusPlaying,
    VideoPlayerStatusPaused,
    VideoPlayerStatusStopped,
    VideoPlayerStatusFinished,
    VideoPlayerStatusUnknown,
    VideoPlayerStatusFailed,
    
//    VideoPlayerStatusChangeEsolution,
//    VideoPlayerStatusDownload,
};

@class VideoPlayer;
@protocol VideoPlayerDelegate <NSObject>

@optional
- (void)videoPlayer:(VideoPlayer *)videoPlayer playerStatus:(VideoPlayerStatus)status error:(NSError *)error;
- (void)videoPlayer:(VideoPlayer *)videoPlayer tapActionWithIsShouldToHideSubviews:(BOOL)isHide;
- (void)videoPlayer:(VideoPlayer *)videoPlayer loadingDataWithStatus:(BOOL)isHide;

@end

@interface VideoPlayer : UIView
// AVPlayer
@property(nonatomic, strong) AVPlayer *avPlayer;
// 用于画中画
@property(nonatomic, strong) AVPlayerLayer *avPlayerLayer;
//总时长
@property(nonatomic, assign) CGFloat totalTime;
//当前时间
@property(nonatomic, assign) CGFloat currentTime;
//播放器Playback Rate
@property(nonatomic, assign) CGFloat rate;
//播放状态
@property(nonatomic, assign, readonly) VideoPlayerStatus status;
// videoGravity设置屏幕填充模式（只写）
@property(nonatomic, assign, readwrite) VideoPlayerGravity mode;
/// 是否正在播放
@property(nonatomic, assign, readonly) BOOL isPlaying;
/// 自动播放次数。默认无限循环(NSUIntegerMax)
@property (nonatomic, assign, readwrite) NSUInteger autoPlayCount;
/// 前后台切换，自动播放/暂停。默认YES
@property (nonatomic, assign, readwrite) BOOL autoControlBackground;

//与url初始化
- (instancetype)initWithUrl:(NSURL *)url;
- (instancetype)initWithUrl:(NSURL *)url delegate:(id<VideoPlayerDelegate>)delegate;
//播放
- (void)play;
//暂停
- (void)pause;
//停止 （移除当前视频播放下一个或者销毁视频，需调用Stop方法）
- (void)stop;
- (void)seekToTimeTo:(CGFloat)seekTime;

@property(nonatomic, weak) id<VideoPlayerDelegate> delegate;

@property (copy, nonatomic) void(^progressBlock) (NSString *currentTime, NSString *totalTime, CGFloat progress);
@property (copy, nonatomic) void(^bufferBlock) (CGFloat bufferProgress);

@end
