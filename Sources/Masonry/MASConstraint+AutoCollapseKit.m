#import "MASConstraint+AutoCollapseKit.h"
#import "ACKConstraintRegistry.h"
#import <objc/runtime.h>
#import <objc/message.h>

/// Creation marker copied to each leaf; Core owns installed constant state.
static char ACKMasonryMarkerKey;

/// Private ac_ hook scoped with autoCollapse to reduce category selector collisions.
/// The hook preserves the original installer without modifying third-party sources.
@interface MASViewConstraint (ACKInstallation)
- (void)ac_autoCollapse_install;
@end

/// Fail visibly when dependency internals differ; never use unchecked KVC access.
static id ACKMasonryObjectGetter(id object, NSString *name) {
    SEL selector = NSSelectorFromString(name);
    if (![object respondsToSelector:selector]) {
        NSCAssert(NO, @"AutoCollapseKit Masonry adapter missing private selector %@.", name);
        NSLog(@"[AutoCollapseKit] Unsupported Masonry internals: %@ on %@", name, [object class]);
        return nil;
    }
    return ((id (*)(id, SEL))objc_msgSend)(object, selector);
}

/// The installation hook is only enabled when the Masonry adapter is actually used.
static void ACKInstallMasonryHook(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method original = class_getInstanceMethod(MASViewConstraint.class, @selector(install));
        Method replacement = class_getInstanceMethod(MASViewConstraint.class, @selector(ac_autoCollapse_install));
        method_exchangeImplementations(original, replacement);
    });
}

/// Mark composites recursively after their children and relation have been configured.
static void ACKMarkMasonry(MASConstraint *constraint, CGFloat constant) {
    NSCAssert(NSThread.isMainThread, @"AutoCollapseKit requires the main thread.");
    if (!NSThread.isMainThread) { return; }
    ACKInstallMasonryHook();
    if ([constraint isKindOfClass:MASCompositeConstraint.class]) {
        NSArray *children = ACKMasonryObjectGetter(constraint, @"childConstraints");
        for (MASConstraint *child in children) { ACKMarkMasonry(child, constant); }
    } else if ([constraint isKindOfClass:MASViewConstraint.class]) {
        objc_setAssociatedObject(constraint, &ACKMasonryMarkerKey, @(constant), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } else {
        NSCAssert(NO, @"AutoCollapseKit cannot mark an unsupported MASConstraint subclass.");
        NSLog(@"[AutoCollapseKit] Unsupported Masonry constraint: %@", [constraint class]);
    }
}

@implementation MASConstraint (AutoCollapseKit)
- (MASConstraint * (^)(void))ac_makeCollapsible {
    return ^MASConstraint * {
        ACKMarkMasonry(self, 0);
        return self;
    };
}
- (MASConstraint * (^)(CGFloat))ac_makeCollapsibleTo {
    return ^MASConstraint *(CGFloat constant) {
        ACKMarkMasonry(self, constant);
        return self;
    };
}
@end

@implementation MASViewConstraint (ACKInstallation)
- (void)ac_autoCollapse_install {
    [self ac_autoCollapse_install];
    NSNumber *marker = objc_getAssociatedObject(self, &ACKMasonryMarkerKey);
    if (!marker) { return; }
    NSLayoutConstraint *native = ACKMasonryObjectGetter(self, @"layoutConstraint");
    if (native) { ac_registerConstraint(native, marker.doubleValue); }
}
@end
