#import "SvgaPlayerView.h"

#import <react/renderer/components/SvgaPlayerViewSpec/ComponentDescriptors.h>
#import <react/renderer/components/SvgaPlayerViewSpec/EventEmitters.h>
#import <react/renderer/components/SvgaPlayerViewSpec/Props.h>
#import <react/renderer/components/SvgaPlayerViewSpec/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"
#import <SVGAPlayer/SVGAPlayer.h>

using namespace facebook::react;

@interface SvgaPlayerView () <RCTSvgaPlayerViewViewProtocol>

@end

@implementation SvgaPlayerView {
    SVGAPlayer * _svgaPlayer;
    NSString * _currentSource;
    BOOL _autoPlay;
    NSInteger _loops;
    BOOL _clearsAfterStop;
    NSString * _fillMode;
    SVGAVideoEntity * _currentVideoItem;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
    return concreteComponentDescriptorProvider<SvgaPlayerViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const SvgaPlayerViewProps>();
    _props = defaultProps;

    _svgaPlayer = [[SVGAPlayer alloc] init];
    _svgaPlayer.delegate = self;
    _svgaPlayer.loops = 0; // 默认无限循环
    _svgaPlayer.clearsAfterStop = YES; // 默认停止后清空画布

    _autoPlay = YES; // 默认自动播放
    _loops = 0; // 默认无限循环
    _clearsAfterStop = YES; // 默认停止后清空画布
    _fillMode = @"Forward"; // 默认前向填充

    self.contentView = _svgaPlayer;
  }

  return self;
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
    const auto &oldViewProps = *std::static_pointer_cast<SvgaPlayerViewProps const>(_props);
    const auto &newViewProps = *std::static_pointer_cast<SvgaPlayerViewProps const>(props);

    // 处理 source 属性
    if (oldViewProps.source != newViewProps.source) {
        NSString *newSource = newViewProps.source.empty() ? nil : [[NSString alloc] initWithUTF8String:newViewProps.source.c_str()];
        
        // 如果源发生变化，先清理当前的播放器状态
        if (![newSource isEqualToString:_currentSource]) {
            // 停止当前播放并清理
            if (_svgaPlayer) {
                [_svgaPlayer stopAnimation];
                [_svgaPlayer setVideoItem:nil];
                [_svgaPlayer clear];
            }
            _currentVideoItem = nil;
            
            _currentSource = newSource;
            
            // 如果有新源，则加载
            if (newSource) {
                [self loadSVGAFromSource:newSource];
            }
        }
    }

    // 处理 autoPlay 属性
    if (oldViewProps.autoPlay != newViewProps.autoPlay) {
        _autoPlay = newViewProps.autoPlay;
    }

    // 处理 loops 属性
    if (oldViewProps.loops != newViewProps.loops) {
        _loops = newViewProps.loops;
        _svgaPlayer.loops = _loops;
    }

    // 处理 clearsAfterStop 属性
    if (oldViewProps.clearsAfterStop != newViewProps.clearsAfterStop) {
        _clearsAfterStop = newViewProps.clearsAfterStop;
        _svgaPlayer.clearsAfterStop = _clearsAfterStop;
    }

    // 处理 fillMode 属性
    if (oldViewProps.fillMode != newViewProps.fillMode) {
        NSString *newFillMode = newViewProps.fillMode.empty() ? @"Forward" : [[NSString alloc] initWithUTF8String:newViewProps.fillMode.c_str()];
        _fillMode = newFillMode;
        // SVGAPlayer 没有直接的 fillMode 属性，我们需要在播放完成后处理
    }

    [super updateProps:props oldProps:oldProps];
}

Class<RCTComponentViewProtocol> SvgaPlayerViewCls(void)
{
    return SvgaPlayerView.class;
}

// 辅助方法：发送事件
- (void)sendLoadEvent
{
    if (_eventEmitter != nullptr) {
        std::dynamic_pointer_cast<const facebook::react::SvgaPlayerViewEventEmitter>(_eventEmitter)
            ->onLoad(facebook::react::SvgaPlayerViewEventEmitter::OnLoad{
                .loaded = true
            });
    }
}

- (void)sendErrorEvent:(NSString *)errorMessage
{
    if (_eventEmitter != nullptr) {
        std::dynamic_pointer_cast<const facebook::react::SvgaPlayerViewEventEmitter>(_eventEmitter)
            ->onError(facebook::react::SvgaPlayerViewEventEmitter::OnError{
                .error = std::string([errorMessage UTF8String])
            });
    }
}

