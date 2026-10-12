#if ACK_HAS_MASONRY
#import <XCTest/XCTest.h>
#import <Masonry/Masonry.h>
#import <AutoCollapseKit/AutoCollapseKit.h>
#import <AutoCollapseKit/MASConstraint+AutoCollapseKit.h>

/// Exercises installation, composite recursion and updateExisting on real Masonry.
@interface ACKMasonryTests : XCTestCase
@end
@implementation ACKMasonryTests
/// Finds the native dimension without reaching into Masonry private state in tests.
- (NSLayoutConstraint *)dimension:(NSLayoutAttribute)attribute ofView:(UIView *)view {
    for (NSLayoutConstraint *constraint in view.constraints) {
        if (constraint.firstAttribute == attribute) { return constraint; }
    }
    return nil;
}
/// Composite marking must affect every leaf and preserve latest hidden updates.
- (void)testCompositeHiddenUpdatesAndRemake {
    UIView *view = [UIView new];
    view.ac_autoCollapseWhenHidden = YES;
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@44).ac_makeCollapsible();
    }];
    view.hidden = YES;
    XCTAssertEqual([self dimension:NSLayoutAttributeHeight ofView:view].constant, 0);
    XCTAssertEqual([self dimension:NSLayoutAttributeWidth ofView:view].constant, 0);
    [view mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@88);
    }];
    XCTAssertEqual([self dimension:NSLayoutAttributeHeight ofView:view].constant, 0);
    view.hidden = NO;
    XCTAssertEqual([self dimension:NSLayoutAttributeHeight ofView:view].constant, 88);
    XCTAssertEqual([self dimension:NSLayoutAttributeWidth ofView:view].constant, 88);
    view.hidden = YES;
    [view mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@70).ac_makeCollapsibleTo(2);
    }];
    XCTAssertEqual([self dimension:NSLayoutAttributeHeight ofView:view].constant, 2);
    view.hidden = NO;
    XCTAssertEqual([self dimension:NSLayoutAttributeHeight ofView:view].constant, 70);
}
/// Direct Masonry references must stay marked across uninstall/install cycles.
- (void)testReferenceUpdateAndReinstall {
    UIView *view = [UIView new];
    __block MASConstraint *reference;
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        reference = make.height.equalTo(@44).ac_makeCollapsible();
    }];
    view.ac_autoCollapseWhenHidden = YES;
    view.hidden = YES;
    reference.offset(90);
    view.hidden = NO;
    XCTAssertEqual([self dimension:NSLayoutAttributeHeight ofView:view].constant, 90);
    [reference uninstall];
    view.hidden = YES;
    [reference install];
    XCTAssertEqual([self dimension:NSLayoutAttributeHeight ofView:view].constant, 0);
    view.hidden = NO;
    XCTAssertEqual([self dimension:NSLayoutAttributeHeight ofView:view].constant, 90);
}
@end
#endif
