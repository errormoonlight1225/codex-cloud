#import "DPViewController.h"
#import <UserNotifications/UserNotifications.h>

@interface DPViewController ()
@property (nonatomic, strong) UITextField *eventField;
@property (nonatomic, strong) UITextField *cityField;
@property (nonatomic, strong) UITextField *sessionField;
@property (nonatomic, strong) UITextField *priceField;
@property (nonatomic, strong) UITextField *quantityField;
@property (nonatomic, strong) UITextField *linkField;
@property (nonatomic, strong) UIDatePicker *salePicker;
@property (nonatomic, strong) UILabel *countdownLabel;
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) NSTimer *countdownTimer;
@end

@implementation DPViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.title = @"DamaiPocket";
    [self buildInterface];
    [self loadPlan];
    [self updateCountdown];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.countdownTimer invalidate];
    self.countdownTimer = [NSTimer timerWithTimeInterval:1.0
                                                  target:self
                                                selector:@selector(updateCountdown)
                                                userInfo:nil
                                                 repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.countdownTimer forMode:NSRunLoopCommonModes];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.countdownTimer invalidate];
    self.countdownTimer = nil;
}

- (UILabel *)makeLabel:(NSString *)text size:(CGFloat)size weight:(UIFontWeight)weight {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont systemFontOfSize:size weight:weight];
    label.textColor = UIColor.labelColor;
    label.numberOfLines = 0;
    return label;
}

- (UITextField *)makeField:(NSString *)placeholder keyboard:(UIKeyboardType)keyboard {
    UITextField *field = [[UITextField alloc] init];
    field.placeholder = placeholder;
    field.borderStyle = UITextBorderStyleRoundedRect;
    field.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    field.font = [UIFont systemFontOfSize:16.0];
    field.clearButtonMode = UITextFieldViewModeWhileEditing;
    field.autocorrectionType = UITextAutocorrectionTypeNo;
    field.autocapitalizationType = UITextAutocapitalizationTypeNone;
    field.keyboardType = keyboard;
    field.returnKeyType = UIReturnKeyDone;
    field.delegate = self;
    [field.heightAnchor constraintEqualToConstant:44.0].active = YES;
    return field;
}

