#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
/// Opt-in hidden folding for UIKit; only explicitly marked constraints change.
@interface UIView (AutoCollapseKit)
/// Updated by the caller on the main thread. Turning off restores the latest
/// expanded constants without removing their markers. Defaults to NO.
@property (nonatomic) IBInspectable BOOL ac_autoCollapseWhenHidden;
@end
NS_ASSUME_NONNULL_END
