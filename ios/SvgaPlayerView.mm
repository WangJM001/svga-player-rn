#import "SvgaPlayerView.h"

#import <react/renderer/components/SvgaPlayerViewSpec/ComponentDescriptors.h>
#import <react/renderer/components/SvgaPlayerViewSpec/EventEmitters.h>
#import <react/renderer/components/SvgaPlayerViewSpec/Props.h>
#import <react/renderer/components/SvgaPlayerViewSpec/RCTComponentViewHelpers.h>

#import <SVGAPlayer/SVGAPlayer.h>
#import <SVGAPlayer/SVGAParser.h>
#import <SVGAPlayer/SVGAVideoEntity.h>

using namespace facebook::react;

@interface SvgaPlayerView () <RCTSvgaPlayerViewViewProtocol, SVGAPlayerDelegate>

@end

@implementation SvgaPlayerView {
    SVGAPlayer * _svgaPlayer;
    NSString * _currentSource;
    BOOL _autoPlay;
    NSInteger _loops;
    BOOL _clearsAfterStop;
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

    NSLog(@"🏗️ SvgaPlayer: Initializing with frame");

    _svgaPlayer = [[SVGAPlayer alloc] init];
    _svgaPlayer.delegate = self;
    _svgaPlayer.loops = 0; // 默认无限循环
    _svgaPlayer.clearsAfterStop = YES; // 默认停止后清空画布

    // 设置合理的默认值，实际值会在 updateProps 中设置
    _autoPlay = NO; // 默认不自动播放，等待 props 更新
    _loops = 0; // 默认无限循环
    _clearsAfterStop = YES; // 默认停止后清空画布

    self.contentView = _svgaPlayer;

    NSLog(@"✅ SvgaPlayer: Initialization completed");
  }

  return self;
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
    const auto &oldViewProps = *std::static_pointer_cast<SvgaPlayerViewProps const>(_props);
    const auto &newViewProps = *std::static_pointer_cast<SvgaPlayerViewProps const>(props);

    // 处理 autoPlay 属性 (包括初始设置)
    if (oldProps == nullptr || oldViewProps.autoPlay != newViewProps.autoPlay) {
        _autoPlay = newViewProps.autoPlay;
        NSLog(@"SvgaPlayer: AutoPlay set to: %@", _autoPlay ? @"YES" : @"NO");
    }

    // 处理 loops 属性 (包括初始设置)
    if (oldProps == nullptr || oldViewProps.loops != newViewProps.loops) {
        _loops = newViewProps.loops;
        _svgaPlayer.loops = _loops;
        NSLog(@"SvgaPlayer: Loops set to: %ld", (long)_loops);
    }

    // 处理 clearsAfterStop 属性 (包括初始设置)
    if (oldProps == nullptr || oldViewProps.clearsAfterStop != newViewProps.clearsAfterStop) {
        _clearsAfterStop = newViewProps.clearsAfterStop;
        _svgaPlayer.clearsAfterStop = _clearsAfterStop;
        NSLog(@"SvgaPlayer: ClearsAfterStop set to: %@", _clearsAfterStop ? @"YES" : @"NO");
    }

    // 处理 source 属性 (包括初始设置)
    if (oldProps == nullptr || oldViewProps.source != newViewProps.source) {
        NSString *newSource = newViewProps.source.empty() ? nil : [[NSString alloc] initWithUTF8String:newViewProps.source.c_str()];
        if (newSource && ![newSource isEqualToString:_currentSource]) {
            _currentSource = newSource;
            NSLog(@"SvgaPlayer: Loading source: %@, autoPlay: %@", newSource, _autoPlay ? @"YES" : @"NO");
            [self loadSVGAFromSource:newSource];
        } else if (newSource == nil && _currentSource != nil) {
            // 清空源 - 彻底清理
            NSLog(@"🚫 SvgaPlayer: Source cleared, cleaning up completely");
            _currentSource = nil;
            [self cleanup];
            // 显式地清空画布
            if (_svgaPlayer) {
                [_svgaPlayer clear];
            }
        }
    }

    [super updateProps:props oldProps:oldProps];
}

Class<RCTComponentViewProtocol> SvgaPlayerViewCls(void)
{
    return SvgaPlayerView.class;
}

// 辅助方法：发送事件
- (void)sendErrorEvent:(NSString *)errorMessage
{
    // 清空当前的 VideoItem 和画布
    [_svgaPlayer stopAnimation];
    [_svgaPlayer setVideoItem:nil];
    [_svgaPlayer clear];
    _currentVideoItem = nil;

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
        NSLog(@"SvgaPlayer: Empty source provided");
        return;
    }

    NSLog(@"SvgaPlayer: Loading SVGA from source: %@", source);
    SVGAParser *parser = [[SVGAParser alloc] init];

    // 判断文件类型并加载（与 Android 端保持一致）
    if ([source hasPrefix:@"http://"] || [source hasPrefix:@"https://"]) {
        // 远程 URL
        NSLog(@"SvgaPlayer: Loading from URL: %@", source);
        [self loadSVGAFromURL:source withParser:parser];
    } else if ([source hasPrefix:@"file://"]) {
        // file:// 协议的本地文件
        NSLog(@"SvgaPlayer: Loading from file URL: %@", source);
        [self loadSVGAFromFileURL:source withParser:parser];
    } else {
        // Assets 文件（默认情况）
        NSLog(@"SvgaPlayer: Loading from bundle assets: %@", source);
        [self loadSVGAFromBundle:source withParser:parser];
    }
}

