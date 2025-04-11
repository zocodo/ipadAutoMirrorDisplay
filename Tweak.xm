#import <UIKit/UIKit.h>

// —— 自定义控制中心按钮 ——
// 一个简单的 UIViewController 用作模块
@interface DisplayModeViewController : UIViewController
@property (nonatomic, strong) UIButton *toggleButton;
@end

%ctor {
    // 添加调试信息
    NSLog(@"[DisplayMode] 开始检查类是否存在");
    
    Class sbExternalDisplayManagerClass = NSClassFromString(@"SBExternalDisplayManager");
    if (sbExternalDisplayManagerClass) {
        NSLog(@"[DisplayMode] SBExternalDisplayManager 类存在");
        
        // 检查方法是否存在
        if ([sbExternalDisplayManagerClass respondsToSelector:@selector(sharedInstance)]) {
            NSLog(@"[DisplayMode] sharedInstance 方法存在");
            
            id instance = [sbExternalDisplayManagerClass sharedInstance];
            if ([instance respondsToSelector:@selector(setMirroringEnabled:)]) {
                NSLog(@"[DisplayMode] setMirroringEnabled: 方法存在");
            } else {
                NSLog(@"[DisplayMode] setMirroringEnabled: 方法不存在");
            }
        } else {
            NSLog(@"[DisplayMode] sharedInstance 方法不存在");
        }
    } else {
        NSLog(@"[DisplayMode] SBExternalDisplayManager 类不存在");
        
        // 列出所有包含 "ExternalDisplay" 的类名
        NSMutableArray *matchingClasses = [NSMutableArray array];
        int numClasses = objc_getClassList(NULL, 0);
        if (numClasses > 0) {
            Class *classes = (Class *)malloc(sizeof(Class) * numClasses);
            numClasses = objc_getClassList(classes, numClasses);
            for (int i = 0; i < numClasses; i++) {
                NSString *className = NSStringFromClass(classes[i]);
                if ([className containsString:@"ExternalDisplay"]) {
                    [matchingClasses addObject:className];
                }
            }
            free(classes);
        }
        
        if (matchingClasses.count > 0) {
            NSLog(@"[DisplayMode] 找到的相关类: %@", matchingClasses);
        } else {
            NSLog(@"[DisplayMode] 没有找到任何相关的类");
        }
    }
}

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
    
    // 使用 UIScreen API 控制显示模式
    for (UIScreen *screen in [UIScreen screens]) {
        if (screen != [UIScreen mainScreen]) {
            // 获取当前屏幕模式
            UIScreenMode *currentMode = screen.currentMode;
            NSArray *availableModes = screen.availableModes;
            
            // 找到镜像模式（通常是第一个模式）和扩展模式（通常是最后一个模式）
            if (availableModes.count > 0) {
                UIScreenMode *targetMode = on ? availableModes.firstObject : availableModes.lastObject;
                if (targetMode != currentMode) {
                    screen.currentMode = targetMode;
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
    [nc addObserverForName:UIScreenDidConnectNotification
                    object:nil queue:nil usingBlock:^(NSNotification *note) {
        UIScreen *screen = note.object;
        if (screen != [UIScreen mainScreen]) {
            BOOL on = [[NSUserDefaults standardUserDefaults] boolForKey:@"com.example.DisplayMode"];
            
            // 设置初始显示模式
            NSArray *availableModes = screen.availableModes;
            if (availableModes.count > 0) {
                UIScreenMode *targetMode = on ? availableModes.firstObject : availableModes.lastObject;
                screen.currentMode = targetMode;
            }
        }
    }];
}
