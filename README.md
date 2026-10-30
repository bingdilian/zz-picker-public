# 转转选机助手 · 1.2.0-beta9（收藏收尾修复测试包）

面向社区免费试用的非官方插件。按型号、待售手机 iOS 区间、购买渠道、容量和成色筛选商品，在转转前台逐件读取验机报告，命中后暂停供你查看。无需另行注册、付费或连接插件服务器。

第一版当前版本为 **1.2.0-beta9**，对应分支 `v1-compatibility`。修复收藏待确认后全局等待不结束的问题：无法核实的商品在本次 App 进程内隔离，禁止再次自动收藏，可继续扫描其他商品；查看详情后返回会只读核验收藏，确认成功后更新结果且不重复计数。新增收藏尝试、点击、请求、回读和收尾诊断。保留 beta8 设置保存及此前修复；用户已反馈 beta9 在其原测试手机上运行正常，收藏可用；该反馈不代表所有设备、系统或商品路径均已验证。

**当前版本下载：[1.2.0-beta9 安装文件与校验清单](https://github.com/bingdilian/zz-picker/releases/tag/v1.2.0-beta9)**

| 使用环境 | 下载文件 |
|---|---|
| TrollFools 注入 | [dylib](https://github.com/bingdilian/zz-picker/releases/download/v1.2.0-beta9/ZZPicker-1.2.0-beta9-trollfools.dylib) / [zip](https://github.com/bingdilian/zz-picker/releases/download/v1.2.0-beta9/ZZPicker-1.2.0-beta9-trollfools.zip)，任选一种 |
| 普通 Dopamine / rootless | [rootless.deb](https://github.com/bingdilian/zz-picker/releases/download/v1.2.0-beta9/ZZPicker-1.2.0-beta9-rootless.deb) |
| Dopamine RootHide | [roothide.deb](https://github.com/bingdilian/zz-picker/releases/download/v1.2.0-beta9/ZZPicker-1.2.0-beta9-roothide.deb) |
| 全部安装格式、文档与源码 | [完整合集](https://github.com/bingdilian/zz-picker/releases/download/v1.2.0-beta9/ZZPicker-1.2.0-beta9-release.zip) |

校验文件：[SHA256SUMS](https://github.com/bingdilian/zz-picker/releases/download/v1.2.0-beta9/SHA256SUMS)；合集另附 `.sha256` 文件。TrollFools 选择 dylib 或对应 zip，不能直接注入 deb。

第二版的机型选择器、巨魔 / 越狱兼容性筛选与 iOS 范围联动在 [`v2-compatibility`](https://github.com/bingdilian/zz-picker/tree/v2-compatibility) 开发，尚未包含在本版，也没有第二版安装包。

安装包位于 Release 的 **Assets**；GitHub 自动生成的 `Source code (zip)` 仅为源码，不能直接注入。请先移除旧注入，再安装对应的一种文件，并完全重开转转。本版为测试版，下方兼容范围与待验证项仍适用。

适配基线为转转 **12.8.5**；动态库为 **arm64**，最低部署版本 **iOS 15.0**。这只是编译条件，实际安装还受注入工具、系统和 App 状态限制。平台换新电池等收藏二次确认尚未自动处理，不能视为两种收藏路径均已完整适配。已有 iPhone 13 Pro Max / iOS 15.4.1 / TrollFools 环境的历史记录，用户现已反馈 beta9 运行及收藏正常；其他环境仍需分别验证。

- [安装、更新、卸载与使用](docs/public/install.md)
- [兼容范围与已知限制](docs/public/compatibility.md)
- [反馈与诊断隐私](docs/public/feedback.md)
- [版本记录](docs/public/CHANGELOG.md)
- [社区发帖稿](docs/public/forum-post.md)

首次使用先阅读帮助，确认“说明 / 环境”中的版本与编译变体，保持转转前台。新用户自动收藏默认关闭；升级保留已保存的开关值，旧用户请自行核对。建议先关闭收藏，只验证筛选和报告结果。

任务上限：默认处理 100 件、有效运行 15 分钟，达到任一上限暂停，需新建任务。全局停用会停止任务与采集并保留设置入口、已有结果；已发出的收藏不能撤回。详细边界见安装说明。

仓库包含源码与构建脚本。本地编译和检查通过只能说明对应检查通过，不能替代手机上的安装、连续翻页或收藏验证。发布文件与 SHA-256 校验清单以实际分发包为准，插件只提供本地、手动更新，不自动发帖或发布。

开发者可在安装 Xcode、Python 3 与 Node.js 的 Mac 上进入源码目录，执行 `make check` 构建三种分发格式并运行本地检查；`make ui-tests` 需要已安装的 iOS 模拟器运行时。输出位于 `dist/`，旧版文件不会被自动删除，新版合集只收录当前版本。