- (void)loadSVGAFromURL:(NSString *)urlString withParser:(SVGAParser *)parser
{
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        NSLog(@"SvgaPlayer: Invalid URL: %@", urlString);
        [self sendErrorEvent:[NSString stringWithFormat:@"Invalid URL: %@", urlString]];
        return;
    }

    NSLog(@"SvgaPlayer: Starting download from URL: %@", urlString);
    [parser parseWithURL:url completionBlock:^(SVGAVideoEntity * _Nullable videoItem) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (videoItem) {
                NSLog(@"SvgaPlayer: Successfully loaded SVGA from URL, frames: %lu", (unsigned long)videoItem.frames);
                self->_currentVideoItem = videoItem;

                // 确保delegate被正确设置
                self->_svgaPlayer.delegate = self;
                [self->_svgaPlayer setVideoItem:videoItem];

                if (self->_autoPlay) {
                    NSLog(@"SvgaPlayer: Auto-playing animation");
                    [self->_svgaPlayer startAnimation];
                }
            } else {
                NSLog(@"SvgaPlayer: Video item is nil after parsing URL");
                [self sendErrorEvent:@"Failed to parse SVGA from URL"];
            }
        });
    } failureBlock:^(NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"SvgaPlayer: SVGA load from URL error: %@", error.localizedDescription);
            [self sendErrorEvent:[NSString stringWithFormat:@"Failed to load SVGA from URL: %@", error.localizedDescription]];
        });
    }];
}

- (void)loadSVGAFromFileURL:(NSString *)fileURLString withParser:(SVGAParser *)parser
{
    NSURL *fileURL = [NSURL URLWithString:fileURLString];
    if (!fileURL) {
        NSLog(@"SvgaPlayer: Invalid file URL: %@", fileURLString);
        [self sendErrorEvent:[NSString stringWithFormat:@"Invalid file URL: %@", fileURLString]];
        return;
    }

    NSString *filePath = fileURL.path;
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    NSLog(@"SvgaPlayer: Checking file at path: %@, exists: %@", filePath, fileExists ? @"YES" : @"NO");

    if (!fileExists) {
        NSLog(@"SvgaPlayer: SVGA file not found at: %@", fileURLString);
        [self sendErrorEvent:[NSString stringWithFormat:@"SVGA file not found at: %@", fileURLString]];
        return;
    }

    NSLog(@"SvgaPlayer: Loading SVGA from file URL: %@", fileURLString);
    [parser parseWithURL:fileURL completionBlock:^(SVGAVideoEntity * _Nullable videoItem) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (videoItem) {
                NSLog(@"SvgaPlayer: Successfully loaded SVGA from file, frames: %lu", (unsigned long)videoItem.frames);
                self->_currentVideoItem = videoItem;

                // 确保delegate被正确设置
                self->_svgaPlayer.delegate = self;
                [self->_svgaPlayer setVideoItem:videoItem];

                if (self->_autoPlay) {
                    NSLog(@"SvgaPlayer: Auto-playing animation");
                    [self->_svgaPlayer startAnimation];
                }
            } else {
                NSLog(@"SvgaPlayer: Video item is nil after parsing file");
                [self sendErrorEvent:@"Failed to parse SVGA from file"];
            }
        });
    } failureBlock:^(NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"SvgaPlayer: SVGA load from file URL error: %@", error.localizedDescription);
            [self sendErrorEvent:[NSString stringWithFormat:@"Failed to load SVGA from file URL: %@", error.localizedDescription]];
        });
    }];
}

- (void)loadSVGAFromBundle:(NSString *)fileName withParser:(SVGAParser *)parser
{
    NSLog(@"SvgaPlayer: Loading SVGA from bundle: %@", fileName);
    // 去掉文件扩展名
    NSString *fileNameWithoutExtension = [fileName stringByDeletingPathExtension];

    [parser parseWithNamed:fileNameWithoutExtension inBundle:nil completionBlock:^(SVGAVideoEntity * _Nullable videoItem) {
      dispatch_async(dispatch_get_main_queue(), ^{
        if (videoItem) {
          NSLog(@"SvgaPlayer: Successfully loaded SVGA from bundle, frames: %lu", (unsigned long)videoItem.frames);
          self->_currentVideoItem = videoItem;

          // 确保delegate被正确设置
          self->_svgaPlayer.delegate = self;
          [self->_svgaPlayer setVideoItem:videoItem];

          if (self->_autoPlay) {
            NSLog(@"SvgaPlayer: Auto-playing animation");
            [self->_svgaPlayer startAnimation];
          }
        } else {
          NSLog(@"SvgaPlayer: Video item is nil after parsing bundle");
          [self sendErrorEvent:@"Failed to parse SVGA from bundle"];
        }
      });
    } failureBlock:^(NSError * _Nonnull error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"SvgaPlayer: SVGA load from bundle error: %@", error.localizedDescription);
            [self sendErrorEvent:[NSString stringWithFormat:@"Failed to load SVGA from bundle: %@", error.localizedDescription]];
        });
    }];
}

