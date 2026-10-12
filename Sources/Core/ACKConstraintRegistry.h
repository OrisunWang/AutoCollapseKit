#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
/// Public low-level adapter bridge; shares the ac_ prefix with category and Swift APIs.
/// Call on the main thread after the full constraint is configured.
/// Registration preserves activation state and uses weak view/constraint ownership.
FOUNDATION_EXPORT void ac_registerConstraint(NSLayoutConstraint *constraint, CGFloat collapsedConstant);
NS_ASSUME_NONNULL_END
