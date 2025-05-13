/* How to Hook with Logos
Hooks are written with syntax similar to that of an Objective-C @implementation.
You don't need to #include <substrate.h>, it will be done automatically, as will
the generation of a class list and an automatic constructor.

%hook ClassName

// Hooking a class method
+ (id)sharedInstance {
	return %orig;
}

// Hooking an instance method with an argument.
- (void)messageName:(int)argument {
	%log; // Write a message about this call, including its class, name and arguments, to the system log.

	%orig; // Call through to the original function with its original arguments.
	%orig(nil); // Call through to the original function with a custom argument.

	// If you use %orig(), you MUST supply all arguments (except for self and _cmd, the automatically generated ones.)
}

// Hooking an instance method with no arguments.
- (id)noArguments {
	%log;
	id awesome = %orig;
	[awesome doSomethingElse];

	return awesome;
}

// Always make sure you clean up after yourself; Not doing so could have grave consequences!
%end
*/

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// 日志管理
@interface LogManager : NSObject
+ (instancetype)sharedInstance;
- (void)addLog:(NSString *)log;
- (NSArray *)getLogs;
@end

@implementation LogManager {
    NSMutableArray *_logs;
}

+ (instancetype)sharedInstance {
    static LogManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LogManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        _logs = [NSMutableArray array];
    }
    return self;
}

- (void)addLog:(NSString *)log {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    NSString *timeString = [formatter stringFromDate:[NSDate date]];
    NSString *logEntry = [NSString stringWithFormat:@"[%@] %@", timeString, log];
    [_logs addObject:logEntry];
    
    // 保持最近的50条日志
    if (_logs.count > 50) {
        [_logs removeObjectAtIndex:0];
    }
    
    // 保存到UserDefaults
    [[NSUserDefaults standardUserDefaults] setObject:_logs forKey:@"com.zocodo.ipad-auto-mirror-display.logs"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray *)getLogs {
    return [_logs copy];
}

@end

// UIScreen分类声明
@interface UIScreen (MirrorAdditions)
- (BOOL)isMirrored;
- (void)setMirrored:(BOOL)mirrored;
@end

// 监听显示器连接状态
%hook UIScreen

- (void)setMirrored:(BOOL)mirrored {
    %log;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"enabled"]) {
        %orig;
        [[LogManager sharedInstance] addLog:[NSString stringWithFormat:@"镜像模式已%@", mirrored ? @"开启" : @"关闭"]];
    }
}

- (void)setCurrentMode:(UIScreenMode *)mode {
    %log;
    %orig;
}

%end

// 监听显示器连接
@interface UIScreen (DisplayConnection)
- (void)_updateDisplayConnection;
@end

%hook UIScreen

- (void)_updateDisplayConnection {
    %log;
    %orig;
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"enabled"]) {
        return;
    }
    
    // 获取所有屏幕
    NSArray *screens = [UIScreen screens];
    if (screens.count > 1) {
        // 有外接显示器连接
        UIScreen *mainScreen = [UIScreen mainScreen];
        if (![mainScreen isMirrored]) {
            // 如果当前不是镜像模式，则切换到镜像模式
            [[LogManager sharedInstance] addLog:@"检测到外接显示器，切换到镜像模式"];
            [mainScreen setMirrored:YES];
        }
    }
}

%end

// 初始化
%ctor {
    @autoreleasepool {
        [[LogManager sharedInstance] addLog:@"插件已加载"];
        
        // 注册通知监听
        [[NSNotificationCenter defaultCenter] addObserverForName:UIScreenDidConnectNotification 
                                                        object:nil 
                                                         queue:[NSOperationQueue mainQueue] 
                                                    usingBlock:^(NSNotification *notification) {
            if (![[NSUserDefaults standardUserDefaults] boolForKey:@"enabled"]) {
                return;
            }
            
            UIScreen *mainScreen = [UIScreen mainScreen];
            if (![mainScreen isMirrored]) {
                [[LogManager sharedInstance] addLog:@"通过通知检测到外接显示器，切换到镜像模式"];
                [mainScreen setMirrored:YES];
            }
        }];
    }
}
