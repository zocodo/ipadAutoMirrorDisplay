#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

static BOOL tweakInitialized = NO;

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
        NSLog(@"[AutoMirrorDisplay] LogManager singleton created");
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        NSLog(@"[AutoMirrorDisplay] LogManager initializing...");
        // 从 UserDefaults 读取已保存的日志
        NSArray *savedLogs = [[NSUserDefaults standardUserDefaults] objectForKey:@"com.zocodo.ipad-auto-mirror-display.logs"];
        _logs = savedLogs ? [savedLogs mutableCopy] : [NSMutableArray array];
        NSLog(@"[AutoMirrorDisplay] LogManager initialized with %lu saved logs", (unsigned long)_logs.count);
        [self addLog:@"LogManager 初始化完成"];
    }
    return self;
}

- (void)addLog:(NSString *)log {
    if (!log) return;
    
    @try {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"HH:mm:ss"];
        NSString *timeString = [formatter stringFromDate:[NSDate date]];
        NSString *logEntry = [NSString stringWithFormat:@"[%@] %@", timeString, log];
        
        // 同时输出到系统日志
        NSLog(@"[AutoMirrorDisplay] %@", logEntry);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self->_logs addObject:logEntry];
            
            // 保持最近的50条日志
            if (self->_logs.count > 50) {
                [self->_logs removeObjectAtIndex:0];
            }
            
            // 保存到UserDefaults
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:self->_logs forKey:@"com.zocodo.ipad-auto-mirror-display.logs"];
            [defaults synchronize];
            
            // 发送通知以更新UI
            [[NSNotificationCenter defaultCenter] postNotificationName:@"LogsUpdated" object:nil];
            NSLog(@"[AutoMirrorDisplay] Posted LogsUpdated notification");
        });
    } @catch (NSException *exception) {
        NSLog(@"[AutoMirrorDisplay] Error adding log: %@", exception);
    }
}

- (NSArray *)getLogs {
    return [_logs copy];
}

@end

// UIScreen分类声明
@interface UIScreen (MirrorAdditions)
- (BOOL)isMirrored;
- (void)setMirrored:(BOOL)mirrored;
- (void)_updateDisplayConnection;
@end

static void checkAndEnableMirrorMode(void) {
    NSLog(@"[AutoMirrorDisplay] Checking mirror mode...");
    @try {
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"enabled"]) {
            [[LogManager sharedInstance] addLog:@"自动镜像功能已禁用"];
            return;
        }
        
        NSArray *screens = [UIScreen screens];
        if (!screens) {
            [[LogManager sharedInstance] addLog:@"无法获取屏幕信息"];
            return;
        }
        
        [[LogManager sharedInstance] addLog:[NSString stringWithFormat:@"检测到 %lu 个屏幕", (unsigned long)screens.count]];
        
        if (screens.count > 1) {
            UIScreen *mainScreen = [UIScreen mainScreen];
            if (!mainScreen) {
                [[LogManager sharedInstance] addLog:@"无法获取主屏幕"];
                return;
            }
            
            if (![mainScreen respondsToSelector:@selector(isMirrored)] || 
                ![mainScreen respondsToSelector:@selector(setMirrored:)]) {
                [[LogManager sharedInstance] addLog:@"设备不支持镜像模式"];
                return;
            }
            
            BOOL currentMirrorState = [mainScreen isMirrored];
            [[LogManager sharedInstance] addLog:[NSString stringWithFormat:@"当前镜像状态: %@", currentMirrorState ? @"开启" : @"关闭"]];
            
            if (!currentMirrorState) {
                [[LogManager sharedInstance] addLog:@"检测到外接显示器，正在切换到镜像模式..."];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [mainScreen setMirrored:YES];
                });
            }
        } else {
            [[LogManager sharedInstance] addLog:@"未检测到外接显示器"];
        }
    } @catch (NSException *exception) {
        [[LogManager sharedInstance] addLog:[NSString stringWithFormat:@"错误: %@", exception]];
        NSLog(@"[AutoMirrorDisplay] Error in checkAndEnableMirrorMode: %@", exception);
    }
}

// 监听显示器连接状态
%hook UIScreen

