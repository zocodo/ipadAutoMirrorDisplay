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

    BOOL mirror = IsMirrorModeEnabled();
    SBExternalDisplayManager *mgr = [%c(SBExternalDisplayManager) sharedInstance];
    // mirror==YES 时要镜像，内部 API 用 setWantsExtendedDisplay:NO；mirror==NO 时扩展，用 YES
    [mgr setWantsExtendedDisplay:!mirror];

    LogIfEnabled(@"Display mode set to %@", mirror ? @"Mirror" : @"Extend");
}

%end
