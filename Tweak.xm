#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <ControlCenter/ControlCenter.h>

// —— 自定义控制中心模块 ——
@interface DisplayModeModule : NSObject <CCModule>
@property (nonatomic, strong) UIButton *toggleButton;
@end

@implementation DisplayModeModule

- (UIView *)contentView {
    if (!_toggleButton) {
        _toggleButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _toggleButton.frame = CGRectMake(10, 10, 60, 60);
        [_toggleButton setTitle:@"镜像" forState:UIControlStateNormal];
        _toggleButton.backgroundColor = [UIColor colorWithWhite:1 alpha:0.1];
        _toggleButton.layer.cornerRadius = 12;
        [_toggleButton addTarget:self action:@selector(togglePressed)
                forControlEvents:UIControlEventTouchUpInside];
        [self updateState];
    }
    return _toggleButton;
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
    [_toggleButton setTitle:title forState:UIControlStateNormal];
}

@end

// —— 注入控制中心 ——
%hook CCControlCenterModuleProvider

- (NSArray *)moduleIdentifiers {
    NSMutableArray *mods = [NSMutableArray arrayWithArray:%orig];
    if (![mods containsObject:@"com.example.DisplayMode"]) {
        [mods addObject:@"com.example.DisplayMode"];
    }
    return mods;
}

- (id)moduleInstanceForIdentifier:(NSString *)identifier {
    if ([identifier isEqualToString:@"com.example.DisplayMode"]) {
        return [[DisplayModeModule alloc] init];
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
