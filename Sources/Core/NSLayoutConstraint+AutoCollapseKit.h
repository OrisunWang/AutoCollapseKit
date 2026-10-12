#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
/// Native Auto Layout counterpart of the two optional DSL adapters.
@interface NSLayoutConstraint (AutoCollapseKit)
/// Registers this constraint with its first item's view, folding its constant to zero.
- (instancetype)ac_makeCollapsible NS_SWIFT_NAME(ac_makeCollapsible());
/// Registers a signed raw constant; repeated marking preserves the expanded value.
- (instancetype)ac_makeCollapsibleTo:(CGFloat)constant NS_SWIFT_NAME(ac_makeCollapsibleTo(_:));
@end
NS_ASSUME_NONNULL_END
