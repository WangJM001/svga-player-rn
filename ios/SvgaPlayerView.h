#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>
#import <SVGAPlayer/SVGAPlayer.h>

#ifndef SvgaPlayerViewNativeComponent_h
#define SvgaPlayerViewNativeComponent_h

NS_ASSUME_NONNULL_BEGIN

@interface SvgaPlayerView : RCTViewComponentView <SVGAPlayerDelegate>

// Commands
- (void)startAnimation;
- (void)stopAnimation;

@end

NS_ASSUME_NONNULL_END

#endif /* SvgaPlayerViewNativeComponent_h */
