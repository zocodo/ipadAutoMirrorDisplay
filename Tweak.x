#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// 私有接口声明
@interface SBExternalDisplayManager : NSObject
+ (instancetype)sharedInstance;
- (void)setWantsExtendedDisplay:(BOOL)extend;
@end

// 读取配置
static BOOL IsMirrorModeEnabled() {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"mirrorMode"];
}
static BOOL IsLoggingEnabled() {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"logEnabled"];
}
static void LogIfEnabled(NSString *format, ...) {
    if (!IsLoggingEnabled()) return;
    va_list args;
    va_start(args, format);
    NSLogv([@"[AutoMirrorDisplay] " stringByAppendingString:format], args);
    va_end(args);
}
%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;

    // 注册默认设置
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"mirrorMode": @NO, @"logEnabled": @NO}];
    
    // 监听设置变化
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    NULL,
                                    (CFNotificationCallback)handlePreferencesChanged,
                                    CFSTR("com.your.tweak.prefs.changed"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
    
    // 初始配置
    [self configureDisplayMode];
}

- (void)configureDisplayMode {
    BOOL mirror = IsMirrorModeEnabled();
    SBExternalDisplayManager *mgr = [%c(SBExternalDisplayManager) sharedInstance];
    if (mgr && [mgr respondsToSelector:@selector(setWantsExtendedDisplay:)]) {
        [mgr setWantsExtendedDisplay:!mirror];
        LogIfEnabled(@"Display mode set to %@", mirror ? @"Mirror" : @"Extend");
    } else {
        LogIfEnabled(@"Error: Display configuration failed.");
    }
}

%end

// 偏好设置变化回调
static void handlePreferencesChanged() {
    [[NSUserDefaults standardUserDefaults] synchronize];
    SpringBoard *springBoard = [UIApplication sharedApplication];
    [springBoard configureDisplayMode];
}
