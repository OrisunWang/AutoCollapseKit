#import "AutoCollapseKit.h"
#import <objc/runtime.h>

/// Keys are unique addresses, independent of category names in other libraries.
static char ACKRecordKey;
/// Stored on UIView; changed only by the public opt-in setter.
static char ACKEnabledKey;
/// Stored on UIView; the registry adds weak constraints and prunes on traversal.
static char ACKConstraintsKey;

/// Per-native-constraint state shared by both adapters, never retaining its view.
@interface ACKCollapseRecord : NSObject
/// Latest external constant write, captured at registration and by the setter hook.
@property (nonatomic) CGFloat expandedConstant;
/// Signed folding constant, changed only by explicit registration/marking.
@property (nonatomic) CGFloat collapsedConstant;
/// First item's owner; weak to avoid making inactive constraints retain UI trees.
@property (nonatomic, weak) UIView *owner;
/// Internal transition nesting; updated around our writes to preserve expanded state.
@property (nonatomic) NSUInteger internalWriteDepth;
@end
@implementation ACKCollapseRecord
@end

/// Reject managed UI operations off the main thread rather than racing associations.
static BOOL ACKCheckMainThread(void) {
    BOOL valid = NSThread.isMainThread;
    NSCAssert(valid, @"AutoCollapseKit managed layout operations require the main thread.");
    return valid;
}

/// Private runtime hooks share the ac_ prefix; autoCollapse scopes their selectors to this library.
/// Each exchanged hook always chains the original IMP.
@interface UIView (ACKRuntime)
- (void)ac_autoCollapse_setHidden:(BOOL)hidden;
@end
/// The native setter captures writes from both libraries without intercepting Swift.
@interface NSLayoutConstraint (ACKRuntime)
- (void)ac_autoCollapse_setConstant:(CGFloat)constant;
@end

/// Works even when the original implementation is inherited; no superclass is changed.
static void ACKExchange(Class cls, SEL original, SEL replacement) {
    Method oldMethod = class_getInstanceMethod(cls, original);
    Method newMethod = class_getInstanceMethod(cls, replacement);
    if (class_addMethod(cls, original, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(cls, replacement, method_getImplementation(oldMethod), method_getTypeEncoding(oldMethod));
    } else {
        method_exchangeImplementations(oldMethod, newMethod);
    }
}

/// Lazily install exactly once, avoiding any runtime side effect for unused Core.
static void ACKInstallRuntime(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ACKExchange(UIView.class, @selector(setHidden:), @selector(ac_autoCollapse_setHidden:));
        ACKExchange(NSLayoutConstraint.class, @selector(setConstant:), @selector(ac_autoCollapse_setConstant:));
    });
}

/// Returns the opt-in flag without invoking public accessors from inside hooks.
static BOOL ACKEnabled(UIView *view) {
    return [objc_getAssociatedObject(view, &ACKEnabledKey) boolValue];
}

/// State is evaluated live so changing the opt-in flag immediately restores values.
static BOOL ACKShouldFold(ACKCollapseRecord *record) {
    UIView *owner = record.owner;
    return owner && ACKEnabled(owner) && owner.isHidden;
}

/// Own writes bypass expanded-value capture and do not change constraint activation.
static void ACKApply(NSLayoutConstraint *constraint, ACKCollapseRecord *record) {
    CGFloat target = ACKShouldFold(record) ? record.collapsedConstant : record.expandedConstant;
    if (constraint.constant == target) { return; }
    record.internalWriteDepth += 1;
    @try {
        constraint.constant = target;
    } @finally {
        record.internalWriteDepth -= 1;
    }
}

/// Snapshot weak members to keep them alive during a single synchronous transition.
static void ACKSynchronize(UIView *view) {
    NSHashTable<NSLayoutConstraint *> *table = objc_getAssociatedObject(view, &ACKConstraintsKey);
    for (NSLayoutConstraint *constraint in table.allObjects) {
        ACKCollapseRecord *record = objc_getAssociatedObject(constraint, &ACKRecordKey);
        if (record.owner == view) { ACKApply(constraint, record); }
    }
}