- (void)setMirrored:(BOOL)mirrored {
    NSLog(@"[AutoMirrorDisplay] setMirrored: %d called", mirrored);
    @try {
        [[LogManager sharedInstance] addLog:[NSString stringWithFormat:@"正在设置镜像模式: %@", mirrored ? @"开启" : @"关闭"]];
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"enabled"]) {
            %orig;
            [[LogManager sharedInstance] addLog:[NSString stringWithFormat:@"镜像模式已%@", mirrored ? @"开启" : @"关闭"]];
        } else {
            %orig;
            [[LogManager sharedInstance] addLog:@"自动镜像功能已禁用，保持原始设置"];
        }
    } @catch (NSException *exception) {
        [[LogManager sharedInstance] addLog:[NSString stringWithFormat:@"设置镜像模式时出错: %@", exception]];
        NSLog(@"[AutoMirrorDisplay] Error in setMirrored: %@", exception);
        %orig;
    }
}

- (void)setCurrentMode:(UIScreenMode *)mode {
    NSLog(@"[AutoMirrorDisplay] setCurrentMode called");
    @try {
        %orig;
        [[LogManager sharedInstance] addLog:@"屏幕模式已更新"];
    } @catch (NSException *exception) {
        [[LogManager sharedInstance] addLog:[NSString stringWithFormat:@"设置屏幕模式时出错: %@", exception]];
        NSLog(@"[AutoMirrorDisplay] Error in setCurrentMode: %@", exception);
        %orig;
    }
}

- (void)_updateDisplayConnection {
    NSLog(@"[AutoMirrorDisplay] _updateDisplayConnection called");
    @try {
        [[LogManager sharedInstance] addLog:@"检测到显示器连接状态变化"];
        %orig;
        dispatch_async(dispatch_get_main_queue(), ^{
            checkAndEnableMirrorMode();
        });
    } @catch (NSException *exception) {
        [[LogManager sharedInstance] addLog:[NSString stringWithFormat:@"更新显示连接时出错: %@", exception]];
        NSLog(@"[AutoMirrorDisplay] Error in _updateDisplayConnection: %@", exception);
        %orig;
    }
}

%end

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    
    if (tweakInitialized) {
        NSLog(@"[AutoMirrorDisplay] Tweak already initialized, skipping...");
        return;
    }
    
    tweakInitialized = YES;
    NSLog(@"[AutoMirrorDisplay] SpringBoard applicationDidFinishLaunching called");
    
    @try {
        [[LogManager sharedInstance] addLog:@"SpringBoard 已启动"];
        
        // 设置默认值
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if (![defaults objectForKey:@"enabled"]) {
            [defaults setBool:YES forKey:@"enabled"];
            [defaults synchronize];
            [[LogManager sharedInstance] addLog:@"已设置默认启用状态"];
        }
        
        // 注册通知监听
        [[NSNotificationCenter defaultCenter] addObserverForName:UIScreenDidConnectNotification 
                                                        object:nil 
                                                         queue:[NSOperationQueue mainQueue] 
                                                    usingBlock:^(NSNotification *notification) {
            @try {
                [[LogManager sharedInstance] addLog:@"收到显示器连接通知"];
                NSLog(@"[AutoMirrorDisplay] Received UIScreenDidConnectNotification");
                dispatch_async(dispatch_get_main_queue(), ^{
                    checkAndEnableMirrorMode();
                });
            } @catch (NSException *exception) {
                [[LogManager sharedInstance] addLog:[NSString stringWithFormat:@"处理屏幕连接通知时出错: %@", exception]];
                NSLog(@"[AutoMirrorDisplay] Error handling screen connection notification: %@", exception);
            }
        }];
        
        [[LogManager sharedInstance] addLog:@"通知监听已注册"];
        
        // 初始检查显示器状态
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            checkAndEnableMirrorMode();
        });
    } @catch (NSException *exception) {
        NSLog(@"[AutoMirrorDisplay] Error in SpringBoard hook: %@", exception);
    }
}

%end

// 监听设置变更
%hook NSUserDefaults

- (void)setObject:(id)value forKey:(NSString *)defaultName {
    %orig;
    if ([defaultName isEqualToString:@"enabled"]) {
        NSLog(@"[AutoMirrorDisplay] Settings changed: enabled = %@", [value boolValue] ? @"YES" : @"NO");
        [[LogManager sharedInstance] addLog:[NSString stringWithFormat:@"设置已更改：自动镜像功能已%@", [value boolValue] ? @"启用" : @"禁用"]];
        if ([value boolValue]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                checkAndEnableMirrorMode();
            });
        }
    }
}

%end

%ctor {
    @autoreleasepool {
        NSLog(@"[AutoMirrorDisplay] Constructor called");
        [[LogManager sharedInstance] addLog:@"Tweak 构造函数已调用"];
    }
} 