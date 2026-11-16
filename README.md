# DamaiPocket · Dopamine rootless tweak

面向 iPad 8（A10、arm64）与 Dopamine / ElleKit rootless 环境，注入官方大麦 App：`cn.damai.iphone`。当前针对资料库中的大麦 9.0.38 做 UI 适配。

## 功能

- 在大麦 App 页面右侧显示 `DP` 浮动入口。
- 设置场次关键词、票档关键词和数量（1–6）。
- 根据大麦当前可见 UI 选择场次与票档、调整数量，并推进到订单确认与支付入口。
- 订单提交前请核对演出、场次、价格、数量及实名观演人；购票须知必须由你亲自勾选。
- 到支付宝/收银台后停止；支付密码由你本人输入。本工具不读取、存储或代填密码。

## 安全边界

不调用大麦私有下单 API，不处理或绕过验证码、人机验证、排队、风控、频率限制或选座流程。检测到这些情况会停止并让你在官方界面手动处理。UI 控件在不同活动、版本和灰度页面可能变化；本构建需在实际 iPad 上验证，不能保证每场演出都能自动推进。

## 构建

GitHub Actions → **Build DamaiPocket Dopamine Tweak**。也可向 `main` 推送 `DamaiPocketTweak/` 下的更改自动构建。成功后下载 artifact **DamaiPocket-Dopamine-DEB**，用 Sileo/Zebra 安装。

构建目标：Theos、iPhoneOS 16.5 SDK、arm64、iOS 14.0+、rootless。依赖 ElleKit。安装前确认设备为 Dopamine rootless 环境；不要安装旧版网页壳 artifact。
