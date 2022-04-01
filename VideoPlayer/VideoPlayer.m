//
//  VideoPlayer.m
//
//  Created by HN on 2021/6/30.
//

#import "VideoPlayer.h"

@interface VideoPlayer ()<UIGestureRecognizerDelegate>
//资产AVURLAsset
@property(nonatomic, strong) AVURLAsset *asset;
// AVPlayer的播放item
@property(nonatomic, strong) AVPlayerItem *item;

//播放状态
@property(nonatomic, assign, readwrite) VideoPlayerStatus status;
//加载动画
@property(nonatomic, strong) UIActivityIndicatorView *activityIndeView;
@property(nonatomic, assign) BOOL isShouldToHiddenSubviews;
@property(nonatomic, assign) BOOL isFirstPrepareToPlay;
/// 自动播放次数。默认无限循环(NSUIntegerMax)
@property(nonatomic, assign) NSUInteger autoPlayCountTemp;
@property(nonatomic, assign) BOOL autoControlBackgroundTemp;
@property(strong, nonatomic) id playbackTimerObserver;

@end

@implementation VideoPlayer

#pragma mark - life
- (instancetype)initWithUrl:(NSURL *)url {
    return [self initWithUrl:url delegate:nil];
}

- (instancetype)initWithUrl:(NSURL *)url delegate:(id<VideoPlayerDelegate>)delegate {
    if (self = [super init]) {
        self.delegate = delegate;
        self.autoPlayCountTemp = NSUIntegerMax;
        self.autoControlBackground = YES;
        [self setupPlayerUI];
        [self assetWithURL:url];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.avPlayerLayer.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    
    self.activityIndeView.center = self.center;
    self.activityIndeView.bounds = CGRectMake(0, 0, 35, 35);
}

- (void)assetWithURL:(NSURL *)url {
    self.status = VideoPlayerStatusReady;

    [self setupPlayerWithURL:url];

    NSArray *keys = @[@"duration"];
    __weak typeof(self) weakSelf = self;
    [self.asset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
        NSError *error = nil;
        AVKeyValueStatus tracksStatus = [weakSelf.asset statusOfValueForKey:@"duration" error:&error];
        switch (tracksStatus) {
            case AVKeyValueStatusLoaded: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!CMTIME_IS_INDEFINITE(weakSelf.asset.duration)) {
                        if (weakSelf.asset.duration.timescale > 0) {
//                            CGFloat second = weakSelf.asset.duration.value / weakSelf.asset.duration.timescale;
//                            weakSelf.controlView.totalTime = [weakSelf convertTime:second];
//                            weakSelf.controlView.minValue = 0;
//                            weakSelf.controlView.maxValue = second;
                        }
                    }
                });
            } break;
            case AVKeyValueStatusFailed: {
//                NSLog(@"AVKeyValueStatusFailed失败,请检查网络,或查看plist中是否添加App Transport Security Settings");
            } break;
            case AVKeyValueStatusCancelled: {
//                NSLog(@"AVKeyValueStatusCancelled取消");
            } break;
            case AVKeyValueStatusUnknown: {
//                NSLog(@"AVKeyValueStatusUnknown未知");
            } break;
            case AVKeyValueStatusLoading: {
//                NSLog(@"AVKeyValueStatusLoading正在加载");
            } break;
        }
    }];
}

- (void)setupPlayerWithURL:(NSURL *)url {
    self.asset = [[AVURLAsset alloc] initWithURL:url options:@{AVURLAssetPreferPreciseDurationAndTimingKey:@YES}];
    self.item = [[AVPlayerItem alloc] initWithAsset:self.asset];
    
    self.avPlayer = [[AVPlayer alloc] initWithPlayerItem:self.item];
    self.avPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
    [self.layer addSublayer:self.avPlayerLayer];

    self.avPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self addPeriodicTimeObserver];
    //添加KVO
    [self addKVO];
    //添加消息中心
    [self addNotificationCenter];
}

- (void)dealloc {
    [self stop];
}

#pragma mark - UI
// 设置界面 在此方法下面可以添加自定义视图，和删除视图
- (void)setupPlayerUI {
    self.activityIndeView.hidden = NO;
    [self.activityIndeView startAnimating];
    //添加点击事件
    [self addGestureEvent];
    //添加加载视图
    [self addSubview:self.activityIndeView];
    self.isFirstPrepareToPlay = YES;
}

- (void)hideActivityIndeView {
    [self.activityIndeView stopAnimating];
    self.activityIndeView.hidden = YES;
}

