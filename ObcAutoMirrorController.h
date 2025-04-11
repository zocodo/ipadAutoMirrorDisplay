#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface ObcAutoMirrorController : UIViewController

@property (nonatomic, strong) UISwitch *enabledSwitch;
@property (nonatomic, strong) UITextView *logTextView;
@property (nonatomic, strong) UILabel *statusLabel;

+ (instancetype)sharedInstance;
- (void)updateLog:(NSString *)log;
- (void)checkDisplayConnection;
- (void)toggleEnabled:(UISwitch *)sender;

@end