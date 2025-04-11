#import <UIKit/UIKit.h>
#import "ObcAutoMirrorController.h"
#import <SpringBoard/SpringBoard.h>

// 声明控制中心相关类
@interface CCUIModuleInstance : NSObject
@property(nonatomic, retain) UIView *view;
@end

@interface CCUIModuleCollectionViewController : UIViewController
- (void)addModule:(CCUIModuleInstance *)module;
@end

@interface CCUIModuleControlCenterViewController : UIViewController
@property(nonatomic, retain) CCUIModuleCollectionViewController *moduleCollectionViewController;
+ (instancetype)sharedInstance;
@end

// 创建自定义控制中心模块
@interface ObcAutoMirrorModule : CCUIModuleInstance
@property(nonatomic, retain) UIButton *toggleButton;
@property(nonatomic, retain) UILabel *statusLabel;
@end

@implementation ObcAutoMirrorModule

- (instancetype)init {
    self = [super init];
    if (self) {
        UIView *moduleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        moduleView.backgroundColor = [UIColor clearColor];
        
        self.toggleButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.toggleButton.frame = CGRectMake(10, 10, 80, 80);
        [self.toggleButton setTitle:@"镜像" forState:UIControlStateNormal];
        [self.toggleButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.toggleButton.backgroundColor = [UIColor systemBlueColor];
        self.toggleButton.layer.cornerRadius = 40;
        [self.toggleButton addTarget:self action:@selector(toggleButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        
        self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 95, 80, 20)];
        self.statusLabel.textAlignment = NSTextAlignmentCenter;
        self.statusLabel.textColor = [UIColor whiteColor];
        self.statusLabel.font = [UIFont systemFontOfSize:12];
        
        [moduleView addSubview:self.toggleButton];
        [moduleView addSubview:self.statusLabel];
        
        self.view = moduleView;
        
        [self updateStatus];
    }
    return self;
}

- (void)toggleButtonTapped {
    BOOL currentState = [[NSUserDefaults standardUserDefaults] boolForKey:@"ObcAutoMirrorEnabled"];
    [[NSUserDefaults standardUserDefaults] setBool:!currentState forKey:@"ObcAutoMirrorEnabled"];
    [[ObcAutoMirrorController sharedInstance] toggleEnabled:nil];
    [self updateStatus];
}

- (void)updateStatus {
    BOOL isEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"ObcAutoMirrorEnabled"];
    self.toggleButton.backgroundColor = isEnabled ? [UIColor systemGreenColor] : [UIColor systemBlueColor];
    self.statusLabel.text = isEnabled ? @"已启用" : @"已禁用";
}

@end

%hook SpringBoard

-(void)applicationDidFinishLaunching:(id)application {
    %orig;
    
    // 延迟执行以确保控制中心已初始化
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self setupControlCenterModule];
    });
}

- (void)setupControlCenterModule {
    CCUIModuleControlCenterViewController *controlCenter = [%c(CCUIModuleControlCenterViewController) sharedInstance];
    if (controlCenter && controlCenter.moduleCollectionViewController) {
        ObcAutoMirrorModule *module = [[ObcAutoMirrorModule alloc] init];
        [controlCenter.moduleCollectionViewController addModule:module];
    }
}

%end

// 监听显示器连接状态变化
%hook UIScreen

- (void)didConnect {
    %orig;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ObcAutoMirrorEnabled"]) {
        [[ObcAutoMirrorController sharedInstance] checkDisplayConnection];
    }
}

- (void)didDisconnect {
    %orig;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"ObcAutoMirrorEnabled"]) {
        [[ObcAutoMirrorController sharedInstance] updateLog:@"外接显示器已断开连接"];
    }
}

%end 