- (void)buildInterface {
    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.alwaysBounceVertical = YES;
    [self.view addSubview:scroll];

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 12.0;
    stack.alignment = UIStackViewAlignmentFill;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor],
        [scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor constant:20.0],
        [stack.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor constant:-20.0],
        [stack.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor constant:18.0],
        [stack.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor constant:-28.0],
        [stack.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor constant:-40.0]
    ]];

    UILabel *title = [self makeLabel:@"DamaiPocket 购票计划" size:25.0 weight:UIFontWeightBold];
    [stack addArrangedSubview:title];
    UILabel *subtitle = [self makeLabel:@"保存演出信息、设置开售提醒，到点后打开大麦官方页面。此工具不接管购票流程。"
                                     size:14.0 weight:UIFontWeightRegular];
    subtitle.textColor = UIColor.secondaryLabelColor;
    [stack addArrangedSubview:subtitle];

    [stack addArrangedSubview:[self makeLabel:@"演出名称" size:14 weight:UIFontWeightSemibold]];
    self.eventField = [self makeField:@"例如：演出 / 音乐节名称" keyboard:UIKeyboardTypeDefault];
    [stack addArrangedSubview:self.eventField];

    [stack addArrangedSubview:[self makeLabel:@"城市 / 场馆" size:14 weight:UIFontWeightSemibold]];
    self.cityField = [self makeField:@"例如：上海 · 梅赛德斯奔驰文化中心" keyboard:UIKeyboardTypeDefault];
    [stack addArrangedSubview:self.cityField];

    [stack addArrangedSubview:[self makeLabel:@"场次 / 日期" size:14 weight:UIFontWeightSemibold]];
    self.sessionField = [self makeField:@"例如：11月20日 19:30" keyboard:UIKeyboardTypeDefault];
    [stack addArrangedSubview:self.sessionField];

    [stack addArrangedSubview:[self makeLabel:@"票价 / 数量" size:14 weight:UIFontWeightSemibold]];
    UIStackView *ticketRow = [[UIStackView alloc] init];
    ticketRow.axis = UILayoutConstraintAxisHorizontal;
    ticketRow.spacing = 10.0;
    ticketRow.distribution = UIStackViewDistributionFillEqually;
    self.priceField = [self makeField:@"票价，例如 680" keyboard:UIKeyboardTypeDecimalPad];
    self.quantityField = [self makeField:@"张数，例如 2" keyboard:UIKeyboardTypeNumberPad];
    [ticketRow addArrangedSubview:self.priceField];
    [ticketRow addArrangedSubview:self.quantityField];
    [stack addArrangedSubview:ticketRow];

    [stack addArrangedSubview:[self makeLabel:@"开售时间（设备本地时间）" size:14 weight:UIFontWeightSemibold]];
    self.salePicker = [[UIDatePicker alloc] init];
    self.salePicker.datePickerMode = UIDatePickerModeDateAndTime;
    self.salePicker.minimumDate = [NSDate date];
    if (@available(iOS 13.4, *)) {
        self.salePicker.preferredDatePickerStyle = UIDatePickerStyleWheels;
    }
    [stack addArrangedSubview:self.salePicker];

    self.countdownLabel = [self makeLabel:@"距离开售：--" size:19.0 weight:UIFontWeightBold];
    self.countdownLabel.textColor = UIColor.systemRedColor;
    [stack addArrangedSubview:self.countdownLabel];

    [stack addArrangedSubview:[self makeLabel:@"大麦官方演出链接" size:14 weight:UIFontWeightSemibold]];
    self.linkField = [self makeField:@"粘贴 https://...damai.cn/... 演出链接" keyboard:UIKeyboardTypeURL];
    self.linkField.textContentType = UITextContentTypeURL;
    [stack addArrangedSubview:self.linkField];

    UIButton *saveButton = [self makeButton:@"保存计划并设置本地通知"
                                      color:UIColor.systemBlueColor
                                    action:@selector(savePlanAndSchedule)];
    [stack addArrangedSubview:saveButton];

    UIButton *openButton = [self makeButton:@"打开大麦官方购票页面"
                                     color:UIColor.systemRedColor
                                   action:@selector(openDamai)];
    [stack addArrangedSubview:openButton];

    self.statusLabel = [self makeLabel:@"提醒仅在本机触发。请提前在大麦官方 App 登录、添加观演人并检查支付方式。"
                                    size:13.0 weight:UIFontWeightRegular];
    self.statusLabel.textColor = UIColor.secondaryLabelColor;
    [stack addArrangedSubview:self.statusLabel];

    UIView *separator = [[UIView alloc] init];
    separator.backgroundColor = UIColor.separatorColor;
    [separator.heightAnchor constraintEqualToConstant:1.0].active = YES;
    [stack addArrangedSubview:separator];

    UILabel *privacy = [self makeLabel:@"隐私：计划保存在本机；不收集账号密码、身份证号或支付信息，也不连接或修改大麦服务。"
                                     size:12.0 weight:UIFontWeightRegular];
    privacy.textColor = UIColor.tertiaryLabelColor;
    [stack addArrangedSubview:privacy];
}

- (UIButton *)makeButton:(NSString *)title color:(UIColor *)color action:(SEL)selector {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.backgroundColor = color;
    button.layer.cornerRadius = 12.0;
    button.contentEdgeInsets = UIEdgeInsetsMake(13, 16, 13, 16);
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold];
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    [button.heightAnchor constraintGreaterThanOrEqualToConstant:48.0].active = YES;
    return button;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)loadPlan {
    NSDictionary *plan = [NSUserDefaults.standardUserDefaults dictionaryForKey:@"DPTSavedPlan"];
    if (![plan isKindOfClass:[NSDictionary class]]) return;
    self.eventField.text = plan[@"event"] ?: @"";
    self.cityField.text = plan[@"city"] ?: @"";
    self.sessionField.text = plan[@"session"] ?: @"";
    self.priceField.text = plan[@"price"] ?: @"";
    self.quantityField.text = plan[@"quantity"] ?: @"";
    self.linkField.text = plan[@"link"] ?: @"";
    NSDate *saleDate = plan[@"saleDate"];
    if ([saleDate isKindOfClass:[NSDate class]] && [saleDate timeIntervalSinceNow] > 0) {
        self.salePicker.date = saleDate;
    }
}

- (NSDictionary *)currentPlan {
    return @{
        @"event": self.eventField.text ?: @"",
        @"city": self.cityField.text ?: @"",
        @"session": self.sessionField.text ?: @"",
        @"price": self.priceField.text ?: @"",
        @"quantity": self.quantityField.text ?: @"",
        @"link": self.linkField.text ?: @"",
        @"saleDate": self.salePicker.date
    };
}

