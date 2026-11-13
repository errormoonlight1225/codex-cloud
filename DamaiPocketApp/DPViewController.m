#import "DPViewController.h"
#import <WebKit/WebKit.h>

@interface DPViewController ()
@property(nonatomic,strong) UITextField *urlField,*sessionField,*priceField,*quantityField;
@property(nonatomic,strong) WKWebView *webView;
@property(nonatomic,strong) UILabel *statusLabel;
@property(nonatomic,strong) NSTimer *timer;
@property(nonatomic,strong) UIButton *startButton;
@property(nonatomic,assign) BOOL running;
@end

@implementation DPViewController
- (void)viewDidLoad { [super viewDidLoad]; self.title=@"DamaiPocket 抢票"; self.view.backgroundColor=UIColor.systemBackgroundColor; [self buildUI]; }
- (UITextField *)field:(NSString *)p type:(UIKeyboardType)t { UITextField *v=[UITextField new]; v.placeholder=p; v.borderStyle=UITextBorderStyleRoundedRect; v.backgroundColor=UIColor.secondarySystemBackgroundColor; v.font=[UIFont systemFontOfSize:15]; v.keyboardType=t; v.autocorrectionType=UITextAutocorrectionTypeNo; v.autocapitalizationType=UITextAutocapitalizationTypeNone; v.delegate=self; [v.heightAnchor constraintEqualToConstant:40].active=YES; return v; }
- (UIButton *)button:(NSString *)s sel:(SEL)sel color:(UIColor *)c { UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem]; [b setTitle:s forState:UIControlStateNormal]; [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal]; b.backgroundColor=c; b.layer.cornerRadius=9; b.titleLabel.font=[UIFont systemFontOfSize:14 weight:UIFontWeightSemibold]; [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside]; [b.heightAnchor constraintEqualToConstant:42].active=YES; return b; }
- (void)buildUI {
 UIStackView *s=[UIStackView new]; s.axis=UILayoutConstraintAxisVertical; s.spacing=7; s.translatesAutoresizingMaskIntoConstraints=NO; [self.view addSubview:s];
 [NSLayoutConstraint activateConstraints:@[[s.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:10],[s.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-10],[s.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:6],[s.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-6]]];
 UILabel *h=[UILabel new]; h.text=@"网页登录大麦，自动匹配场次/票档、设置数量并提交订单。验证码、选座和付款由你本人完成。"; h.numberOfLines=2; h.font=[UIFont systemFontOfSize:12]; h.textColor=UIColor.secondaryLabelColor; [s addArrangedSubview:h];
 self.urlField=[self field:@"大麦演出详情页 HTTPS 链接" type:UIKeyboardTypeURL];
 self.sessionField=[self field:@"场次关键词，例如 11月20日 19:30" type:UIKeyboardTypeDefault];
 self.priceField=[self field:@"票档关键词，例如 680元" type:UIKeyboardTypeDefault];
 self.quantityField=[self field:@"数量 1-6" type:UIKeyboardTypeNumberPad]; self.quantityField.text=@"1";
 [s addArrangedSubview:self.urlField]; [s addArrangedSubview:self.sessionField]; [s addArrangedSubview:self.priceField]; [s addArrangedSubview:self.quantityField];
 UIStackView *row=[UIStackView new]; row.axis=UILayoutConstraintAxisHorizontal; row.spacing=6;
 [row addArrangedSubview:[self button:@"打开演出页" sel:@selector(openEvent) color:UIColor.systemBlueColor]];
 self.startButton=[self button:@"开始抢票" sel:@selector(start) color:UIColor.systemRedColor]; [row addArrangedSubview:self.startButton];
 [row addArrangedSubview:[self button:@"停止" sel:@selector(stop) color:UIColor.darkGrayColor]]; [s addArrangedSubview:row];
 self.statusLabel=[UILabel new]; self.statusLabel.text=@"状态：先在网页内登录大麦账号。"; self.statusLabel.font=[UIFont systemFontOfSize:12]; self.statusLabel.numberOfLines=2; self.statusLabel.textColor=UIColor.systemOrangeColor; [s addArrangedSubview:self.statusLabel];
 WKWebViewConfiguration *c=[WKWebViewConfiguration new]; c.websiteDataStore=WKWebsiteDataStore.defaultDataStore;
 self.webView=[[WKWebView alloc] initWithFrame:CGRectZero configuration:c]; self.webView.translatesAutoresizingMaskIntoConstraints=NO; self.webView.allowsBackForwardNavigationGestures=YES; [s addArrangedSubview:self.webView]; [self.webView.heightAnchor constraintGreaterThanOrEqualToConstant:220].active=YES;
 [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.damai.cn/"]]];
}
- (BOOL)textFieldShouldReturn:(UITextField *)t { [t resignFirstResponder]; return YES; }
- (BOOL)validURL:(NSString *)u { NSURLComponents *c=[NSURLComponents componentsWithString:u]; NSString *h=c.host.lowercaseString; return [c.scheme.lowercaseString isEqual:@"https"] && ([h isEqual:@"damai.cn"] || [h hasSuffix:@".damai.cn"]); }
- (void)openEvent { [self.view endEditing:YES]; NSString *u=self.urlField.text ?: @""; if(![self validURL:u]) { self.statusLabel.text=@"状态：请输入有效的大麦 HTTPS 链接"; return; } [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:u]]]; self.statusLabel.text=@"状态：打开页面；首次使用请在网页内扫码登录。"; }
- (void)start { [self.view endEditing:YES]; if(![self validURL:self.webView.URL.absoluteString ?: @""] || !self.sessionField.text.length || !self.priceField.text.length) { self.statusLabel.text=@"状态：打开演出页并填写场次、票档关键词。"; return; } NSInteger q=self.quantityField.text.integerValue; if(q<1||q>6) { self.statusLabel.text=@"状态：数量范围为 1-6"; return; } self.running=YES; [self.startButton setTitle:@"抢票运行中" forState:UIControlStateNormal]; self.statusLabel.text=@"状态：开始检测库存…"; [self.timer invalidate]; self.timer=[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(tick) userInfo:nil repeats:YES]; [self tick]; }
- (void)stop { self.running=NO; [self.timer invalidate]; self.timer=nil; [self.startButton setTitle:@"开始抢票" forState:UIControlStateNormal]; self.statusLabel.text=@"状态：已停止"; }
- (void)tick {
 if(!self.running)return;
 NSString *session=[self.sessionField.text stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
 NSString *price=[self.priceField.text stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
 NSInteger qty=MAX(1,MIN(6,self.quantityField.text.integerValue));
 NSString *js=[NSString stringWithFormat:
 @"(()=>{const S='%@',P='%@',Q=%ld;const T=e=>(e.innerText||e.textContent||'').replace(/\\s+/g,' ').trim();const V=e=>e&&e.getBoundingClientRect().width>0;const C=e=>{e.scrollIntoView({block:'center'});e.click()};const B=T(document.body);const R=()=>{window.__dpPoll=(window.__dpPoll||0)+1;if(window.__dpPoll%8===0){location.reload();return '刷新页面等待库存'}return '等待库存变化'};"
 "if(/验证码|滑块|安全验证/.test(B))return '需要手动完成安全验证';if(/选座购买|选择座位/.test(document.title+' '+B))return '需要手动完成选座';"
 "if(/订单确认|确认订单/.test(document.title+' '+B)){let b=[...document.querySelectorAll('button,a,[role=button]')].find(e=>V(e)&&/提交订单|确认提交/.test(T(e)));if(b){C(b);return '订单已提交，等待支付';}return '已进入订单确认页';}"
 "let ts=document.querySelector('.sku-times-card'),ps=document.querySelector('.sku-tickets-card');"
 "if(ts||ps){if(ts){let e=[...ts.querySelectorAll('.bui-dm-sku-card-item')].find(x=>T(x).includes(S)&&!/(无票|缺货|售罄)/.test(T(x)));if(!e)return R();if(!/active|selected/.test(e.className+' '+e.getAttribute('aria-selected'))){C(e);return '已选场次';}}"
 "if(ps){let e=[...ps.querySelectorAll('.item-content')].find(x=>T(x).includes(P)&&!/(无票|缺货|售罄)/.test(T(x)));if(!e)return R();if(!/active|selected/.test(e.className+' '+e.getAttribute('aria-selected'))){C(e);return '已选票档';}}"
 "let plus=document.querySelectorAll('.number-edit-bg');if(plus.length>1){let n=document.querySelector('.number-edit-num'),v=parseInt(n?T(n):'1')||1;if(v<Q){C(plus[1]);return '设置数量 '+(v+1)+'/'+Q;}}"
 "let ok=document.querySelector('.bui-btn-contained');if(ok&&V(ok)&&!ok.disabled){C(ok);return '确认票档数量并进入订单';}return '选票页检测中';}"
 "let buy=[...document.querySelectorAll('.buy__button__text,button,a,[role=button]')].find(e=>V(e)&&/立即预订|立即购买|选座购买/.test(T(e)));if(buy){C(buy);return '发现可购买入口，进入选票页';}return R();})()",
 session,price,(long)qty];
 [self.webView evaluateJavaScript:js completionHandler:^(id v,NSError *e){ if(!self.running)return; NSString *m=e?e.localizedDescription:([v isKindOfClass:NSString.class]?v:@"检测中"); dispatch_async(dispatch_get_main_queue(),^{self.statusLabel.text=[@"状态：" stringByAppendingString:m];}); if([m containsString:@"订单已提交"]||[m containsString:@"安全验证"]||[m containsString:@"手动完成选座"])[self stop]; }];
}
- (void)dealloc { [self.timer invalidate]; }
@end
