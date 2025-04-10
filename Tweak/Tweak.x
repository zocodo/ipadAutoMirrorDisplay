#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

%hook SBExternalDisplayManager

- (void)externalDisplayDidConnect:(id)display {
    %orig;

    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.yourid.automirrordisplay.plist"];
    BOOL mirrorEnabled = [[prefs objectForKey:@"MirrorDisplayEnabled"] boolValue];
    BOOL logEnabled = [[prefs objectForKey:@"DebugLogEnabled"] boolValue];

    if (logEnabled) {
        NSLog(@"[AutoMirrorDisplay] Display connected. Mirror mode: %d", mirrorEnabled);
    }

    if (mirrorEnabled) {
        if ([self respondsToSelector:@selector(setMirroringEnabled:forDisplay:)]) {
            [self setMirroringEnabled:YES forDisplay:display];
            if (logEnabled) {
                NSLog(@"[AutoMirrorDisplay] Mirroring enabled via selector.");
            }
        } else if (logEnabled) {
            NSLog(@"[AutoMirrorDisplay] Method not available on this version.");
        }
    }
}

%end