#pragma mark - other
#pragma mark KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus itemStatus = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (itemStatus) {
            case AVPlayerItemStatusUnknown: {
                [self hideActivityIndeView];
                self.status = VideoPlayerStatusUnknown;
//                NSLog(@"AVPlayerItemStatusUnknown");
            } break;
            case AVPlayerItemStatusReadyToPlay: {
                _isPlaying = YES;
                self.status = VideoPlayerStatusPlaying;
//                NSLog(@"AVPlayerItemStatusReadyToPlay");
            } break;
            case AVPlayerItemStatusFailed: {
                [self hideActivityIndeView];
                self.status = VideoPlayerStatusFailed;
//                NSLog(@"AVPlayerItemStatusFailed");
            } break;
            default:
                break;
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) { //监听播放器的下载进度
        NSArray *loadedTimeRanges = [self.item loadedTimeRanges];
        CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue]; // 获取缓冲区域
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval timeInterval = startSeconds + durationSeconds; // 计算缓冲总进度
        CMTime duration = self.item.duration;
        CGFloat totalDuration = CMTimeGetSeconds(duration);
        //缓存值
        CGFloat bufferValue = timeInterval / totalDuration;
        if (self.bufferBlock) {
            self.bufferBlock(bufferValue);
        }
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        if ([self.delegate respondsToSelector:@selector(videoPlayer:loadingDataWithStatus:)]) {
            [self.delegate videoPlayer:self loadingDataWithStatus:NO];
        }
        //监听播放器在缓冲数据的状态
        NSLog(@"缓冲中。。。");
        if (!self.activityIndeView.isAnimating && self.isFirstPrepareToPlay) {
            self.activityIndeView.hidden = NO;
            [self.activityIndeView startAnimating];
        }
    } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        if ([self.delegate respondsToSelector:@selector(videoPlayer:loadingDataWithStatus:)]) {
            [self.delegate videoPlayer:self loadingDataWithStatus:YES];
        }
        if (self.isFirstPrepareToPlay) {
            NSLog(@"缓冲达到可播放");
            [self hideActivityIndeView];
//#warning <#message#>
//            [self play];
            self.isFirstPrepareToPlay = NO;
        }
    } else if ([keyPath isEqualToString:@"rate"]) { //当rate==0时为暂停,rate==1时为播放,当rate等于负数时为回放
//        if (self.isFirstPrepareToPlay == YES) {
//            return;
//        }
//        if ([[change objectForKey:NSKeyValueChangeNewKey] integerValue] == 0) {
//            _isPlaying = NO;
//            self.status = VideoPlayerStatusPaused;
//        } else {
//            _isPlaying = YES;
//            self.status = VideoPlayerStatusPlaying;
//        }
    }
}

//添加KVO
- (void)addKVO {
    if (self.item || self.item != nil) {
        //监听状态属性
        [self.item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        //监听网络加载情况属性
        [self.item addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
        //监听播放的区域缓存是否为空
        [self.item addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
        //缓存可以播放的时候调用
        [self.item addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    }
    if (self.avPlayer || self.avPlayer != nil) {
        //监听暂停或者播放中
        [self.avPlayer addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:nil];
    }
}

#pragma mark - Notify
- (void)addNotificationCenter {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidPlayToEndTimeNotification:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.avPlayer.currentItem];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)removeNotificationCenter {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.avPlayer.currentItem];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)playerItemDidPlayToEndTimeNotification:(NSNotification *)notification {
    [self seekToTimeTo:0];
    [self finished];
    
    //重新播放视频
    if (self.autoPlayCountTemp == NSUIntegerMax) {
        [self replay];
    } else {
        --self.autoPlayCountTemp;
        if (self.autoPlayCountTemp > 0) {
            [self replay];
        }
    }
}

- (void)willResignActive:(NSNotification *)notification {
    if (self.isPlaying && self.autoControlBackgroundTemp) {
        [self pause];
    }
}

- (void)willEnterForeground:(NSNotification *)notification {
    if (!self.isPlaying && self.autoControlBackgroundTemp) {
        [self replay];
    }
}

#pragma mark - gesture
- (void)addGestureEvent {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapAction:)];
    tap.delegate = self;
    [self addGestureRecognizer:tap];
}

- (void)handleTapAction:(UITapGestureRecognizer *)gesture {
    self.isShouldToHiddenSubviews = !self.isShouldToHiddenSubviews;
    if ([self.delegate respondsToSelector:@selector
         (videoPlayer:tapActionWithIsShouldToHideSubviews:)]) {
        [self.delegate videoPlayer:self tapActionWithIsShouldToHideSubviews:self.isShouldToHiddenSubviews];
    }
}

//将数值转换成时间
+ (NSString *)convertTime:(CGFloat)second {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:second];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    if (second / 3600 >= 1) {
        [formatter setDateFormat:@"HH:mm:ss"];
    } else {
        [formatter setDateFormat:@"mm:ss"];
    }
    NSString *showtimeNew = [formatter stringFromDate:date];
    return showtimeNew;
}

