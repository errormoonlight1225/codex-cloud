#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

static NSString * const DPTargetBundleID = @"cn.damai.iphone";
static NSTimeInterval const DPPollInterval = 0.35;

@interface DPTicketAssistant : NSObject <UITextFieldDelegate>
@property (nonatomic, weak) UIWindow *hostWindow;
@property (nonatomic, strong) UIButton *floatingButton;
@property (nonatomic, strong) UIView *panel;
@property (nonatomic, strong) UITextField *sessionField;
@property (nonatomic, strong) UITextField *priceField;
@property (nonatomic, strong) UITextField *saleTimeField;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UILabel *countdownLabel;
@property (nonatomic, strong) NSTimer *pollTimer;
@property (nonatomic, strong) NSDate *saleDate;
@property (nonatomic, strong) NSString *sessionTerm;
@property (nonatomic, strong) NSString *priceTerm;
@property (nonatomic, assign) BOOL running;
@property (nonatomic, assign) BOOL sessionSelected;
@property (nonatomic, assign) BOOL priceSelected;
@property (nonatomic, assign) BOOL primaryTapped;
@property (nonatomic, assign) BOOL advanced;
@property (nonatomic, assign) NSUInteger actionCount;
@property (nonatomic, strong) NSDate *lastActionAt;
+ (instancetype)shared;
- (void)install;
@end

@implementation DPTicketAssistant

+ (instancetype)shared {
    static DPTicketAssistant *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[DPTicketAssistant alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appBecameActive:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [self install];
        });
    }
    return self;
}

- (void)appBecameActive:(NSNotification *)note {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.45 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [self install];
    });
}

- (UIWindow *)damaiWindow {
    UIApplication *app = UIApplication.sharedApplication;
    UIWindow *candidate = nil;
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in app.connectedScenes) {
            if (![scene isKindOfClass:[UIWindowScene class]]) continue;
            for (UIWindow *window in ((UIWindowScene *)scene).windows) {
                if (!window.hidden && window.rootViewController) {
                    if (window.isKeyWindow) return window;
                    if (!candidate) candidate = window;
                }
            }
        }
    }
    if (!candidate) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        for (UIWindow *window in app.windows) {
            if (!window.hidden && window.rootViewController) {
                if (window.isKeyWindow) return window;
                if (!candidate) candidate = window;
            }
        }
#pragma clang diagnostic pop
    }
    return candidate;
}

- (void)install {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self install]; });
        return;
    }
    NSString *bundle = NSBundle.mainBundle.bundleIdentifier ?: @"";
    if (![bundle isEqualToString:DPTargetBundleID]) return;

    UIWindow *window = [self damaiWindow];
    if (!window) return;
    if (self.floatingButton && self.floatingButton.superview == window) {
        self.hostWindow = window;
        [self layoutFloatingButton];
        return;
    }

    [self.floatingButton removeFromSuperview];
    self.hostWindow = window;
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(0, 110, 108, 48);
    button.backgroundColor = [UIColor colorWithRed:0.93 green:0.27 blue:0.16 alpha:0.96];
    button.layer.cornerRadius = 13.0;
    button.layer.shadowColor = UIColor.blackColor.CGColor;
    button.layer.shadowOpacity = 0.22;
    button.layer.shadowRadius = 8.0;
    button.layer.shadowOffset = CGSizeMake(0, 3);
    [button setTitle:@"DamaiPocket" forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:13.0];
    [button addTarget:self action:@selector(togglePanel) forControlEvents:UIControlEventTouchUpInside];
    [window addSubview:button];
    self.floatingButton = button;
    [self layoutFloatingButton];
}

- (void)layoutFloatingButton {
    if (!self.hostWindow || !self.floatingButton) return;
    CGRect bounds = self.hostWindow.bounds;
    CGFloat width = 108.0;
    CGFloat height = 48.0;
    CGFloat x = MAX(8.0, CGRectGetWidth(bounds) - width - 14.0);
    CGFloat y = MIN(116.0, MAX(72.0, CGRectGetHeight(bounds) - height - 24.0));
    self.floatingButton.frame = CGRectMake(x, y, width, height);
    [self.hostWindow bringSubviewToFront:self.floatingButton];
}

