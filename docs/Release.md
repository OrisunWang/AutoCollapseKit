# 发布流程

仓库：https://github.com/OrisunWang/AutoCollapseKit。首次发布版本为 0.1.0，tag 名称与 podspec 的 version 完全一致，不添加 v 前缀。trunk 发布需要维护者本机已有有效会话；凭据不保存到仓库。

## 发布准备

1. 更新 podspec 版本及 CHANGELOG.md，确认 README 接入示例、许可与作者信息完整。
2. 执行隔离接入测试及示例构建；行为变化需要重跑相应测试。
3. 执行 pod lib lint，检查本地源代码。
4. 提交源码并创建同版本 tag，推送 main 和该 tag，禁止覆盖已发布版本标签。
5. 执行 pod spec lint，从远程 tag 下载并构建所有 subspec。
6. 执行 pod trunk push，再通过 trunk API 和远程 refs 确认发布结果。

## 本机 Xcode 27 验证

当前工具链最低构建目标为 iOS 15；库 podspec 保持 iOS 13。以下 xcconfig 仅对发布验证命令设置构建目标，不改签名或宿主配置，也不声明已验证 iOS 13：

```sh
mkdir -p .build/release
printf 'IPHONEOS_DEPLOYMENT_TARGET = 15.0\n' > .build/release/ValidationOverrides.xcconfig
XCODE_XCCONFIG_FILE="$PWD/.build/release/ValidationOverrides.xcconfig" \
  pod lib lint AutoCollapseKit.podspec --use-modular-headers --platforms=ios
# 推送同版本 tag 后执行远程源校验。
XCODE_XCCONFIG_FILE="$PWD/.build/release/ValidationOverrides.xcconfig" \
  pod spec lint AutoCollapseKit.podspec --use-modular-headers --platforms=ios
XCODE_XCCONFIG_FILE="$PWD/.build/release/ValidationOverrides.xcconfig" \
  pod trunk push AutoCollapseKit.podspec --use-modular-headers
```

仅在查明警告来源且不影响集成时添加 --allow-warnings；不得跳过编译或 import 校验来发布。最新发布结果记录在 docs/Validation.md，原始日志留在忽略的 .build/ 目录。