/// Layout guides follow their owning view; an unattached guide cannot be registered.
static UIView *ACKOwner(NSLayoutConstraint *constraint) {
    id firstItem = constraint.firstItem;
    if ([firstItem isKindOfClass:UIView.class]) { return firstItem; }
    if ([firstItem isKindOfClass:UILayoutGuide.class]) { return [firstItem owningView]; }
    return nil;
}

void ac_registerConstraint(NSLayoutConstraint *constraint, CGFloat collapsedConstant) {
    if (!ACKCheckMainThread()) { return; }
    if (!isfinite(collapsedConstant)) {
        NSCAssert(NO, @"AutoCollapseKit requires a finite collapsed constant.");
        NSLog(@"[AutoCollapseKit] Ignoring non-finite collapsed constant.");
        return;
    }
    UIView *owner = ACKOwner(constraint);
    if (!owner) {
        NSCAssert(NO, @"AutoCollapseKit requires a UIView first item or an attached UILayoutGuide.");
        NSLog(@"[AutoCollapseKit] Cannot resolve constraint owner: %@", constraint);
        return;
    }
    ACKInstallRuntime();
    ACKCollapseRecord *record = objc_getAssociatedObject(constraint, &ACKRecordKey);
    if (!record) {
        record = [ACKCollapseRecord new];
        record.expandedConstant = constraint.constant;
        record.owner = owner;
        objc_setAssociatedObject(constraint, &ACKRecordKey, record, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } else if (record.owner != owner) {
        // Guides can move owners; detach the previous weak registration before transfer.
        NSHashTable *oldTable = objc_getAssociatedObject(record.owner, &ACKConstraintsKey);
        [oldTable removeObject:constraint];
        record.owner = owner;
    }
    record.collapsedConstant = collapsedConstant;
    NSHashTable *table = objc_getAssociatedObject(owner, &ACKConstraintsKey);
    if (!table) {
        table = [NSHashTable weakObjectsHashTable];
        objc_setAssociatedObject(owner, &ACKConstraintsKey, table, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [table addObject:constraint];
    ACKApply(constraint, record);
}

@implementation UIView (AutoCollapseKit)
- (BOOL)ac_autoCollapseWhenHidden {
    if (!ACKCheckMainThread()) { return NO; }
    return ACKEnabled(self);
}
- (void)setAc_autoCollapseWhenHidden:(BOOL)enabled {
    if (!ACKCheckMainThread()) { return; }
    ACKInstallRuntime();
    objc_setAssociatedObject(self, &ACKEnabledKey, @(enabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    ACKSynchronize(self);
}
@end

@implementation UIView (ACKRuntime)
- (void)ac_autoCollapse_setHidden:(BOOL)hidden {
    BOOL managed = ACKEnabled(self);
    if (managed && !ACKCheckMainThread()) { return; }
    [self ac_autoCollapse_setHidden:hidden];
    // Repeated assignments deliberately synchronize without recapturing expanded values.
    if (managed) { ACKSynchronize(self); }
}
@end

@implementation NSLayoutConstraint (ACKRuntime)
- (void)ac_autoCollapse_setConstant:(CGFloat)constant {
    ACKCollapseRecord *record = objc_getAssociatedObject(self, &ACKRecordKey);
    if (!record || record.internalWriteDepth > 0) {
        [self ac_autoCollapse_setConstant:constant];
        return;
    }
    if (!ACKCheckMainThread()) { return; }
    // Record the requested value even if it equals the currently folded value.
    record.expandedConstant = constant;
    [self ac_autoCollapse_setConstant:ACKShouldFold(record) ? record.collapsedConstant : constant];
}
@end

@implementation NSLayoutConstraint (AutoCollapseKit)
- (instancetype)ac_makeCollapsible {
    return [self ac_makeCollapsibleTo:0];
}
- (instancetype)ac_makeCollapsibleTo:(CGFloat)constant {
    ac_registerConstraint(self, constant);
    return self;
}
@end