- (UILabel *)label:(NSString *)text frame:(CGRect)frame font:(CGFloat)size color:(UIColor *)color {
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.text = text;
    label.font = [UIFont systemFontOfSize:size weight:UIFontWeightMedium];
    label.textColor = color;
    label.numberOfLines = 0;
    return label;
}

- (UITextField *)field:(NSString *)placeholder frame:(CGRect)frame {
    UITextField *field = [[UITextField alloc] initWithFrame:frame];
    field.borderStyle = UITextBorderStyleRoundedRect;
    field.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.10];
    field.textColor = UIColor.whiteColor;
    field.tintColor = [UIColor colorWithRed:1.0 green:0.54 blue:0.34 alpha:1.0];
    field.font = [UIFont systemFontOfSize:14.0];
    field.autocorrectionType = UITextAutocorrectionTypeNo;
    field.autocapitalizationType = UITextAutocapitalizationTypeNone;
    field.clearButtonMode = UITextFieldViewModeWhileEditing;
    field.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder
        attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.48]}];
    field.delegate = self;
    return field;
}

- (UIButton *)actionButton:(NSString *)title frame:(CGRect)frame color:(UIColor *)color action:(SEL)selector {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = frame;
    button.backgroundColor = color;
    button.layer.cornerRadius = 10.0;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)togglePanel {
    if (self.panel) {
        [self.panel removeFromSuperview];
        self.panel = nil;
        return;
    }
    [self showPanel];
}

