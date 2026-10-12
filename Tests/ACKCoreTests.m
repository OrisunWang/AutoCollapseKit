#import <XCTest/XCTest.h>
#import <AutoCollapseKit/AutoCollapseKit.h>

/// Exercises actual native constraints so both DSL adapters inherit these guarantees.
@interface ACKCoreTests : XCTestCase
@end
@implementation ACKCoreTests
/// Switching state never overwrites the latest requested expanded constant.
- (void)testHiddenUpdateRepeatedStatesAndDisable {
    UIView *view = [UIView new];
    NSLayoutConstraint *height = [view.heightAnchor constraintEqualToConstant:44];
    [height ac_makeCollapsible];
    XCTAssertFalse(view.ac_autoCollapseWhenHidden);
    view.hidden = YES;
    XCTAssertEqual(height.constant, 44);
    view.ac_autoCollapseWhenHidden = YES;
    XCTAssertEqual(height.constant, 0);
    height.constant = 88;
    XCTAssertEqual(height.constant, 0);
    view.hidden = YES;
    view.ac_autoCollapseWhenHidden = YES;
    XCTAssertEqual(height.constant, 0);
    view.hidden = NO;
    XCTAssertEqual(height.constant, 88);
    view.hidden = YES;
    view.ac_autoCollapseWhenHidden = NO;
    XCTAssertEqual(height.constant, 88);
    view.ac_autoCollapseWhenHidden = YES;
    XCTAssertEqual(height.constant, 0);
    view.hidden = NO;
    height.constant = 96;
    view.hidden = YES;
    view.hidden = NO;
    XCTAssertEqual(height.constant, 96);
}
/// A folded raw negative value does not imply inset conversion or size constraints.
- (void)testNegativeConstantUnmarkedConstraintAndRepeatedMark {
    UIView *view = [UIView new];
    NSLayoutConstraint *marked = [view.heightAnchor constraintEqualToConstant:44];
    NSLayoutConstraint *unmarked = [view.widthAnchor constraintEqualToConstant:100];
    view.ac_autoCollapseWhenHidden = YES;
    // Exercise the public ac_ bridge directly; category markers use this same registry.
    ac_registerConstraint(marked, -8);
    view.hidden = YES;
    XCTAssertEqual(marked.constant, -8);
    XCTAssertEqual(unmarked.constant, 100);
    [marked ac_makeCollapsibleTo:-4];
    XCTAssertEqual(marked.constant, -4);
    view.hidden = NO;
    XCTAssertEqual(marked.constant, 44);
    XCTAssertEqual(view.constraints.count, 0);
}
/// Late registration and activation preserve state without activating as a side effect.
- (void)testInitiallyHiddenLateRegistrationAndReactivation {
    UIView *view = [UIView new];
    view.hidden = YES;
    view.ac_autoCollapseWhenHidden = YES;
    NSLayoutConstraint *height = [view.heightAnchor constraintEqualToConstant:50];
    [height ac_makeCollapsible];
    XCTAssertFalse(height.active);
    XCTAssertEqual(height.constant, 0);
    height.active = YES;
    height.active = NO;
    height.constant = 70;
    view.hidden = NO;
    XCTAssertEqual(height.constant, 70);
    height.active = YES;
    XCTAssertEqual(height.constant, 70);
    height.active = NO;
}
/// Layout guides use their owning view, not an unrelated second item.
- (void)testLayoutGuideOwnerAndParentHiddenIsolation {
    UIView *parent = [UIView new];
    UIView *view = [UIView new];
    [parent addSubview:view];
    UILayoutGuide *guide = [UILayoutGuide new];
    [view addLayoutGuide:guide];
    NSLayoutConstraint *width = [guide.widthAnchor constraintEqualToConstant:60];
    [width ac_makeCollapsible];
    view.ac_autoCollapseWhenHidden = YES;
    parent.hidden = YES;
    XCTAssertEqual(width.constant, 60);
    view.hidden = YES;
    XCTAssertEqual(width.constant, 0);
    view.hidden = NO;
    XCTAssertEqual(width.constant, 60);
}
/// Weak registry membership must not keep inactive constraints or views alive.
- (void)testRegistryDoesNotRetainViewsOrConstraints {
    __weak UIView *weakView;
    __weak NSLayoutConstraint *weakConstraint;
    @autoreleasepool {
        UIView *view = [UIView new];
        NSLayoutConstraint *height = [view.heightAnchor constraintEqualToConstant:44];
        [height ac_makeCollapsible];
        view.ac_autoCollapseWhenHidden = YES;
        weakView = view;
        weakConstraint = height;
    }
    XCTAssertNil(weakView);
    XCTAssertNil(weakConstraint);
}
/// A latest requested expanded value equal to the folded value is still meaningful.
- (void)testUpdateToTheFoldedValue {
    UIView *view = [UIView new];
    NSLayoutConstraint *height = [view.heightAnchor constraintEqualToConstant:44];
    [height ac_makeCollapsible];
    view.ac_autoCollapseWhenHidden = YES;
    view.hidden = YES;
    height.constant = 0;
    view.hidden = NO;
    XCTAssertEqual(height.constant, 0);
}
@end
