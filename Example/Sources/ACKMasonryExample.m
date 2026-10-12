#import "ACKMasonryExample.h"
#import <Masonry/Masonry.h>
#import <AutoCollapseKit/MASConstraint+AutoCollapseKit.h>

@implementation ACKMasonryExample
+ (void)installHeightForView:(UIView *)view value:(CGFloat)value {
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(value)).ac_makeCollapsible();
    }];
}
+ (void)installTopForView:(UIView *)view below:(UIView *)previous {
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(previous.mas_bottom).offset(12).ac_makeCollapsible();
    }];
}
+ (void)updateHeightForView:(UIView *)view value:(CGFloat)value {
    [view mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(value));
    }];
}
@end
