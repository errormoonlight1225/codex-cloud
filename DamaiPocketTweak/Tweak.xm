#import <UIKit/UIKit.h>

%ctor {
    @autoreleasepool {
        NSString *bundle = NSBundle.mainBundle.bundleIdentifier ?: @"unknown";
        if (![bundle isEqualToString:@"cn.damai.iphone"]) {
            return;
        }

        NSLog(@"[DamaiPocket] Rootless tweak loaded in %@ (passive probe).", bundle);
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification *note) {
            NSLog(@"[DamaiPocket] Damai became active; passive probe only.");
        }];
    }
}
