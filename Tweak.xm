#import <UIKit/UIKit.h>
#import <ControlCenterUIKit/ControlCenterUIKit.h>

// —— 私有 API 声明 ——
// SpringBoard 的私有单例，用于控制外接显示器的镜像开关
@interface SBExternalDisplayManager : NSObject
+ (instancetype)sharedInstance;
- (void)setMirroringEnabled:(BOOL)enabled;
@end

// —— 自定义 Control Center Toggle 模块 ——
// 继承自 CCUIToggleModule，自动获得开关样式
@interface DisplayModeModule : CCUIToggleModule
@end

@implementation DisplayModeModule

- (NSString *)toggleIdentifier {
    return @"com.example.DisplayMode";
}

- (BOOL)isSelected {
    return [[NSUserDefaults standardUserDefaults]
             boolForKey:[self toggleIdentifier]];
}

- (void)setSelected:(BOOL)selected {
    [[NSUserDefaults standardUserDefaults]
      setBool:selected forKey:[self toggleIdentifier]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[SBExternalDisplayManager sharedInstance]
      setMirroringEnabled:selected];
}

@end

// —— 注入 Control Center ——
// SpringBoard 控制中心控制器
@interface SBControlCenterController : NSObject
- (NSArray<NSString *> *)orderedModuleIdentifiers;
@end

%hook SBControlCenterController
- (NSArray<NSString *> *)orderedModuleIdentifiers {
    NSMutableArray *mods = [NSMutableArray arrayWithArray:%orig];
    if (![mods containsObject:@"com.example.DisplayMode"]) {
        [mods addObject:@"com.example.DisplayMode"];
    }
    return mods;
}
%end

// —— 监听外接显示器 Scene 生命周期 ——
// 使用 UISceneWillConnectNotification 与 UISceneDidDisconnectNotification
%ctor {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserverForName:UISceneWillConnectNotification
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification *note) {
        UIScene *scene = note.object;
        // 使用字符串字面量替代已弃用的常量
        if ([scene.session.role isEqualToString:@"UIWindowSceneSessionRoleExternalDisplay"]) {
            BOOL on = [[NSUserDefaults standardUserDefaults]
                         boolForKey:@"com.example.DisplayMode"];
            [[SBExternalDisplayManager sharedInstance]
              setMirroringEnabled:on];
        }
    }];
    [nc addObserverForName:UISceneDidDisconnectNotification
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification *note) {
        // 外接显示器断开，可在此执行清理逻辑
    }];
}
