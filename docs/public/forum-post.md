# 第二版 2.0.0-alpha1 测试说明草稿（未发布）

本文是随本地测试包保存的说明草稿，尚未发帖、上传附件或正式发布。非官方选机助手，在待售商品报告上增加四款 Pro 系列机型目录、巨魔 / 完整越狱用途交集、实际系统范围与逐项依据。不会执行安装或越狱，不保证实物固件状态。

候选按转转 12.8.5、arm64、最低部署 iOS 15.0 构建；提供三种安装文件不等于三种环境都已真机验证。规则版本 compat-2026-10-21.1，详见[兼容说明](compatibility.md)。旧 test5 的部分真机流程不能扩展为本版全流程通过。第二版、连续翻页、收藏成功回读及 rootless / RootHide 加载仍待测试。

安装前保留自己的旧包，移除同一 App 的旧注入，只选一种：

- TrollFools：[dylib](ZZPicker-2.0.0-alpha1-trollfools.dylib) 或 [zip](ZZPicker-2.0.0-alpha1-trollfools.zip)。
- [rootless deb](ZZPicker-2.0.0-alpha1-rootless.deb) / [RootHide deb](ZZPicker-2.0.0-alpha1-roothide.deb)。
- [本地合集](ZZPicker-2.0.0-alpha1-release.zip) / [源码](ZZPicker-2.0.0-alpha1-source.zip)。
- [单文件校验](SHA256SUMS) / [合集校验](ZZPicker-2.0.0-alpha1-release.zip.sha256)。

以上是随包相对文件名，不表示文件已经上线。首轮关闭自动收藏，设置最多 5 件 / 2 分钟，核对机型与实际范围后再开始。旧设置会保留原收藏偏好，请主动检查。任务命中暂停、查看后手动继续。后续单件收藏需独立回读和手动核对，未知不反复重试。

完整步骤见[安装与恢复](install.md)，反馈见[诊断隐私](feedback.md)。默认诊断不含商品明细或损坏设置原文；详细模式需主动选择，两种模式均先预览后手动分享，无自动上传。不要发送账号密码、Cookie、Token 或完整抓包。
