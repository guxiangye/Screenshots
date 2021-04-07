//
//  VTSimplePlayer.m
//  VTAntiScreenCapture_Example
//
//  Created by Vincent on 2018/12/31.
//  Copyright © 2018 mightyme@qq.com. All rights reserved.
//

#import "VTSimplePlayer.h"
#import <AVFoundation/AVFoundation.h>

#pragma mark - VTSimpleResourceLoaderDelegate

@interface VTSimpleResourceLoaderDelegate : NSObject<AVAssetResourceLoaderDelegate>
@property (nonatomic, strong) NSString *name;
@end

@implementation VTSimpleResourceLoaderDelegate

- (instancetype)initWithName:(NSString *)name
{
    self = [super init];
    if (self) {
        self.name = name;
    }
    return self;
}

/**
 m3u8 文件，player 是无法直接读取
 */
- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest{
    
    NSString *url = loadingRequest.request.URL.absoluteString;
    if ([url isEqualToString:[NSString stringWithFormat:@"screenshot://%@.m3u8", self.name]]) {
        NSData *data = [[self get_m3u8] dataUsingEncoding:NSUTF8StringEncoding];
        [loadingRequest.dataRequest respondWithData:data];
        [loadingRequest finishLoading];
    }
    else if([url isEqualToString:[NSString stringWithFormat:@"screenshot://%@.key", self.name]]) {
        NSMutableData *data = [NSMutableData dataWithLength:16];
        [data resetBytesInRange:NSMakeRange(0, [data length])];
        [loadingRequest.dataRequest respondWithData:data];
        [loadingRequest finishLoading];
    }
    
    return YES;
}

- (NSString *)get_m3u8 {
    NSString *format = @"#EXTM3U\n\
#EXT-X-PLAYLIST-TYPE:VOD\n\
#EXT-X-VERSION:5\n\
#EXT-X-TARGETDURATION:%@\n\
#EXT-X-KEY:METHOD=SAMPLE-AES,URI=\"screenshot://%@.key\"\n\
#EXTINF:%@,\n\
http://localhost:%@\n\
#EXT-X-ENDLIST";
    NSInteger duration = 1;
    CGFloat EXTINF = 1/15.0;  // 15 fps
    NSString *host = [NSString stringWithFormat:@"%@/%@", @(10123), self.name];
    NSString *res = [NSString stringWithFormat:format, @(duration), self.name, @(EXTINF), host];
    return res;
}

@end

#pragma mark - VTSimplePlayer

@interface VTSimplePlayer ()

@property(nonatomic, strong)AVURLAsset *URLAsset;
@property (nonatomic, strong)AVPlayerItem *playerItem;
@property (nonatomic, strong)AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, weak)UIView *containerView;

@property (nonatomic, strong) VTSimpleResourceLoaderDelegate *resourceLoader;

@end

@implementation VTSimplePlayer

- (void)playURL:(NSString *)url name:(NSString *)name inView:(UIView *)container {
    if (![url isKindOfClass:[NSString class]]) {
        return;
    }
    if (url.length==0) return;
    if (!container) return;
    
    _containerView = container;
    AVURLAsset *videoURLAsset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:url] options:nil];
    self.URLAsset = videoURLAsset;
    
    VTSimpleResourceLoaderDelegate *loader = [[VTSimpleResourceLoaderDelegate alloc] initWithName:name];
    self.resourceLoader = loader;
    [self.URLAsset.resourceLoader setDelegate:loader queue:dispatch_get_main_queue()];

    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:videoURLAsset];
    self.playerItem = playerItem;
    
    self.player = [AVPlayer playerWithPlayerItem:playerItem];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = CGRectMake(0, 0, container.bounds.size.width, container.bounds.size.height-1);
}

- (void)resume{
    if (!self.playerItem) return;
    [self.player play];
}

- (void)pause{
    if (!self.playerItem) return;
    [self.player pause];
}

- (void)stop{
    if (!self.player) return;
    [self.player pause];
    [self.player cancelPendingPrerolls];
    if (self.playerLayer) {
        [self.playerLayer removeFromSuperlayer];
        self.playerLayer = nil;
    }
    [self.URLAsset.resourceLoader setDelegate:nil queue:dispatch_get_main_queue()];
    self.URLAsset = nil;
    self.playerItem = nil;
    self.player = nil;
}

-(void)handleShowViewSublayers{
    for (UIView *view in _containerView.subviews) {
        [view removeFromSuperview];
    }
    [_containerView.layer addSublayer:self.playerLayer];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItem *playerItem = (AVPlayerItem *)object;
        AVPlayerItemStatus status = playerItem.status;
        switch (status) {
            case AVPlayerItemStatusUnknown:{
            }
                break;
                
            case AVPlayerItemStatusReadyToPlay:{
                [self.player play];
                [self handleShowViewSublayers];
                NSLog(@"duration: %@", @([self duration]));
            }
                break;
                
            case AVPlayerItemStatusFailed:{
                
            }
                break;
            default:
                break;
        }
    }
    else if ([keyPath isEqualToString:@"playbackBufferEmpty"]){

    }
    else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]){

    }
}

- (CGFloat)duration {
    CGFloat totalTime = CMTimeGetSeconds(self.playerItem.asset.duration);
    return totalTime;
}


-(void)setPlayerItem:(AVPlayerItem *)playerItem{
    if (_playerItem) {
        [_playerItem removeObserver:self forKeyPath:@"status"];
        [_playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [_playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    }
    
    _playerItem = playerItem;
    
    [_playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [_playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [_playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
}

-(void)setPlayerLayer:(AVPlayerLayer *)playerLayer{
    if (_playerLayer) {
        [_playerLayer removeFromSuperlayer];
    }
    _playerLayer = playerLayer;
}

@end
