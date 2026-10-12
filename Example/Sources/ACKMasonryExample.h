#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
/// Objective-C demo bridge also used by the mixed-adapter XCTest target.
@interface ACKMasonryExample : NSObject
/// Installs a marked height only; callers choose Masonry-only or mixed ownership.
+ (void)installHeightForView:(UIView *)view value:(CGFloat)value NS_SWIFT_NAME(installHeight(on:value:));
/// Installs a marked top spacing whose first item is the folding view.
+ (void)installTopForView:(UIView *)view below:(UIView *)previous NS_SWIFT_NAME(installTop(on:below:));
/// Updates a previously marked height without marking a temporary update description.
+ (void)updateHeightForView:(UIView *)view value:(CGFloat)value NS_SWIFT_NAME(updateHeight(on:value:));
@end
NS_ASSUME_NONNULL_END
