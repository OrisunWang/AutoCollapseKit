#import <UIKit/UIKit.h>

/// Minimal UIKit host so unit tests execute real layout APIs on the simulator.
@interface ACKValidationAppDelegate : UIResponder <UIApplicationDelegate>
/// Created on launch by this delegate; UIKit uses it to retain the host scene.
@property (nonatomic, strong) UIWindow *window;
@end
@implementation ACKValidationAppDelegate
/// Test hosting only; no product layout or layout-library dependency is introduced.
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options {
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.rootViewController = [UIViewController new];
    [self.window makeKeyAndVisible];
    return YES;
}
@end
/// Starts the UIKit host selected by Xcode's test runner.
int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass(ACKValidationAppDelegate.class));
    }
}