// SVGA 播放器方法
- (void)loadSVGAFromSource:(NSString *)source
{
    if (!source || source.length == 0) {
        return;
    }

    SVGAParser *parser = [[SVGAParser alloc] init];

    // 判断文件类型并加载
    if ([source hasPrefix:@"http://"] || [source hasPrefix:@"https://"]) {
        // 远程 URL
        [self loadSVGAFromURL:source withParser:parser];
    } else if ([source hasPrefix:@"file://"]) {
        // file:// 协议的本地文件
        [self loadSVGAFromFileURL:source withParser:parser];
    } else if ([source hasPrefix:@"/"]) {
        // 绝对路径
        [self loadSVGAFromAbsolutePath:source withParser:parser];
    } else {
        // 相对路径，从 bundle 中查找
        [self loadSVGAFromBundle:source withParser:parser];
    }
}

- (void)loadSVGAFromURL:(NSString *)urlString withParser:(SVGAParser *)parser
{
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        [self sendErrorEvent:[NSString stringWithFormat:@"Invalid URL: %@", urlString]];
        return;
    }

    [parser parseWithURL:url completionBlock:^(SVGAVideoEntity * _Nullable videoItem) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (videoItem) {
                self->_currentVideoItem = videoItem;
                [self->_svgaPlayer setVideoItem:videoItem];
                [self sendLoadEvent];
                if (self->_autoPlay) {
                    [self->_svgaPlayer startAnimation];
                }
            }
        });
    } failureBlock:^(NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"SVGA load from URL error: %@", error.localizedDescription);
            [self sendErrorEvent:[NSString stringWithFormat:@"Failed to load SVGA from URL: %@", error.localizedDescription]];
        });
    }];
}

- (void)loadSVGAFromFileURL:(NSString *)fileURLString withParser:(SVGAParser *)parser
{
    NSURL *fileURL = [NSURL URLWithString:fileURLString];
    if (!fileURL || ![[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]) {
        NSLog(@"SVGA file not found at: %@", fileURLString);
        [self sendErrorEvent:[NSString stringWithFormat:@"SVGA file not found at: %@", fileURLString]];
        return;
    }

    [parser parseWithURL:fileURL completionBlock:^(SVGAVideoEntity * _Nullable videoItem) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (videoItem) {
                self->_currentVideoItem = videoItem;
                [self->_svgaPlayer setVideoItem:videoItem];
                [self sendLoadEvent];
                if (self->_autoPlay) {
                    [self->_svgaPlayer startAnimation];
                }
            }
        });
    } failureBlock:^(NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"SVGA load from file URL error: %@", error.localizedDescription);
            [self sendErrorEvent:[NSString stringWithFormat:@"Failed to load SVGA from file URL: %@", error.localizedDescription]];
        });
    }];
}

- (void)loadSVGAFromAbsolutePath:(NSString *)absolutePath withParser:(SVGAParser *)parser
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:absolutePath]) {
        NSLog(@"SVGA file not found at absolute path: %@", absolutePath);
        [self sendErrorEvent:[NSString stringWithFormat:@"SVGA file not found at: %@", absolutePath]];
        return;
    }

    NSURL *fileURL = [NSURL fileURLWithPath:absolutePath];
    [parser parseWithURL:fileURL completionBlock:^(SVGAVideoEntity * _Nullable videoItem) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (videoItem) {
                self->_currentVideoItem = videoItem;
                [self->_svgaPlayer setVideoItem:videoItem];
                [self sendLoadEvent];
                if (self->_autoPlay) {
                    [self->_svgaPlayer startAnimation];
                }
            }
        });
    } failureBlock:^(NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"SVGA load from absolute path error: %@", error.localizedDescription);
            [self sendErrorEvent:[NSString stringWithFormat:@"Failed to load SVGA from path: %@", error.localizedDescription]];
        });
    }];
    }];
}

- (void)loadSVGAFromBundle:(NSString *)fileName withParser:(SVGAParser *)parser
{
    // 处理文件扩展名
    NSString *name = [fileName stringByDeletingPathExtension];
    NSString *extension = [fileName pathExtension];
    if (extension.length == 0) {
        extension = @"svga";
    }

    // 从 main bundle 查找文件
    NSString *filePath = [[NSBundle mainBundle] pathForResource:name ofType:extension];
    if (!filePath) {
        NSLog(@"SVGA file not found in bundle: %@", fileName);
        [self sendErrorEvent:[NSString stringWithFormat:@"SVGA file not found in bundle: %@", fileName]];
        return;
    }

    [parser parseWithNamed:fileName inBundle:[NSBundle mainBundle] completionBlock:^(SVGAVideoEntity * _Nullable videoItem) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (videoItem) {
                self->_currentVideoItem = videoItem;
                [self->_svgaPlayer setVideoItem:videoItem];
                [self sendLoadEvent];
                if (self->_autoPlay) {
                    [self->_svgaPlayer startAnimation];
                }
            }
        });
    } failureBlock:^(NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"SVGA load from bundle error: %@", error.localizedDescription);
            [self sendErrorEvent:[NSString stringWithFormat:@"Failed to load SVGA from bundle: %@", error.localizedDescription]];
        });
    }];
}

