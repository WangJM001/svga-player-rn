#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>
#import <SVGAPlayer/SVGAPlayer.h>

#ifndef SvgaPlayerViewNativeComponent_h
#define SvgaPlayerViewNativeComponent_h

NS_ASSUME_NONNULL_BEGIN

@interface SvgaPlayerView : RCTViewComponentView <SVGAPlayerDelegate>

// Commands
- (void)startAnimation;
- (void)startAnimationWithRange:(NSInteger)location length:(NSInteger)length reverse:(BOOL)reverse;
- (void)pauseAnimation;
- (void)stopAnimation;
- (void)stepToFrame:(NSInteger)frame andPlay:(BOOL)andPlay;
- (void)stepToPercentage:(CGFloat)percentage andPlay:(BOOL)andPlay;

@end

NS_ASSUME_NONNULL_END

#endif /* SvgaPlayerViewNativeComponent_h */
