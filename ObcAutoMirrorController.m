#import "ObcAutoMirrorController.h"
#import <DisplayServices/DisplayServices.h>
#import <UIKit/UIKit.h>

// 声明私有 API
@interface UIScreen ()
- (BOOL)isCaptured;
- (void)setMirroredScreen:(UIScreen *)screen;
@end

@interface UIScreen (Private)
+ (UIScreen *)mirroredScreen;
@end

@implementation ObcAutoMirrorController {
    BOOL _isEnabled;
    NSTimer *_checkTimer;
    UIScreen *_externalScreen;
}

+ (instancetype)sharedInstance {
    static ObcAutoMirrorController *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[ObcAutoMirrorController alloc] init];
    });
    return instance;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    // 创建状态标签
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.text = @"状态: 未启用";
    self.statusLabel.frame = CGRectMake(20, 100, self.view.bounds.size.width - 40, 30);
    [self.view addSubview:self.statusLabel];
    
    // 创建开关
    self.enabledSwitch = [[UISwitch alloc] init];
    self.enabledSwitch.frame = CGRectMake(20, 150, 51, 31);
    [self.enabledSwitch addTarget:self action:@selector(toggleEnabled:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.enabledSwitch];
    
    // 创建日志文本框
    self.logTextView = [[UITextView alloc] init];
    self.logTextView.frame = CGRectMake(20, 200, self.view.bounds.size.width - 40, 300);
    self.logTextView.editable = NO;
    self.logTextView.font = [UIFont systemFontOfSize:14];
    [self.view addSubview:self.logTextView];
    
    // 加载保存的状态
    _isEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"ObcAutoMirrorEnabled"];
    self.enabledSwitch.on = _isEnabled;
    [self updateStatusLabel];
}

- (void)updateStatusLabel {
    self.statusLabel.text = [NSString stringWithFormat:@"状态: %@", _isEnabled ? @"已启用" : @"未启用"];
}

- (void)toggleEnabled:(UISwitch *)sender {
    _isEnabled = sender.isOn;
    [[NSUserDefaults standardUserDefaults] setBool:_isEnabled forKey:@"ObcAutoMirrorEnabled"];
    [self updateStatusLabel];
    
    if (_isEnabled) {
        [self startMonitoring];
        [self updateLog:@"插件已启用"];
    } else {
        [self stopMonitoring];
        [self updateLog:@"插件已禁用"];
    }
}

- (void)startMonitoring {
    if (!_checkTimer) {
        _checkTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                      target:self
                                                    selector:@selector(checkDisplayConnection)
                                                    userInfo:nil
                                                     repeats:YES];
    }
}

- (void)stopMonitoring {
    [_checkTimer invalidate];
    _checkTimer = nil;
}

- (void)checkDisplayConnection {
    if (!_isEnabled) return;
    
    // 检查显示器连接状态
    BOOL isDisplayConnected = [self isExternalDisplayConnected];
    if (isDisplayConnected) {
        [self setMirrorMode];
    }
}

- (BOOL)isExternalDisplayConnected {
    NSArray *screens = [UIScreen screens];
    for (UIScreen *screen in screens) {
        if (screen != [UIScreen mainScreen]) {
            _externalScreen = screen;
            [self updateLog:@"检测到外接显示器"];
            return YES;
        }
    }
    _externalScreen = nil;
    [self updateLog:@"未检测到外接显示器"];
    return NO;
}

- (void)setMirrorMode {
    if (!_externalScreen) return;
    
    @try {
        // 获取主屏幕
        UIScreen *mainScreen = [UIScreen mainScreen];
        
        // 设置镜像模式
        [mainScreen setMirroredScreen:_externalScreen];
        
        [self updateLog:@"已设置为镜像模式"];
    } @catch (NSException *exception) {
        [self updateLog:[NSString stringWithFormat:@"设置镜像模式失败: %@", exception.reason]];
    }
}

- (void)updateLog:(NSString *)log {
    NSString *timestamp = [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                       dateStyle:NSDateFormatterNoStyle
                                                       timeStyle:NSDateFormatterMediumStyle];
    NSString *logEntry = [NSString stringWithFormat:@"[%@] %@\n", timestamp, log];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.logTextView.text = [self.logTextView.text stringByAppendingString:logEntry];
        [self.logTextView scrollRangeToVisible:NSMakeRange(self.logTextView.text.length - 1, 1)];
    });
}

@end 