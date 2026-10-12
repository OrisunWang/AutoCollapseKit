#import <Masonry/Masonry.h>

NS_ASSUME_NONNULL_BEGIN
/// Creation-time terminal markers, including composite Masonry constraints.
@interface MASConstraint (AutoCollapseKit)
/// Caller marks all children with a zero folded constant before installation.
- (MASConstraint * (^)(void))ac_makeCollapsible;
/// Caller supplies a signed native constant; update calls inherit existing markers.
- (MASConstraint * (^)(CGFloat constant))ac_makeCollapsibleTo;
@end
NS_ASSUME_NONNULL_END