// FIXME: Tracking time,跟踪时间的改变
- (void)addPeriodicTimeObserver {
    __weak typeof(self) weakSelf = self;
    self.playbackTimerObserver = [self.avPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1000.0)
                                                                             queue:dispatch_get_main_queue()
                                                                        usingBlock:^(CMTime time) {
        if (weakSelf.item.status == AVPlayerItemStatusReadyToPlay) {
            
            weakSelf.currentTime = CMTimeGetSeconds(time);
            weakSelf.totalTime = CMTimeGetSeconds([weakSelf.item duration]);
            CGFloat value = weakSelf.item.currentTime.value /(CGFloat) weakSelf.item.currentTime.timescale;

            if (!CMTIME_IS_INDEFINITE(weakSelf.asset.duration)) {
                NSString *currentTime = [VideoPlayer convertTime:value];
                NSString *totalTime = [VideoPlayer convertTime:weakSelf.totalTime];
                CGFloat progress = value/weakSelf.totalTime;
                if (weakSelf.progressBlock) {
                    weakSelf.progressBlock(currentTime, totalTime, progress);
                }
            }
        }
    }];
}

#pragma mark player operation
- (void)play {
    if (self.avPlayer) {
//        self.status = VideoPlayerStatusLoading;
        [self.avPlayer play];
    }
}

- (void)replay {
    if (self.avPlayer) {
        _isPlaying = YES;
        self.status = VideoPlayerStatusPlaying;
        [self.avPlayer play];
    }
}

- (void)pause {
    if (self.avPlayer) {
        _isPlaying = NO;
        self.status = VideoPlayerStatusPaused;
        [self.avPlayer pause];
    }
}

- (void)finished {
    if (self.avPlayer) {
        self.status = VideoPlayerStatusFinished;
        [self.avPlayer pause];
    }
}

- (void)stop {
    if (self.item || self.item != nil) {
        [self.item removeObserver:self forKeyPath:@"status"];
        [self.item removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [self.item removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [self.item removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    }
    if (self.avPlayer || self.avPlayer != nil) {
        [self.avPlayer removeTimeObserver:self.playbackTimerObserver];
        [self.avPlayer removeObserver:self forKeyPath:@"rate"];
    }
    
    [self removeNotificationCenter];
    
    if (self.avPlayer) {
        [self pause];
        self.asset = nil;
        self.item = nil;
        self.avPlayer = nil;
        [self.activityIndeView stopAnimating];
        [self.activityIndeView removeFromSuperview];
        self.activityIndeView = nil;
        [self removeFromSuperview];
    }
}

- (void)seekToTimeTo:(CGFloat)seekTime {
    CMTime pointTime = CMTimeMake(seekTime * self.item.currentTime.timescale, self.item.currentTime.timescale);
    [self.item seekToTime:pointTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:nil];
    if (self.status == VideoPlayerStatusFinished) {
        [self play];
    }
}

#pragma mark - get data
- (CGFloat)rate {
    return self.avPlayer.rate;
}

//懒加载ActivityIndicateView
- (UIActivityIndicatorView *)activityIndeView {
    if (!_activityIndeView) {
        if (@available(iOS 13.0, *)) {
            _activityIndeView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        } else {
            _activityIndeView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        }
        _activityIndeView.hidesWhenStopped = YES;
    }
    return _activityIndeView;
}

#pragma mark - set data
- (void)setRate:(CGFloat)rate {
    self.avPlayer.rate = rate;
}

- (void)setMode:(VideoPlayerGravity)mode {
    switch (mode) {
        case VideoPlayerGravityResizeAspect:
            self.avPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
            break;
        case VideoPlayerGravityResizeAspectFill:
            self.avPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            break;
        case VideoPlayerGravityResize:
            self.avPlayerLayer.videoGravity = AVLayerVideoGravityResize;
            break;
    }
}

- (void)setAutoPlayCount:(NSUInteger)autoPlayCount {
    _autoPlayCount = autoPlayCount;
    self.autoPlayCountTemp = autoPlayCount;
}

- (void)setAutoControlBackground:(BOOL)autoControlBackground {
    _autoControlBackground = autoControlBackground;
    self.autoControlBackgroundTemp = autoControlBackground;
}

- (void)setStatus:(VideoPlayerStatus)status {
    _status = status;
    
    if ([self.delegate respondsToSelector:@selector(videoPlayer:playerStatus:error:)]) {
        [self.delegate videoPlayer:self playerStatus:status error:self.item.error];
    }
}
@end
