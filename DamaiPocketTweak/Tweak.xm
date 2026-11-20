#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/message.h>

static NSString *const DPBundle = @"cn.damai.iphone";
static NSInteger const DPTag = 0x44504B54;
static NSTimer *DPTimer;
static BOOL DPRunning, DPSubmitTapped;
static NSInteger DPStep = 0, DPWant = 1;
static CFTimeInterval DPLastTap = 0, DPSubmitTapTime = 0;
static NSString *DPSession = @"", *DPPrice = @"", *DPStatus = @"待命：打开大麦目标页面，点右侧“识别”。";

@interface DPNode : NSObject
@property(nonatomic,strong) UIView *view;
@property(nonatomic,copy) NSString *text;
@end
@implementation DPNode @end

// UI-only automation: it never calls Damai order APIs or reads payment credentials.
static BOOL DPIsDamai(void) { return [NSBundle.mainBundle.bundleIdentifier isEqualToString:DPBundle]; }
static NSString *DPText(UIView *v) {
    NSMutableArray *a = [NSMutableArray array];
    if ([v isKindOfClass:UILabel.class] && ((UILabel *)v).text.length) [a addObject:((UILabel *)v).text];
    if ([v isKindOfClass:UIButton.class]) {
        NSString *s = [(UIButton *)v currentTitle]; if (s.length) [a addObject:s];
    }
    if ([v isKindOfClass:UITextField.class] && ((UITextField *)v).text.length) [a addObject:((UITextField *)v).text];
    if (v.accessibilityLabel.length) [a addObject:v.accessibilityLabel];
    if (v.accessibilityValue.length) [a addObject:v.accessibilityValue];
    return [[a componentsJoinedByString:@" "] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
}
static BOOL DPVisible(UIView *v, UIView *w) {
    if (v.hidden || v.alpha < .03 || v.tag == DPTag) return NO;
    CGRect r = [v convertRect:v.bounds toView:w];
    return !CGRectIsEmpty(r) && CGRectIntersectsRect(r, w.bounds);
}
static void DPWalk(UIView *v, UIView *w, NSMutableArray *out) {
    if (!DPVisible(v,w)) return;
    NSString *s = DPText(v);
    if (s.length) { DPNode *n=[DPNode new]; n.view=v; n.text=s; [out addObject:n]; }
    for (UIView *c in v.subviews) DPWalk(c,w,out);
}
static NSArray *DPNodes(void) {
    NSMutableArray *a=[NSMutableArray array];
    for (UIWindow *w in UIApplication.sharedApplication.windows)
        if (!w.hidden && w.alpha>.03 && w.rootViewController) DPWalk(w.rootViewController.view,w,a);
    return a;
}
static NSString *DPAll(NSArray *nodes) {
    NSMutableArray *a=[NSMutableArray array]; for (DPNode *n in nodes) if(n.text.length)[a addObject:n.text];
    return [a componentsJoinedByString:@" | "];
}
static DPNode *DPFind(NSArray *nodes, NSString *needle) {
    for (DPNode *n in nodes) if ([n.text rangeOfString:needle options:NSCaseInsensitiveSearch].location!=NSNotFound) return n;
    return nil;
}
// Only activate explicit UIKit controls. Never invoke private gesture targets.
static BOOL DPTapView(UIView *v) {
    for (NSInteger i=0; v && i<8; i++,v=v.superview) {
        if (v.hidden || v.alpha<.03) continue;
        if ([v isKindOfClass:UIControl.class]) {
            UIControl *control=(UIControl *)v;
            if (!control.enabled || !control.userInteractionEnabled) return NO;
            [control sendActionsForControlEvents:UIControlEventTouchUpInside]; return YES;
        }
    }
    return NO;
}
static BOOL DPTap(NSArray *nodes, NSString *word, NSString *status) {
    for (DPNode *n in nodes) {
        if ([n.text rangeOfString:word options:NSCaseInsensitiveSearch].location==NSNotFound) continue;
        if (DPTapView(n.view)) { DPLastTap=CACurrentMediaTime(); DPStatus=status; return YES; }
    }
    return NO;
}
static BOOL DPHasLabel(UIView *v, NSString *needle) {
    if ([v.accessibilityLabel containsString:needle]) return YES;
    for (UIView *c in v.subviews) if (DPHasLabel(c,needle)) return YES;
    return NO;
}
static NSInteger DPNumber(UIView *v) {
    if ([v isKindOfClass:UILabel.class]) {
        NSString *s=[((UILabel *)v).text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        NSCharacterSet *notDigits=[[NSCharacterSet decimalDigitCharacterSet] invertedSet];
        if (s.length && [s rangeOfCharacterFromSet:notDigits].location==NSNotFound) { NSInteger q=s.integerValue; if(q>=1 && q<=6)return q; }
    }
    for (UIView *c in v.subviews) { NSInteger q=DPNumber(c); if(q)return q; }
    return 0;
}
static BOOL DPQuantity(NSArray *nodes) {
    UIView *plus=nil,*minus=nil;
    for(DPNode *n in nodes) {
        NSString *a=n.view.accessibilityLabel ?: @"";
        if([a containsString:@"增加按钮"])plus=n.view;
        if([a containsString:@"减少按钮"])minus=n.view;
    }
    if(!plus || !minus)return NO;
    UIView *box=plus; NSInteger now=0;
    for(NSInteger i=0;box && i<8;i++,box=box.superview) {
        if(DPHasLabel(box,@"减少按钮")){now=DPNumber(box);if(now)break;}
    }
    if(!now){DPStatus=@"数量控件已出现，但读不到当前数值；请在大麦页面手动调整数量。";return NO;}
    UIView *button=now<DPWant?plus:(now>DPWant?minus:nil);
    if(!button)return YES;
    if(DPTapView(button)){DPLastTap=CACurrentMediaTime();DPStatus=[NSString stringWithFormat:@"正在设置数量：%ld / %ld",(long)now,(long)DPWant];}
    return NO;
}
static void DPStart(NSString *session, NSString *price, NSInteger quantity);
static NSArray *DPCandidates(NSArray *nodes, NSString *pattern) {
    NSError *error=nil;
    NSRegularExpression *re=[NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    if(!re || error)return @[];
    NSMutableOrderedSet *found=[NSMutableOrderedSet orderedSet];
    for(DPNode *n in nodes) {
        NSString *s=n.text ?: @"";
        for(NSTextCheckingResult *m in [re matchesInString:s options:0 range:NSMakeRange(0,s.length)]) {
            NSString *v=[[s substringWithRange:m.range] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
            if(v.length)[found addObject:v];
        }
    }
    return found.array;
}
static NSString *DPRecognizeAndStart(NSInteger quantity) {
    NSArray *nodes=DPNodes();
    NSString *all=DPAll(nodes);
    if(!all.length)return @"没有读取到当前页面文字。请先打开大麦演出详情或票档页面，再点悬浮窗“识别”。";
    BOOL damaiPage=NO;
    for(NSString *word in @[@"演出",@"场次",@"票档",@"立即购买",@"立即预订",@"选座购买",@"选择场次"])
        if([all containsString:word]){damaiPage=YES;break;}
    if(!damaiPage)return @"当前页面不像大麦购票页面。请先打开目标演出页面，再点“识别”。";
    NSArray *sessions=DPCandidates(nodes,@"(?:20\\d{2}[年./-])?\\d{1,2}(?:月|[./-])\\d{1,2}日?\\s*(?:周[一二三四五六日天]\\s*)?\\d{1,2}:\\d{2}");
    NSArray *prices=DPCandidates(nodes,@"(?:¥|￥)\\s*\\d{2,6}(?:\\.\\d{1,2})?\\s*元?|\\d{2,6}(?:\\.\\d{1,2})?\\s*元");
    if(sessions.count!=1 || prices.count!=1) {
        DPStatus=[NSString stringWithFormat:@"识别到%lu个场次候选、%lu个票价候选；为避免误选，不会猜测。请在大麦页面进入唯一目标场次和票档后，再点“识别”。",(unsigned long)sessions.count,(unsigned long)prices.count];
        return DPStatus;
    }
    DPStart(sessions.firstObject,prices.firstObject,MAX(1,MIN(6,quantity)));
    return [NSString stringWithFormat:@"识别成功\\n场次：%@\\n票档：%@\\n数量：%ld张\\n已开始按当前页面识别结果推进；遇到验证码、排队、风控或选座会停止。",DPSession,DPPrice,(long)DPWant];
}

static void DPStop(NSString *reason) {
    void(^b)(void)=^{DPRunning=NO;[DPTimer invalidate];DPTimer=nil;DPStatus=reason?:@"已停止";};
    if(NSThread.isMainThread)b();else dispatch_async(dispatch_get_main_queue(),b);
}
static void DPScan(void);
static void DPStart(NSString *session, NSString *price, NSInteger quantity) {
    DPSession=[session stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    DPPrice=[price stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    DPWant=MAX(1,MIN(6,quantity));
    NSUserDefaults *d=NSUserDefaults.standardUserDefaults;
    [d setObject:DPSession forKey:@"dp.session"];[d setObject:DPPrice forKey:@"dp.price"];[d setInteger:DPWant forKey:@"dp.quantity"];
    DPStep=0;DPLastTap=0;DPSubmitTapped=NO;DPSubmitTapTime=0;DPRunning=YES;
    DPStatus=@"运行中：只识别并操作大麦当前可见 UI；验证、排队、风控出现即停止。";
    [DPTimer invalidate];DPTimer=[NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(__unused NSTimer *t){DPScan();}];DPScan();
}
static void DPScan(void) {
    // UIKit hierarchy access must always run on the main thread.
    if(!NSThread.isMainThread) {
        dispatch_async(dispatch_get_main_queue(), ^{ DPScan(); });
        return;
    }
    if(!DPRunning || !DPIsDamai() || CACurrentMediaTime()-DPLastTap<1.15)return;
    NSArray *nodes=DPNodes();NSString *all=DPAll(nodes);if(!all.length)return;
    for(NSString *word in @[@"验证码",@"滑块",@"安全验证",@"人机验证",@"风险验证",@"访问过于频繁",@"操作太频繁",@"异常访问",@"请求频繁",@"排队",@"前方等待",@"系统繁忙",@"暂不可购买",@"请稍后重试"])
        if([all containsString:word]){DPStop([NSString stringWithFormat:@"检测到%@，已停止；请在官方界面手动处理。",word]);return;}
    if([all containsString:@"请先登录"] || [all containsString:@"立即登录"]){DPStop(@"请先登录大麦，再重新开始。");return;}
    if([all containsString:@"支付宝安全支付"] || [all containsString:@"支付宝收银台"] || [all containsString:@"输入支付密码"] || [all containsString:@"确认付款"]){DPStop(DPSubmitTapped?@"已检测到提交订单后的付款页面：请核对场次、票档、数量和金额，再由你手动输入支付宝密码。不会读取或代填密码。":@"已到付款页面：核对金额后由你手动输入支付宝密码。不会读取或代填密码。");return;}

    // Stop before seat maps, order confirmation/submission, and all payment screens.
    for(NSString *word in @[@"选座",@"座位图",@"选择座位",@"请选座",@"区域图"]) {
        if([all containsString:word]){DPStop(@"检测到选座流程，已停止；请手动选座。");return;}
    }
    if([all containsString:@"提交订单"] || [all containsString:@"确认订单"] || [all containsString:@"订单确认"]) {
        // A submit tap is one-shot. Never tap again if the result is delayed or ambiguous.
        if(DPSubmitTapped) {
            if(CACurrentMediaTime()-DPSubmitTapTime>8.0)
                DPStop(@"已点击提交订单，但8秒内页面未明确跳转到付款页；为避免重复下单已停止，请手动检查大麦订单。");
            else
                DPStatus=@"已点击提交订单，正在等待付款页确认；不会重复点击。";
            return;
        }
        // Only submit after the selected show, price and quantity steps are complete.
        if(DPStep>=3 && DPSession.length && DPPrice.length &&
           [all containsString:DPSession] && [all containsString:DPPrice]) {
            BOOL tapped=DPTap(nodes,@"提交订单",@"已点击“提交订单”；等待页面确认。");
            if(!tapped)tapped=DPTap(nodes,@"确认订单",@"已点击“确认订单”；等待页面确认。");
            if(tapped) {
                DPSubmitTapped=YES;
                DPSubmitTapTime=CACurrentMediaTime();
                DPStatus=@"已点击订单提交按钮，等待大麦跳转付款页；不会重复点击。";
            } else {
                DPStop(@"已到订单确认页，但未找到明确可点击的提交按钮；为避免误操作已停止。");
            }
            return;
        }
        DPStop(@"已到订单确认页，但目标场次、票档或数量尚未全部确认；为避免误提交已停止。");
        return;
    }
    if([all containsString:@"立即支付"] || [all containsString:@"去支付"] ||
       [all containsString:@"支付宝安全支付"] || [all containsString:@"支付宝收银台"] ||
       [all containsString:@"输入支付密码"] || [all containsString:@"确认付款"]) {
        DPStop(@"已到支付环节。请核对订单金额并手动完成支付；不会点击付款或读取密码。"); return;
    }
    if(DPSession.length && DPStep<1 && [all containsString:DPSession] && DPTap(nodes,DPSession,@"已选择目标场次")){DPStep=1;return;}
    if(DPPrice.length && DPStep<2 && [all containsString:DPPrice] && DPTap(nodes,DPPrice,@"已选择目标票档")){DPStep=2;return;}
    if(DPStep==2){if(DPQuantity(nodes)){DPStep=3;DPStatus=[NSString stringWithFormat:@"数量已设为%ld，等待确认订单。",(long)DPWant];}return;}
    if(DPStep==0 && DPTap(nodes,@"立即购买",@"已进入购票选择页…"))return;
    if(DPStep==0 && DPTap(nodes,@"立即预订",@"已进入预订页…"))return;
    DPStatus=@"运行中：等待匹配场次/票档或大麦页面更新。";
}

@interface UIViewController (DamaiPocket)
- (void)dp_openPanel;
@end
@implementation UIViewController (DamaiPocket)
- (void)dp_openPanel {
    if(!DPIsDamai() || self.presentedViewController)return;
    UIAlertController *a=[UIAlertController alertControllerWithTitle:@"DamaiPocket · 页面识别"
        message:[NSString stringWithFormat:@"%@\n\n无需手动填写场次。打开目标演出/票档页面后，点“识别当前页面”即可。数量默认1张。",DPStatus]
        preferredStyle:UIAlertControllerStyleAlert];
    [a addTextFieldWithConfigurationHandler:^(UITextField *f){f.placeholder=@"购买数量（1–6，默认1）";f.text=@"1";f.keyboardType=UIKeyboardTypeNumberPad;}];
    [a addAction:[UIAlertAction actionWithTitle:@"关闭" style:UIAlertActionStyleCancel handler:nil]];
    [a addAction:[UIAlertAction actionWithTitle:@"停止" style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *x){DPStop(@"已手动停止。");}]];
    [a addAction:[UIAlertAction actionWithTitle:@"识别当前页面" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *x){
        NSInteger q=a.textFields.firstObject.text.integerValue;
        if(q<1 || q>6)q=1;
        NSString *result=DPRecognizeAndStart(q);
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *r=[UIAlertController alertControllerWithTitle:(DPRunning?@"识别成功":@"识别未完成") message:result preferredStyle:UIAlertControllerStyleAlert];
            [r addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:r animated:YES completion:nil];
        });
    }]];
    [self presentViewController:a animated:YES completion:nil];
}
@end

%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    if(!DPIsDamai() || [self isKindOfClass:UIAlertController.class])return;
    dispatch_async(dispatch_get_main_queue(),^{
        if(!self.isViewLoaded || !self.view.window || [self.view viewWithTag:DPTag])return;
        UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];b.tag=DPTag;
        b.frame=CGRectMake(MAX(8,self.view.bounds.size.width-66),self.view.safeAreaInsets.top+72,58,42);
        b.autoresizingMask=UIViewAutoresizingFlexibleLeftMargin;b.backgroundColor=[UIColor colorWithRed:.88 green:.16 blue:.20 alpha:.95];
        b.layer.cornerRadius=12;[b setTitle:@"识别" forState:UIControlStateNormal];[b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        b.titleLabel.font=[UIFont boldSystemFontOfSize:16];[b addTarget:self action:@selector(dp_openPanel) forControlEvents:UIControlEventTouchUpInside];[self.view addSubview:b];
    });
}
%end

// Deliberately do not hook UIApplication URL-opening methods. Payment handoff is
// detected from the visible Damai UI; avoiding global URL hooks reduces app-wide risk.