// Command methods
- (void)startAnimation
{
    NSLog(@"SvgaPlayer: *** startAnimation CALLED FROM JS ***");
    [_svgaPlayer startAnimation];
}

- (void)stopAnimation
{
    NSLog(@"SvgaPlayer: *** stopAnimation CALLED FROM JS ***");
    [_svgaPlayer stopAnimation];
}

// 处理来自 JavaScript 的命令调用
- (void)handleCommand:(const NSString *)commandName args:(const NSArray *)args
{
    NSLog(@"SvgaPlayer: Received command: %@", commandName);

    if ([commandName isEqualToString:@"startAnimation"]) {
        [self startAnimation];
    } else if ([commandName isEqualToString:@"stopAnimation"]) {
        [self stopAnimation];
    }
}

// SVGAPlayerDelegate methods
- (void)svgaPlayerDidFinishedAnimation:(SVGAPlayer *)player
{
    // 检查播放器是否还有效
    if (!_svgaPlayer || player != _svgaPlayer) {
        NSLog(@"⚠️ SvgaPlayer: Received callback from invalid player, ignoring");
        return;
    }

    // 检查事件发送器是否还有效
    if (_eventEmitter == nullptr) {
        NSLog(@"⚠️ SvgaPlayer: Event emitter is null, cannot send finished event");
        return;
    }

    NSLog(@"🏁 SvgaPlayer: Animation finished");

    std::dynamic_pointer_cast<const facebook::react::SvgaPlayerViewEventEmitter>(_eventEmitter)
        ->onFinished(facebook::react::SvgaPlayerViewEventEmitter::OnFinished{
            .finished = true
        });
}

// React Native Fabric 生命周期方法
- (void)prepareForRecycle
{
    [super prepareForRecycle];
    NSLog(@"🔄 SvgaPlayer: prepareForRecycle called - cleaning up");

    // 组件即将被回收时清理资源
    [self cleanup];
}

// 组件销毁时调用
- (void)dealloc
{
    NSLog(@"💀 SvgaPlayer: dealloc called - final cleanup");

    // 组件销毁时确保资源被彻底清理
    [self finalCleanup];
}

// 当视图从父视图移除时调用
- (void)removeFromSuperview
{
    NSLog(@"🗑️ SvgaPlayer: removeFromSuperview called - cleaning up");

    // 从父视图移除时清理资源
    [self cleanup];
    [super removeFromSuperview];
}

// 当视图被标记为即将移除时调用
- (void)willMoveToSuperview:(UIView *)newSuperview
{
    // 如果新的父视图是 nil，说明视图即将被移除
    if (newSuperview == nil) {
        NSLog(@"🚫 SvgaPlayer: willMoveToSuperview nil - cleaning up");
        [self cleanup];
    } else {
        NSLog(@"📱 SvgaPlayer: willMoveToSuperview - new parent view");
    }
    [super willMoveToSuperview:newSuperview];
}

// 常规清理方法（保持视图结构，只清理动画状态）
- (void)cleanup
{
    NSLog(@"🧹 SvgaPlayer: Cleaning up resources");

    // 停止动画并清理所有资源
    if (_svgaPlayer) {
        [_svgaPlayer stopAnimation];
        [_svgaPlayer setVideoItem:nil];
        [_svgaPlayer clear];

        // 注意：不设置 delegate = nil，这样动画完成事件仍能正常回调
        // delegate 只在 finalCleanup (dealloc) 时设置为 nil

        NSLog(@"🛑 SvgaPlayer: Animation stopped and resources cleared (delegate preserved)");

        // 注意：不设置 _svgaPlayer = nil，因为它是 contentView
        // 只是停止动画和清理内容，但保持视图结构
    }

    // 清理其他资源
    _currentVideoItem = nil;
    _currentSource = nil;
}

// 最终清理方法（用于 dealloc，完全释放资源）
- (void)finalCleanup
{
    NSLog(@"💣 SvgaPlayer: Final cleanup for dealloc");

    // 先调用常规清理
    if (_svgaPlayer) {
        [_svgaPlayer stopAnimation];
        [_svgaPlayer setVideoItem:nil];
        [_svgaPlayer clear];
        _svgaPlayer.delegate = nil;

        NSLog(@"🛑 SvgaPlayer: Animation stopped in final cleanup");

        // 从视图层次结构中移除
        if (_svgaPlayer.superview) {
            [_svgaPlayer removeFromSuperview];
            NSLog(@"🗑️ SvgaPlayer: Removed from superview in final cleanup");
        }

        // 在 dealloc 时可以设置为 nil
        _svgaPlayer = nil;
        NSLog(@"🚮 SvgaPlayer: Player instance set to nil");
    }

    // 清理其他资源
    _currentVideoItem = nil;
    _currentSource = nil;
}

@end
