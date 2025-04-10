// Tweak.x

%hook UIApplication

- (void)sendEvent:(UIEvent *)event {
    // 此处可以检测其他事件，当前保持原有实现
    %orig;
}

%end

%ctor {
    // 启动 Swift 模块监听屏幕连接事件
    [MirrorManager.shared startObserving];
    
    // 初始化 roothide 隐藏越狱痕迹（请确保 roothide_init 已正确导入）
    extern void roothide_init(void);
    roothide_init();
}
