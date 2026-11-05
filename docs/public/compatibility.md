# 兼容范围与已知限制 · 1.2.0-beta16

| 项目 | 当前范围 |
|---|---|
| 转转 App | 适配基线 12.8.5 |
| 动态库 | arm64，最低部署 iOS 15.0 |
| 构建变体 | TrollFools、rootless、RootHide |
| 运行方式 | 保持转转前台。切出、锁屏或干预原页面会暂停任务。 |

在「选机设置 → 说明 / 环境」可查看硬件型号代码、iOS、转转版本、插件版本与编译变体。非适配基线或无法识别的转转版本需要明确确认后再启动。

## 真机记录

已有记录使用 iPhone 13 Pro Max、iOS 15.4.1、转转 12.8.5，通过 TrollFools 直接注入 dylib。记录涵盖报告筛选、命中与收藏状态回读。截图里选购的 iPhone 15 Pro Max 及其 iOS 版本是商品条件。[README 真机实践](https://github.com/bingdilian/zz-picker-public/tree/v1-compatibility#真机实践)

rootless、RootHide、TrollFools 压缩包直接导入和其他设备组合需要自行验证。iOS 15.1.1 搭配转转 12.8.5 的收藏路径仍待复测。编译与模拟器结果只覆盖本地检查。

验机报告字段和页面结构随转转版本及商品变化。已启用的条件缺少必要字段时，商品列为待确认。可从筛选核验记录打开详情复核。长时间运行会导致手机发热，介意请勿使用。[反馈说明](feedback.md)
