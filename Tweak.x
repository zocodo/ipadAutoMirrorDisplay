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

// 监听显示器连接状态
%hook UIScreen

- (void)setMirrored:(BOOL)mirrored {
    %log; // 添加日志记录
    %orig;
}

- (void)setCurrentMode:(UIScreenMode *)mode {
    %log; // 添加日志记录
    %orig;
}

%end

// 监听显示器连接
%hook UIScreen (DisplayConnection)

- (void)_updateDisplayConnection {
    %log; // 添加日志记录
    %orig;
    
    // 获取所有屏幕
    NSArray *screens = [UIScreen screens];
    if (screens.count > 1) {
        // 有外接显示器连接
        UIScreen *mainScreen = [UIScreen mainScreen];
        if (![mainScreen isMirrored]) {
            // 如果当前不是镜像模式，则切换到镜像模式
            NSLog(@"[iPad Auto Mirror] 检测到外接显示器，切换到镜像模式");
            [mainScreen setMirrored:YES];
        }
    }
}

%end

// 初始化
%ctor {
    @autoreleasepool {
        NSLog(@"[iPad Auto Mirror] 插件已加载");
        // 注册通知监听
        [[NSNotificationCenter defaultCenter] addObserverForName:UIScreenDidConnectNotification 
                                                        object:nil 
                                                         queue:[NSOperationQueue mainQueue] 
                                                    usingBlock:^(NSNotification *notification) {
            UIScreen *mainScreen = [UIScreen mainScreen];
            if (![mainScreen isMirrored]) {
                NSLog(@"[iPad Auto Mirror] 通过通知检测到外接显示器，切换到镜像模式");
                [mainScreen setMirrored:YES];
            }
        }];
    }
}
