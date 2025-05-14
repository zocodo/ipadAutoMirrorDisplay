#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// 定义常量
static NSString *const kTweakIdentifier = @"com.zocodo.ipad-auto-mirror-display";
static NSString *const kLogsKey = @"com.zocodo.ipad-auto-mirror-display.logs";
static NSString *const kEnabledKey = @"enabled";
static const NSUInteger kMaxLogs = 50;
static const NSTimeInterval kInitialCheckDelay = 2.0;

// 全局状态
static BOOL tweakInitialized = NO;
static BOOL isProcessing = NO;

// 日志管理
@interface LogManager : NSObject
+ (instancetype)sharedInstance;
- (void)addLog:(NSString *)log;
- (NSArray *)getLogs;
- (void)clearLogs;
@end

@implementation LogManager {
    NSMutableArray *_logs;
    dispatch_queue_t _logQueue;
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
        _logQueue = dispatch_queue_create("com.zocodo.ipad-auto-mirror-display.log", DISPATCH_QUEUE_SERIAL);
        [self loadSavedLogs];
    }
    return self;
}

- (void)loadSavedLogs {
    dispatch_async(_logQueue, ^{
        NSArray *savedLogs = [[NSUserDefaults standardUserDefaults] objectForKey:kLogsKey];
        self->_logs = savedLogs ? [savedLogs mutableCopy] : [NSMutableArray array];
        [self addLog:@"日志系统初始化完成"];
    });
}

- (void)addLog:(NSString *)log {
    if (!log) return;
    
    dispatch_async(_logQueue, ^{
        @try {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"HH:mm:ss"];
            NSString *timeString = [formatter stringFromDate:[NSDate date]];
            NSString *logEntry = [NSString stringWithFormat:@"[%@] %@", timeString, log];
            
            [self->_logs addObject:logEntry];
            
            if (self->_logs.count > kMaxLogs) {
                [self->_logs removeObjectAtIndex:0];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSUserDefaults standardUserDefaults] setObject:self->_logs forKey:kLogsKey];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"LogsUpdated" object:nil];
            });
        } @catch (NSException *exception) {
            NSLog(@"[%@] Error adding log: %@", kTweakIdentifier, exception);
        }
    });
}

- (NSArray *)getLogs {
    __block NSArray *logs;
    dispatch_sync(_logQueue, ^{
        logs = [self->_logs copy];
    });
    return logs;
}

- (void)clearLogs {
    dispatch_async(_logQueue, ^{
        [self->_logs removeAllObjects];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLogsKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"LogsUpdated" object:nil];
        });
    });
}

@end

// 安全地执行主线程操作
static void safeDispatchMain(dispatch_block_t block) {
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

// 检查并启用镜像模式
static void checkAndEnableMirrorMode(void) {
    if (isProcessing) {
        [[LogManager sharedInstance] addLog:@"正在处理中，跳过本次检查"];
        return;
    }
    
    isProcessing = YES;
    
    @try {
        // 检查功能是否启用
        if (![[NSUserDefaults standardUserDefaults] boolForKey:kEnabledKey]) {
            [[LogManager sharedInstance] addLog:@"自动镜像功能已禁用"];
            isProcessing = NO;
            return;
        }
        
        // 获取屏幕信息
        NSArray *screens = [UIScreen screens];
        if (!screens) {
            [[LogManager sharedInstance] addLog:@"无法获取屏幕信息"];
            isProcessing = NO;
            return;
        }
        
        [[LogManager sharedInstance] addLog:[NSString stringWithFormat:@"检测到 %lu 个屏幕", (unsigned long)screens.count]];
        
        if (screens.count > 1) {
            UIScreen *mainScreen = [UIScreen mainScreen];
            if (!mainScreen) {
                [[LogManager sharedInstance] addLog:@"无法获取主屏幕"];
                isProcessing = NO;
                return;
            }
            
            // 检查方法是否可用
            if (![mainScreen respondsToSelector:@selector(isMirrored)] || 
                ![mainScreen respondsToSelector:@selector(setMirrored:)]) {
                [[LogManager sharedInstance] addLog:@"设备不支持镜像模式"];
                isProcessing = NO;
                return;
            }
            
            // 检查当前状态
            BOOL currentMirrorState = [mainScreen isMirrored];
            [[LogManager sharedInstance] addLog:[NSString stringWithFormat:@"当前镜像状态: %@", currentMirrorState ? @"开启" : @"关闭"]];
            
            // 如果需要切换
            if (!currentMirrorState) {
                [[LogManager sharedInstance] addLog:@"检测到外接显示器，正在切换到镜像模式..."];
                safeDispatchMain(^{
                    @try {
                        [mainScreen setMirrored:YES];
                        [[LogManager sharedInstance] addLog:@"镜像模式切换完成"];
                    } @catch (NSException *exception) {
                        [[LogManager sharedInstance] addLog:[NSString stringWithFormat:@"切换镜像模式失败: %@", exception]];
                    }
                });
            }
        } else {
            [[LogManager sharedInstance] addLog:@"未检测到外接显示器"];
        }
    } @catch (NSException *exception) {
        [[LogManager sharedInstance] addLog:[NSString stringWithFormat:@"检查镜像模式时出错: %@", exception]];
    } @finally {
        isProcessing = NO;
    }
}

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    
    if (tweakInitialized) {
        return;
    }
    
    tweakInitialized = YES;
    
    @try {
        // 设置默认值
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if (![defaults objectForKey:kEnabledKey]) {
            [defaults setBool:YES forKey:kEnabledKey];
            [defaults synchronize];
            [[LogManager sharedInstance] addLog:@"已设置默认值：启用自动镜像"];
        }
        
        // 注册通知监听
        [[NSNotificationCenter defaultCenter] addObserverForName:UIScreenDidConnectNotification 
                                                        object:nil 
                                                         queue:[NSOperationQueue mainQueue] 
                                                    usingBlock:^(NSNotification *notification) {
            [[LogManager sharedInstance] addLog:@"检测到显示器连接通知"];
            checkAndEnableMirrorMode();
        }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIScreenDidDisconnectNotification 
                                                        object:nil 
                                                         queue:[NSOperationQueue mainQueue] 
                                                    usingBlock:^(NSNotification *notification) {
            [[LogManager sharedInstance] addLog:@"检测到显示器断开通知"];
        }];
        
        // 初始检查
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kInitialCheckDelay * NSEC_PER_SEC)), 
                      dispatch_get_main_queue(), ^{
            checkAndEnableMirrorMode();
        });
        
    } @catch (NSException *exception) {
        [[LogManager sharedInstance] addLog:[NSString stringWithFormat:@"初始化时出错: %@", exception]];
    }
}

%end

// 监听设置变更
%hook NSUserDefaults

- (void)setObject:(id)value forKey:(NSString *)defaultName {
    %orig;
    if ([defaultName isEqualToString:kEnabledKey]) {
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