- (void)savePlanAndSchedule {
    [self.view endEditing:YES];
    if (self.eventField.text.length == 0) {
        self.statusLabel.text = @"先填写演出名称。";
        return;
    }
    if ([self.salePicker.date timeIntervalSinceNow] <= 0) {
        self.statusLabel.text = @"开售时间必须晚于当前时间。";
        return;
    }
    NSString *link = [self.linkField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (link.length > 0 && ![self isOfficialDamaiURLString:link]) {
        self.statusLabel.text = @"链接必须是大麦官方 damai.cn 的 HTTPS 地址。";
        return;
    }

    [NSUserDefaults.standardUserDefaults setObject:[self currentPlan] forKey:@"DPTSavedPlan"];
    self.statusLabel.text = @"计划已保存在本机，正在申请通知权限……";
    [self scheduleLocalNotifications];
    [self updateCountdown];
}

- (void)scheduleLocalNotifications {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge)
                          completionHandler:^(BOOL granted, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!granted || error) {
                self.statusLabel.text = @"计划已保存；通知权限未开启，请在系统设置中允许通知。";
                return;
            }
            [center getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> *requests) {
                NSMutableArray<NSString *> *oldIDs = [NSMutableArray array];
                for (UNNotificationRequest *request in requests) {
                    if ([request.identifier hasPrefix:@"DamaiPocket."]) [oldIDs addObject:request.identifier];
                }
                [center removePendingNotificationRequestsWithIdentifiers:oldIDs];

                NSDate *saleDate = self.salePicker.date;
                NSArray<NSNumber *> *offsets = @[@600, @60, @0];
                NSArray<NSString *> *labels = @[@"10 分钟后开售", @"1 分钟后开售", @"现在开售"];
                for (NSUInteger i = 0; i < offsets.count; i++) {
                    NSDate *fireDate = [saleDate dateByAddingTimeInterval:-offsets[i].doubleValue];
                    if ([fireDate timeIntervalSinceNow] <= 0) continue;
                    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
                    content.title = [NSString stringWithFormat:@"DamaiPocket · %@", labels[i]];
                    NSString *event = self.eventField.text ?: @"演出";
                    NSString *session = self.sessionField.text ?: @"";
                    content.body = session.length ? [NSString stringWithFormat:@"%@ · %@", event, session] : event;
                    content.sound = UNNotificationSound.defaultSound;
                    NSDateComponents *components = [[NSCalendar currentCalendar] components:
                        (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay |
                         NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond)
                        fromDate:fireDate];
                    UNCalendarNotificationTrigger *trigger =
                        [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:components repeats:NO];
                    NSString *identifier = [NSString stringWithFormat:@"DamaiPocket.%lu", (unsigned long)i];
                    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier
                                                                                           content:content
                                                                                           trigger:trigger];
                    [center addNotificationRequest:request withCompletionHandler:nil];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.statusLabel.text = @"已保存，并安排开售前 10 分钟、1 分钟及开售时的本地提醒。";
                });
            }];
        });
    }];
}

- (BOOL)isOfficialDamaiURLString:(NSString *)value {
    NSURLComponents *components = [NSURLComponents componentsWithString:value];
    NSString *scheme = components.scheme.lowercaseString;
    NSString *host = components.host.lowercaseString;
    if (![scheme isEqualToString:@"https"] || host.length == 0) return NO;
    return [host isEqualToString:@"damai.cn"] || [host hasSuffix:@".damai.cn"];
}

- (void)openDamai {
    [self.view endEditing:YES];
    NSString *value = [self.linkField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSURL *url = nil;
    if (value.length == 0) {
        url = [NSURL URLWithString:@"https://www.damai.cn/"];
    } else if ([self isOfficialDamaiURLString:value]) {
        url = [NSURL URLWithString:value];
    } else {
        self.statusLabel.text = @"请先填写有效的大麦官方 HTTPS 链接。";
        return;
    }
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
        self.statusLabel.text = success ? @"已打开大麦官方页面；请在官方 App 内完成购票。" : @"无法打开链接，请检查大麦 App 或网络。";
    }];
}

- (void)updateCountdown {
    if (!self.isViewLoaded || !self.countdownLabel) return;
    NSTimeInterval remaining = [self.salePicker.date timeIntervalSinceNow];
    if (remaining <= 0) {
        self.countdownLabel.text = @"开售时间已到";
        return;
    }
    NSInteger seconds = (NSInteger)remaining;
    NSInteger days = seconds / 86400;
    NSInteger hours = (seconds % 86400) / 3600;
    NSInteger minutes = (seconds % 3600) / 60;
    NSInteger rest = seconds % 60;
    if (days > 0) {
        self.countdownLabel.text = [NSString stringWithFormat:@"距离开售：%ld 天 %02ld:%02ld:%02ld",
                                    (long)days, (long)hours, (long)minutes, (long)rest];
    } else {
        self.countdownLabel.text = [NSString stringWithFormat:@"距离开售：%02ld:%02ld:%02ld",
                                    (long)hours, (long)minutes, (long)rest];
    }
}

@end