// Command methods
- (void)startAnimation
{
    [_svgaPlayer startAnimation];
}

- (void)startAnimationWithRange:(NSInteger)location length:(NSInteger)length reverse:(BOOL)reverse
{
    NSRange range = NSMakeRange(location, length);
    [_svgaPlayer startAnimationWithRange:range reverse:reverse];
}

- (void)pauseAnimation
{
    [_svgaPlayer pauseAnimation];
}

- (void)stopAnimation
{
    NSLog(@"SvgaPlayerView: Stopping animation");
    [_svgaPlayer stopAnimation];
}

- (void)stopAnimationAndClear
{
    NSLog(@"SvgaPlayerView: Stopping animation and clearing");
    if (_svgaPlayer) {
        [_svgaPlayer stopAnimation];
        [_svgaPlayer setVideoItem:nil];
        [_svgaPlayer clear];
    }
    _currentVideoItem = nil;
}

- (void)stepToFrame:(NSInteger)frame andPlay:(BOOL)andPlay
{
    [_svgaPlayer stepToFrame:frame andPlay:andPlay];
}

- (void)stepToPercentage:(CGFloat)percentage andPlay:(BOOL)andPlay
{
    [_svgaPlayer stepToPercentage:percentage andPlay:andPlay];
}

// SVGAPlayerDelegate methods
- (void)svgaPlayerDidFinishedAnimation:(SVGAPlayer *)player
{
    // 处理 fillMode
    if ([_fillMode isEqualToString:@"Backward"]) {
        // Backward 模式：回到第一帧
        if (_currentVideoItem) {
            [_svgaPlayer stepToFrame:0 andPlay:NO];
        }
    }
    // Forward 模式不需要特殊处理，默认就停留在最后一帧

    if (_eventEmitter != nullptr) {
        std::dynamic_pointer_cast<const facebook::react::SvgaPlayerViewEventEmitter>(_eventEmitter)
            ->onFinished(facebook::react::SvgaPlayerViewEventEmitter::OnFinished{
                .finished = true
            });
    }
}

- (void)svgaPlayer:(SVGAPlayer *)player didAnimatedToFrame:(NSInteger)frame
{
    if (_eventEmitter != nullptr) {
        CGFloat percentage = 0.0;
        if (_currentVideoItem && _currentVideoItem.frames > 0) {
            percentage = (CGFloat)frame / (CGFloat)_currentVideoItem.frames * 100.0;
        }

        std::dynamic_pointer_cast<const facebook::react::SvgaPlayerViewEventEmitter>(_eventEmitter)
            ->onFrame(facebook::react::SvgaPlayerViewEventEmitter::OnFrame{
                .frame = static_cast<int>(frame),
                .percentage = percentage
            });

        std::dynamic_pointer_cast<const facebook::react::SvgaPlayerViewEventEmitter>(_eventEmitter)
            ->onPercentage(facebook::react::SvgaPlayerViewEventEmitter::OnPercentage{
                .frame = static_cast<int>(frame),
                .percentage = percentage
            });
    }
}

- (void)svgaPlayer:(SVGAPlayer *)player didAnimatedToPercentage:(CGFloat)percentage
{
    if (_eventEmitter != nullptr) {
        // percentage 已经是 0.0-1.0 范围，转换为 0-100 显示
        CGFloat displayPercentage = percentage * 100.0;
        NSInteger frame = 0;
        if (_currentVideoItem && _currentVideoItem.frames > 0) {
            frame = (NSInteger)(percentage * _currentVideoItem.frames);
        }

        std::dynamic_pointer_cast<const facebook::react::SvgaPlayerViewEventEmitter>(_eventEmitter)
            ->onPercentage(facebook::react::SvgaPlayerViewEventEmitter::OnPercentage{
                .frame = static_cast<int>(frame),
                .percentage = displayPercentage
            });
    }
}

- (void)prepareForRecycle
{
    [super prepareForRecycle];
    
    // 组件即将被回收时清理资源
    [self cleanup];
}

- (void)dealloc
{
    // 组件销毁时确保资源被清理
    [self cleanup];
}

- (void)cleanup
{
    NSLog(@"SvgaPlayerView: Cleaning up resources");
    
    // 停止动画
    if (_svgaPlayer) {
        [_svgaPlayer stopAnimation];
        [_svgaPlayer setVideoItem:nil];
        [_svgaPlayer clear];
        _svgaPlayer.delegate = nil;
        _svgaPlayer = nil;
    }
    
    // 清理其他资源
    _currentVideoItem = nil;
    _currentSource = nil;
}

@end
