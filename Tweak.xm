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

// 必须实现，返回和 Info.plist 中一致的 identifier
- (NSString *)toggleIdentifier {
    return @"com.example.DisplayMode";
}

// 读取开关状态：从 NSUserDefaults 拿
- (BOOL)isSelected {
    return [[NSUserDefaults standardUserDefaults]
             boolForKey:[self toggleIdentifier]];
}

// 用户切换时调用
- (void)setSelected:(BOOL)selected {
    // 存储状态
    [[NSUserDefaults standardUserDefaults]
      setBool:selected forKey:[self toggleIdentifier]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    // 调用私有 API 切换镜像/扩展
    [[SBExternalDisplayManager sharedInstance]
      setMirroringEnabled:selected];
}

@end

// —— 把模块插入到控制中心 ——
// SpringBoard 的控制中心控制器
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

// —— 监听外接显示器插拔 ——
// 在进程启动时注册通知
%ctor {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    // 外接显示器接入
    [nc addObserverForName:UIScreenDidConnectNotification
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification *note) {
        BOOL on = [[NSUserDefaults standardUserDefaults]
                     boolForKey:@"com.example.DisplayMode"];
        [[SBExternalDisplayManager sharedInstance]
          setMirroringEnabled:on];
    }];
    // 外接显示器拔出
    [nc addObserverForName:UIScreenDidDisconnectNotification
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification *note) {
        // 可以在此做清理，通常无需额外操作
    }];
}