- (void)showPanel {
    [self install];
    if (!self.hostWindow) return;
    CGFloat width = MIN(420.0, CGRectGetWidth(self.hostWindow.bounds) - 28.0);
    CGFloat height = 386.0;
    UIView *panel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
    panel.center = self.hostWindow.center;
    panel.backgroundColor = [UIColor colorWithWhite:0.075 alpha:0.98];
    panel.layer.cornerRadius = 18.0;
    panel.layer.borderWidth = 1.0;
    panel.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.14].CGColor;
    panel.layer.shadowColor = UIColor.blackColor.CGColor;
    panel.layer.shadowOpacity = 0.35;
    panel.layer.shadowRadius = 18.0;
    panel.layer.shadowOffset = CGSizeMake(0, 8);
    panel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
                             UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;

    [panel addSubview:[self label:@"DamaiPocket  0.2.0" frame:CGRectMake(18, 15, width - 70, 26)
                                font:19.0 color:UIColor.whiteColor]];
    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.frame = CGRectMake(width - 42, 10, 32, 32);
    [close setTitle:@"×" forState:UIControlStateNormal];
    [close setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    close.titleLabel.font = [UIFont systemFontOfSize:27.0 weight:UIFontWeightLight];
    [close addTarget:self action:@selector(togglePanel) forControlEvents:UIControlEventTouchUpInside];
    [panel addSubview:close];

    [panel addSubview:[self label:@"场次关键词（例如：11月20日 19:30）"
                            frame:CGRectMake(18, 53, width - 36, 18) font:12.0
                             color:[UIColor colorWithWhite:1.0 alpha:0.72]]];
    self.sessionField = [self field:@"按大麦页面显示文字匹配" frame:CGRectMake(18, 74, width - 36, 38)];
    self.sessionField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"DPTSessionTerm"] ?: @"";
    [panel addSubview:self.sessionField];

    [panel addSubview:[self label:@"票价关键词（例如：680）"
                            frame:CGRectMake(18, 119, width - 36, 18) font:12.0
                             color:[UIColor colorWithWhite:1.0 alpha:0.72]]];
    self.priceField = [self field:@"必须与页面票价文字相符" frame:CGRectMake(18, 140, width - 36, 38)];
    self.priceField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"DPTPriceTerm"] ?: @"";
    [panel addSubview:self.priceField];

    [panel addSubview:[self label:@"开售时间（本机时间，可留空立即开始）"
                            frame:CGRectMake(18, 185, width - 36, 18) font:12.0
                             color:[UIColor colorWithWhite:1.0 alpha:0.72]]];
    self.saleTimeField = [self field:@"yyyy-MM-dd HH:mm:ss" frame:CGRectMake(18, 206, width - 36, 38)];
    self.saleTimeField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"DPTSaleTime"] ?: @"";
    self.saleTimeField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    [panel addSubview:self.saleTimeField];

    self.countdownLabel = [self label:@"状态：待启动"
                                 frame:CGRectMake(18, 253, width - 36, 20) font:12.0
                                  color:[UIColor colorWithRed:1.0 green:0.72 blue:0.38 alpha:1.0]];
    [panel addSubview:self.countdownLabel];

    self.statusLabel = [self label:@"只操作大麦页面中当前可见的控件；遇到排队、验证码或支付会停下。"
                              frame:CGRectMake(18, 276, width - 36, 48) font:12.0
                               color:[UIColor colorWithWhite:1.0 alpha:0.78]];
    [panel addSubview:self.statusLabel];

    CGFloat buttonWidth = (width - 48.0) / 2.0;
    [panel addSubview:[self actionButton:@"开始辅助" frame:CGRectMake(18, 336, buttonWidth, 38)
                                  color:[UIColor colorWithRed:0.82 green:0.22 blue:0.13 alpha:1.0]
                                 action:@selector(startAssistant)]];
    [panel addSubview:[self actionButton:@"停止" frame:CGRectMake(30 + buttonWidth, 336, buttonWidth, 38)
                                  color:[UIColor colorWithWhite:0.25 alpha:1.0]
                                 action:@selector(stopAssistant)]];
    self.panel = panel;
    [self.hostWindow addSubview:panel];
    [self.hostWindow bringSubviewToFront:self.floatingButton];
    [self.hostWindow bringSubviewToFront:panel];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (NSDate *)dateFromText:(NSString *)text {
    NSString *trimmed = [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (trimmed.length == 0) return nil;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.timeZone = NSTimeZone.localTimeZone;
    formatter.lenient = NO;
    for (NSString *format in @[@"yyyy-MM-dd HH:mm:ss", @"yyyy-MM-dd HH:mm"]) {
        formatter.dateFormat = format;
        NSDate *date = [formatter dateFromString:trimmed];
        if (date) return date;
    }
    return nil;
}

- (void)startAssistant {
    [self.sessionField resignFirstResponder];
    [self.priceField resignFirstResponder];
    [self.saleTimeField resignFirstResponder];

    NSString *saleText = self.saleTimeField.text ?: @"";
    NSDate *saleDate = [self dateFromText:saleText];
    if (saleText.length > 0 && !saleDate) {
        [self setStatus:@"开售时间格式错误，请使用 yyyy-MM-dd HH:mm:ss"];
        return;
    }

    self.sessionTerm = [self.sessionField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] ?: @"";
    self.priceTerm = [self.priceField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] ?: @"";
    self.saleDate = saleDate;
    self.sessionSelected = NO;
    self.priceSelected = NO;
    self.primaryTapped = NO;
    self.advanced = NO;
    self.actionCount = 0;
    self.running = YES;

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setObject:self.sessionTerm forKey:@"DPTSessionTerm"];
    [defaults setObject:self.priceTerm forKey:@"DPTPriceTerm"];
    [defaults setObject:saleText forKey:@"DPTSaleTime"];

    [self.pollTimer invalidate];
    self.pollTimer = [NSTimer timerWithTimeInterval:DPPollInterval
                                            target:self
                                          selector:@selector(poll)
                                          userInfo:nil
                                           repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.pollTimer forMode:NSRunLoopCommonModes];
    [self setStatus:@"辅助已启动：等待开售并检查当前页面"];
    [self poll];
}

- (void)stopAssistant {
    self.running = NO;
    [self.pollTimer invalidate];
    self.pollTimer = nil;
    [self setStatus:@"已停止。没有发出网络请求，也没有提交或支付订单。"];
}

- (void)setStatus:(NSString *)text {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self setStatus:text]; });
        return;
    }
    self.statusLabel.text = text;
    self.statusLabel.numberOfLines = 0;
    [self.statusLabel sizeToFit];
    if (self.countdownLabel && self.running && self.saleDate) {
        NSTimeInterval remain = [self.saleDate timeIntervalSinceNow];
        if (remain > 0) {
            self.countdownLabel.text = [NSString stringWithFormat:@"距离开售：%.1f 秒", remain];
        } else {
            self.countdownLabel.text = @"已到开售时间：正在检查大麦页面";
        }
    } else if (self.countdownLabel) {
        self.countdownLabel.text = self.running ? @"状态：运行中" : @"状态：已停止";
    }
}

