#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// —— 自定义控制中心按钮 ——
// 一个简单的 UIViewController 用作模块
@interface DisplayModeViewController : UIViewController
@property (nonatomic, strong) UIButton *toggleButton;
@end

@implementation DisplayModeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.toggleButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.toggleButton.frame = CGRectMake(10, 10, 60, 60);
    [self.toggleButton setTitle:@"镜像" forState:UIControlStateNormal];
    self.toggleButton.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
    self.toggleButton.layer.cornerRadius = 12;

    [self.toggleButton addTarget:self action:@selector(togglePressed)
                forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.toggleButton];

    [self updateState];
}

- (void)togglePressed {
    BOOL on = ![[NSUserDefaults standardUserDefaults] boolForKey:@"com.example.DisplayMode"];
    [[NSUserDefaults standardUserDefaults] setBool:on forKey:@"com.example.DisplayMode"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // 使用新的 API 控制显示模式
    for (UISceneSession *session in [UIApplication sharedApplication].openSessions) {
        if ([session.role isEqualToString:@"UIWindowSceneSessionRoleExternalDisplay"]) {
            UIWindowScene *scene = (UIWindowScene *)session.scene;
            if (scene) {
                // 获取当前屏幕模式
                UIScreenMode *currentMode = scene.screen.currentMode;
                NSArray *availableModes = scene.screen.availableModes;
                
                // 找到镜像模式（通常是第一个模式）和扩展模式（通常是最后一个模式）
                if (availableModes.count > 0) {
                    UIScreenMode *targetMode = on ? availableModes.firstObject : availableModes.lastObject;
                    if (targetMode != currentMode) {
                        scene.screen.currentMode = targetMode;
                    }
                }
            }
        }
    }
    
    [self updateState];
}

- (void)updateState {
    BOOL on = [[NSUserDefaults standardUserDefaults] boolForKey:@"com.example.DisplayMode"];
    NSString *title = on ? @"镜像" : @"扩展";
    [self.toggleButton setTitle:title forState:UIControlStateNormal];
}

@end

// —— 注入控制中心 ——
// Hook SpringBoard 控制中心模块加载逻辑
@interface SBControlCenterController : NSObject
- (NSArray *)orderedModuleIdentifiers;
- (UIViewController *)moduleInstanceForIdentifier:(NSString *)identifier;
@end

%hook SBControlCenterController

- (NSArray *)orderedModuleIdentifiers {
    NSMutableArray *mods = [NSMutableArray arrayWithArray:%orig];
    if (![mods containsObject:@"com.example.DisplayMode"]) {
        [mods addObject:@"com.example.DisplayMode"];
    }
    return mods;
}

- (UIViewController *)moduleInstanceForIdentifier:(NSString *)identifier {
    if ([identifier isEqualToString:@"com.example.DisplayMode"]) {
        return [DisplayModeViewController new];
    }
    return %orig;
}

%end

// —— 监听外接显示器连接 ——
%ctor {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserverForName:UISceneWillConnectNotification
                    object:nil queue:nil usingBlock:^(NSNotification *note) {
        UIScene *scene = note.object;
        if ([scene.session.role isEqualToString:@"UIWindowSceneSessionRoleExternalDisplay"]) {
            BOOL on = [[NSUserDefaults standardUserDefaults] boolForKey:@"com.example.DisplayMode"];
            
            // 设置初始显示模式
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            NSArray *availableModes = windowScene.screen.availableModes;
            if (availableModes.count > 0) {
                UIScreenMode *targetMode = on ? availableModes.firstObject : availableModes.lastObject;
                windowScene.screen.currentMode = targetMode;
            }
        }
    }];
}
