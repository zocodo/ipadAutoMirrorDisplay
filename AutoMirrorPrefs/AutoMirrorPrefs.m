#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface AutoMirrorListController: PSListController
@end

@implementation AutoMirrorListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Preferences" target:self];
    }
    return _specifiers;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 设置标题
    self.title = @"自动镜像";
    
    // 添加刷新按钮
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] 
                                    initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh 
                                    target:self 
                                    action:@selector(refreshLogs)];
    self.navigationItem.rightBarButtonItem = refreshButton;
}

- (void)refreshLogs {
    // 获取日志
    NSArray *logs = [[NSUserDefaults standardUserDefaults] objectForKey:@"com.zocodo.ipad-auto-mirror-display.logs"];
    
    // 更新日志显示
    PSSpecifier *logSpecifier = [self specifierForID:@"logView"];
    if (logSpecifier) {
        if (logs.count > 0) {
            NSString *logText = [logs componentsJoinedByString:@"\n"];
            [logSpecifier setProperty:logText forKey:@"staticText"];
        } else {
            [logSpecifier setProperty:@"暂无日志" forKey:@"staticText"];
        }
        [self reloadSpecifier:logSpecifier];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshLogs];
}

@end 