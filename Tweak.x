#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <SpringBoard/SpringBoard.h> // 导入 SpringBoard 头文件

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
                                    CFSTR("com.zocodo.automirrordisplay.prefs.changed"),
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

// 处理设置变化
- (void)handlePreferencesChanged {
    // 重新配置显示模式
    [self configureDisplayMode];
    LogIfEnabled(@"Preferences changed, reconfiguring display mode.");
}

%end

// C 函数作为回调
void handlePreferencesChanged(CFNotificationCenterRef center, 
                               void *observer, 
                               CFNotificationName name, 
                               const void *object, 
                               CFDictionaryRef userInfo) {
    // 获取 SpringBoard 实例并调用方法
    SpringBoard *sb = (SpringBoard *)observer;
    [sb handlePreferencesChanged];
} 