- (NSString *)textForView:(UIView *)view {
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    if ([view isKindOfClass:[UILabel class]]) {
        NSString *text = ((UILabel *)view).text;
        if (text.length) [parts addObject:text];
    }
    if ([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        NSString *title = [button titleForState:UIControlStateNormal];
        if (title.length) [parts addObject:title];
        if (button.currentTitle.length) [parts addObject:button.currentTitle];
    }
    if ([view isKindOfClass:[UITextView class]]) {
        NSString *text = ((UITextView *)view).text;
        if (text.length) [parts addObject:text];
    }
    if ([view isKindOfClass:[UITextField class]]) {
        NSString *text = ((UITextField *)view).text;
        if (text.length) [parts addObject:text];
    }
    if (view.accessibilityLabel.length) [parts addObject:view.accessibilityLabel];
    if (view.accessibilityValue.length) [parts addObject:view.accessibilityValue];
    return [parts componentsJoinedByString:@" "];
}

- (void)collectViews:(UIView *)view into:(NSMutableArray<UIView *> *)result {
    if (!view || view.hidden || view.alpha < 0.02) return;
    if (self.panel && (view == self.panel || [view isDescendantOfView:self.panel])) return;
    [result addObject:view];
    for (UIView *child in view.subviews) {
        [self collectViews:child into:result];
    }
}

- (BOOL)isVisibleControl:(UIView *)view {
    if (!view || view.hidden || view.alpha < 0.02 || !view.userInteractionEnabled) return NO;
    if (self.panel && (view == self.panel || [view isDescendantOfView:self.panel])) return NO;
    if (!self.hostWindow) return NO;
    CGRect rect = [view convertRect:view.bounds toView:self.hostWindow];
    return !CGRectIsNull(rect) && !CGRectIsEmpty(rect) &&
           CGRectIntersectsRect(rect, self.hostWindow.bounds);
}

- (UIButton *)buttonContainingWords:(NSArray<NSString *> *)words inViews:(NSArray<UIView *> *)views {
    for (UIView *view in views) {
        if (![view isKindOfClass:[UIButton class]] || ![self isVisibleControl:view]) continue;
        UIButton *button = (UIButton *)view;
        if (!button.enabled) continue;
        NSString *text = [[self textForView:button] lowercaseString];
        for (NSString *word in words) {
            if ([text containsString:[word lowercaseString]]) return button;
        }
    }
    return nil;
}

- (UIButton *)buttonForConfiguredLabel:(NSString *)keyword views:(NSArray<UIView *> *)views {
    if (keyword.length == 0) return nil;
    NSString *needle = keyword.lowercaseString;
    for (UIView *view in views) {
        if ([view isKindOfClass:[UIButton class]] && [self isVisibleControl:view]) {
            NSString *buttonText = [self textForView:view].lowercaseString;
            if ([buttonText containsString:needle]) return (UIButton *)view;
        }
    }
    for (UIView *view in views) {
        if ([view isKindOfClass:[UIButton class]]) continue;
        NSString *text = [self textForView:view].lowercaseString;
        if (![text containsString:needle]) continue;
        UIView *ancestor = view.superview;
        for (NSUInteger depth = 0; ancestor && depth < 5; depth++, ancestor = ancestor.superview) {
            NSMutableArray<UIView *> *subtree = [NSMutableArray array];
            [self collectViews:ancestor into:subtree];
            UIButton *choice = [self buttonContainingWords:@[@"选择", @"选中", @"购买", @"预订", @"确认", @"下一步"]
                                                  inViews:subtree];
            if (choice) return choice;
        }
    }
    return nil;
}

- (BOOL)screenContainsAny:(NSArray<NSString *> *)needles views:(NSArray<UIView *> *)views {
    NSMutableString *screenText = [NSMutableString string];
    for (UIView *view in views) {
        NSString *text = [self textForView:view];
        if (text.length) [screenText appendFormat:@" %@", text];
    }
    NSString *lower = screenText.lowercaseString;
    for (NSString *needle in needles) {
        if ([lower containsString:needle.lowercaseString]) return YES;
    }
    return NO;
}

- (void)tapVisibleButton:(UIButton *)button description:(NSString *)description {
    if (!button || ![self isVisibleControl:button]) return;
    [button sendActionsForControlEvents:UIControlEventTouchUpInside];
    self.lastActionAt = [NSDate date];
    self.actionCount += 1;
    [self setStatus:[NSString stringWithFormat:@"已操作可见按钮：%@（本轮 %lu 次）", description, (unsigned long)self.actionCount]];
}

- (void)pauseForHuman:(NSString *)message {
    self.running = NO;
    [self.pollTimer invalidate];
    self.pollTimer = nil;
    [self setStatus:message];
}

- (void)poll {
    if (!self.running || !self.hostWindow) return;
    if (self.saleDate && [self.saleDate timeIntervalSinceNow] > 0) {
        NSTimeInterval remain = [self.saleDate timeIntervalSinceNow];
        self.countdownLabel.text = [NSString stringWithFormat:@"距离开售：%.1f 秒", remain];
        return;
    }
    if (self.lastActionAt && [[NSDate date] timeIntervalSinceDate:self.lastActionAt] < 1.1) return;

    NSMutableArray<UIView *> *views = [NSMutableArray array];
    [self collectViews:self.hostWindow into:views];

    NSArray<NSString *> *humanGateWords = @[
        @"验证码", @"滑块验证", @"人机验证", @"安全验证", @"身份验证",
        @"排队中", @"正在排队", @"前方排队", @"请勿刷新", @"请完成验证",
        @"访问过于频繁", @"操作频繁", @"系统繁忙"
    ];
    if ([self screenContainsAny:humanGateWords views:views]) {
        [self pauseForHuman:@"检测到排队/验证/风控提示，已暂停自动操作；请在大麦官方页面手动完成。"];
        return;
    }

    UIButton *submitButton = [self buttonContainingWords:@[@"提交订单", @"确认支付", @"立即支付", @"去支付"] inViews:views];
    if (submitButton) {
        [self pauseForHuman:@"已到订单提交/支付环节。为避免误下单，自动操作已停止，请核对订单后手动继续。"];
        return;
    }

    if (!self.sessionSelected && self.sessionTerm.length > 0) {
        UIButton *sessionButton = [self buttonForConfiguredLabel:self.sessionTerm views:views];
        if (sessionButton) {
            [self tapVisibleButton:sessionButton description:@"匹配场次"];
            self.sessionSelected = YES;
            return;
        }
    }

    if (!self.priceSelected && self.priceTerm.length > 0) {
        UIButton *priceButton = [self buttonForConfiguredLabel:self.priceTerm views:views];
        if (priceButton) {
            [self tapVisibleButton:priceButton description:@"匹配票价"];
            self.priceSelected = YES;
            return;
        }
    }

    if (!self.primaryTapped) {
        UIButton *purchaseButton = [self buttonContainingWords:@[
            @"立即购买", @"立即预定", @"立即抢购", @"立即购票", @"选座购买", @"去抢票"
        ] inViews:views];
        if (purchaseButton) {
            [self tapVisibleButton:purchaseButton description:@"进入官方购票流程"];
            self.primaryTapped = YES;
            return;
        }
    }

    UIButton *nextButton = [self buttonContainingWords:@[@"下一步", @"确认场次", @"确定"] inViews:views];
    if (!self.advanced && nextButton && (self.sessionSelected || self.priceSelected)) {
        [self tapVisibleButton:nextButton description:@"确认当前选择"];
        self.advanced = YES;
        return;
    }

    if ([self screenContainsAny:@[@"缺货登记", @"已售罄", @"暂时缺货", @"无可售票"] views:views]) {
        [self setStatus:@"当前页面显示缺货/售罄；没有进行高频刷新，请手动观察官方页面。"];
    } else if (self.sessionTerm.length > 0 && !self.sessionSelected) {
        [self setStatus:@"等待页面出现匹配场次；请先停留在目标演出页面。"];
    } else if (self.priceTerm.length > 0 && !self.priceSelected) {
        [self setStatus:@"等待页面出现匹配票价；请核对关键词是否与页面文字一致。"];
    } else {
        [self setStatus:@"正在检查大麦当前可见页面；不会调用私有接口或绕过平台验证。"];
    }
}

@end

%ctor {
    @autoreleasepool {
        NSString *bundle = NSBundle.mainBundle.bundleIdentifier ?: @"";
        if (![bundle isEqualToString:DPTargetBundleID]) return;
        NSLog(@"[DamaiPocket] Loaded 0.2.0 in %@.", bundle);
        dispatch_async(dispatch_get_main_queue(), ^{
            [DPTicketAssistant shared];
        });
    }
}
