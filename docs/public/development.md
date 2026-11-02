# 开发与版本管理

开发和发布统一使用 [bingdilian/zz-picker-public](https://github.com/bingdilian/zz-picker-public)。默认分支是 `v1-compatibility`。

| 分支 | 用途 | 版本状态 |
| --- | --- | --- |
| `v1-compatibility` | 第一版维护、已验证问题修复 | 已发布 1.2.0-beta9 |
| `v2-compatibility` | 第二版兼容规则和交互开发 | 开发中，尚无第二版 Release |

## 选择开发版本

源码直接位于当前分支根目录的 `src/`、`scripts/`、`tests/`；不需要复制到另一个仓库，也没有并列的 v1/v2 源码目录。

```sh
git status --short
git switch v1-compatibility   # 第一版
# 或 git switch v2-compatibility
```

切换前先提交或妥善保存改动。两个版本独立提交、测试和推送，不要把第二版整分支直接合入第一版。发布安装包时使用对应版本标签，第二版验收前不创建 Release。

## 构建与测试

需要 Xcode、Python 3.12 或更新版本和 Node.js。在仓库根目录运行：

```sh
make test
```

第一版 `make check` 会重新构建并写入 `dist/`；请先备份需要保留的安装包。第二版每次选择全新的输出目录：

```sh
ZZ_PICKER_OUTPUT_DIR=build/v2-check-unique make check
ZZ_PICKER_OUTPUT_DIR=build/v2-ui-unique make ui-tests
```

第二版输出目录已存在同名产物时会拒绝覆盖。`build/` 和 `dist/` 被 Git 忽略，切换分支不会自动切换它们；核对包内版本，不要把遗留的第一版安装包当成第二版。

## 提交与推送

Git 身份使用 GitHub noreply 邮箱。先查看差异与检查结果，再向当前版本对应的远程分支正常推送，不使用强推。源码、使用说明与发布说明分别核对；本地构建成功不能代替真机测试。

迁移前的设计、历史诊断与安装候选仅保留为本地参考，不随迁移公开。旧私有仓库退出日常开发，不再双向同步；请勿重新合入其原始历史。
