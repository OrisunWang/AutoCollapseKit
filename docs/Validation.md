# 验证记录

日期：2026-10-12（Asia/Shanghai）。环境：Xcode 27.1、CocoaPods 1.16.2、iOS 26.5 / 27.0 模拟器。库版本 0.1.0。

## 隔离接入矩阵

每个组合使用独立 Xcode 工程、Podfile、Pods 和测试工作区，避免两个适配层互相泄漏依赖。全部在 iOS 26.5 iPhone 17 Pro 模拟器执行。

| 组合 | 静态库 | 静态 framework | 每种配置测试数 |
| --- | --- | --- | --- |
| Core | 通过 | 通过 | 6 |
| SnapKit | 通过 | 通过 | 9 |
| Masonry | 通过 | 通过 | 8 |
| SnapKit + Masonry | 通过 | 通过 | 12 |

共 70 次 XCTest 测试执行，0 失败。各配置的 Podfile.lock 已核对：Core 没有 SnapKit/Masonry；仅 SnapKit 没有 Masonry；仅 Masonry 没有 SnapKit。Core/Masonry 适配不包含 Swift 源码。

最终工程改为 XcodeGen `settingPresets: project`，避免目标模板默认写入签名身份。重新安装依赖并再次执行完整八组合矩阵，70 次测试仍全部通过；演示 App 最终工程再次构建通过。最终演示和验证工程的 project.pbxproj 中未配置 DEVELOPMENT_TEAM、CODE_SIGN_IDENTITY、PROVISIONING_PROFILE 或 CODE_SIGN_ENTITLEMENTS。

依赖解析为 SnapKit 5.7.1、Masonry 1.1.0。额外在独立的 `snapkit-framework-snapkit5.6.0` 工程固定 SnapKit 5.6.0，9 个测试通过，验证声明依赖下限。首次混用冒烟验证另外执行 12 个测试并通过。

## 覆盖行为

- 默认关闭、先隐藏后开启、先开启后登记、重复显隐与重复开启、关闭恢复最新值。
- 默认零值、自定义负常量、重复标记保留展开值、不改变未标记宽度、不生成尺寸约束。
- UILayoutGuide owningView、父视图隐藏不影响子视图独立状态、视图和约束弱引用释放。
- SnapKit 普通更新、引用更新、prepare 复合尺寸、隐藏期间重建、失活及重新激活、bottom inset 符号。
- Masonry 复合尺寸、普通更新、引用更新、隐藏期间重建、uninstall/install。
- 同一视图同时登记 SnapKit 高度和 Masonry 顶部间距，共同折叠并恢复最新值。

## Pod 校验

完整命令通过（包含所有 subspec 的编译和 import 校验）：

```sh
XCODE_XCCONFIG_FILE="$PWD/.build/lint/ValidationOverrides.xcconfig" \
pod lib lint AutoCollapseKit.podspec --private --allow-warnings \
  --use-modular-headers --platforms=ios \
  --validation-dir="$PWD/.build/lint/Build" --no-clean
```

覆盖文件仅设置 `IPHONEOS_DEPLOYMENT_TARGET = 15.0`。校验结果为 `AutoCollapseKit passed validation`，使用 allow-warnings 的原因是明确的 `example.invalid` 发布地址占位。源码构建另有 Masonry 自身的弃用/noescape/重复字典键警告，以及 Xcode AppIntents 元数据提示；未修改第三方代码来消除它们。

## 演示 App

- `AutoCollapseKitDemo.xcworkspace` 构建通过，安装并成功启动于 iOS 26.5 和 iOS 27.0 模拟器。
- 在可见的 iOS 27.0 Device Hub 界面检查三个页面：SnapKit、Masonry、混合使用。
- SnapKit/Masonry 均实际操作：64 pt 显示 → 隐藏为 0 → 隐藏期间更新为 96 → 再显示为 96。可见面板和下方内容的位置变化符合约束变化。
- 混合页面实际操作：隐藏 → 更新为 96 → 关闭自动折叠，视图保持隐藏但恢复 96 pt 占位 → 再显示并重新开启。界面和状态显示正确。

## 限制与可复现位置

Xcode 27.1 强制最低构建版本 iOS 15；隔离接入矩阵通过命令行覆盖构建版本，podspec 仍为 iOS 13。演示工程现通过 Example Podfile 的 post_install 持久应用 iOS 15 下限，可直接在 Xcode 构建。**当前环境没有完成 iOS 13 的构建和运行验证**，需要使用支持该版本的 Xcode/模拟器补验。演示 App 使用 UIKit 的 UIButton.Configuration 系统按钮样式，最低为 iOS 15。

初始验证时项目仅本地交付、发布元数据为占位；当前发布准备已配置真实仓库与作者，并由用户确认 MIT 许可，最新发布状态见后续记录。不存在证书、Development Team、描述文件或现有项目 Bundle ID 修改；仅新建演示及验证目标拥有初始测试用 Bundle ID，矩阵构建通过命令行关闭代码签名。

原始日志、Podfile.lock、xcresult 与矩阵汇总在忽略目录 `.build/`：`matrix-results.json`、各 fixture 的 `matrix-build.log`、`lint/lint.log`、`demo-build.log`。验证脚本 `scripts/validate.sh` 可重跑完整矩阵，最低版本工程通过 `generate-validation.py --snapkit-version 5.6.0` 生成。

## 演示工程部署版本报错修复

Example Podfile 的 platform 改为 iOS 15，并添加 post_install，仅将 Pods 各 Debug/Release 目标低于 iOS 15 的部署版本提升到 15.0。再次 pod install 后检查 AutoCollapseKit、Masonry、SnapKit、SnapKit_Privacy 与 Pods 聚合目标，共 10 个配置均为 15.0。

验证命令不再传入 IPHONEOS_DEPLOYMENT_TARGET：

```sh
cd Example
xcodebuild -workspace AutoCollapseKitDemo.xcworkspace -scheme AutoCollapseKitDemo \
  -destination 'platform=iOS Simulator,id=5933F3D7-1682-4F92-A9AE-8FBBEC10D22B' \
  -derivedDataPath ../.build/DemoDerivedData CODE_SIGNING_ALLOWED=NO build
```

结果 BUILD SUCCEEDED，无旧部署版本报错。日志在 `.build/demo-persistent-target-build.log`。修复前后对比确认现有证书、签名配置及 Bundle ID 未改变；库 podspec 的 iOS 13 声明保留。

## Swift + UIKit 演示改造

按用户要求移除 SwiftUI，使用 Swift 的 AppDelegate、SceneDelegate、UITabBarController、UINavigationController 和 UIViewController。Masonry 的 Objective-C 桥接保留供 Swift 调用；库的 Core 与两个适配层没有修改。

通过显式 Info.plist 场景配置验证已安装 App 的场景恢复，防止缺失 scene delegate 导致空窗口。最终 UIKit 演示使用上述 xcodebuild 命令构建通过，无需部署版本覆盖；最新构建日志为 `.build/demo-uikit-build.log`。安装并启动在 iOS 27.0 的 iPhone 18 Pro Max 模拟器上，实际检查如下：

- SnapKit、Masonry、混合使用：64 pt → 隐藏为 0 → 隐藏期间更新请求为 96（实际仍为 0）→ 显示为 96。
- 混合使用额外检查：隐藏时关闭自动折叠恢复 96 pt 占位；重新开启立即回到 0；再次显示恢复 96。
- 三个原生标签页面、开关、按钮与真实约束状态文字显示正常；折叠面板的布局不依赖 UIStackView 自动隐藏。

本次改动仅为演示界面、场景配置与文档，未重新执行上文库的八组合 XCTest 矩阵。改造前后比较演示工程和 Pods 工程的受保护设置，签名配置和 Bundle ID 完全相同。

## ac_ 前缀统一

公开属性、方法和底层登记函数统一为 ac_：ACKRegisterConstraint 改为 ac_registerConstraint；Core 和 Masonry 的运行时钩子统一为 ac_autoCollapse_，更新了声明、方法交换选择器和原实现调用。Swift/Objective-C 适配层、现有测试与文档同步更新，无旧名称兼容别名，内部类型仍使用 ACK。

改名后的验证：Core 静态库 6 个 XCTest 通过；SnapKit + Masonry 静态 framework 12 个 XCTest 通过，共 18 个测试、0 失败。Core 现有负常量测试直接调用 ac_registerConstraint，验证公开 C 接口，Swift 适配层验证 Swift 导入与调用。Swift/UIKit 演示构建通过。本次没有重新执行完整八组合矩阵或 Pod lint。

日志与结果在 `.build/prefix-core-library.log`、`.build/prefix-core-library.xcresult`、`.build/prefix-both-framework.log`、`.build/prefix-both-framework.xcresult` 和 `.build/prefix-demo-build.log`。源码、测试和示例不再包含 ack_ 方法或旧登记函数调用；比较演示与 Pods 工程确认签名配置及 Bundle ID 未改变。

## 0.1.0 首次公开发布准备

用户授权发布至 https://github.com/OrisunWang/AutoCollapseKit 和 CocoaPods trunk，并明确选择 MIT License。podspec 配置真实仓库、作者、LICENSE 与版本 0.1.0；README 补充版本安装、Git 标签安装与本地开发接入，新增 CHANGELOG.md 和 Release.md。

正式发布元数据的 pod lib lint 已通过，包含 Core、SnapKit、Masonry 与默认 subspec 编译和导入校验。没有使用 --private、--allow-warnings、--skip-tests 或 --skip-import-validation；仅通过 XCODE_XCCONFIG_FILE 在本机工具链下覆盖构建目标为 iOS 15，podspec 保持 iOS 13。日志为 `.build/release/local-lint.log`。重新 pod install 后签名和 Bundle ID 与先前设置一致。

源码行为沿用前述测试结果，本次仅修改发布元数据和文档。远程标签校验及 trunk 结果在发布后继续记录，不把本地校验等同于 trunk 发布成功。

## 0.1.0 发布结果

2026-10-12（Asia/Shanghai）首次发布完成：

- 发布提交 c10ef5499af23d138c23bc7844b89c4f1216d42e；main 与带注释的 0.1.0 标签已推送至指定 GitHub 仓库。远程标签解引用指向该发布提交，公开 raw podspec 与本地文件一致。
- pod spec lint 从远程 tag 下载校验，全部 subspec 编译与导入通过；未使用允许警告或跳过检查选项。日志 `.build/release/remote-lint.log`。
- pod trunk push AutoCollapseKit.podspec --use-modular-headers 返回 AutoCollapseKit (0.1.0) successfully published。日志 `.build/release/trunk-push.log`。
- pod trunk info 显示 0.1.0，服务端发布时间为 2026-10-12 03:28:36 UTC。trunk 官方规范接口返回的 canonical JSON 与本地 pod ipc spec 结果完全一致；仓库、标签、MIT 许可、作者、默认 Core 及适配依赖均一致。
- CocoaPods 页面：https://cocoapods.org/pods/AutoCollapseKit。版本源码：https://github.com/OrisunWang/AutoCollapseKit/tree/0.1.0。

发布使用本机现有 SSH GitHub 认证和有效 trunk 会话，无凭据入库。LICENSE、版本接入说明、CHANGELOG 和发布流程均已提交；生成依赖、构建产物及用户状态文件排除在仓库之外。签名配置和 Bundle ID 保持原值。iOS 13 的构建运行验证限制仍与前文一致。

## 依赖范围放宽

2026-10-12（Asia/Shanghai），当前源码将 SnapKit 从 `~> 5.6` 放宽至 `>= 4.0.1, < 6.0`，Masonry 从 `~> 1.1` 放宽至 `>= 0.5.3, < 2.0`。本次未修改运行时或适配逻辑，也未修改第三方源码。已发布的 0.1.0、Git 标签和 trunk 规范保持原范围；此变更随 0.1.1 发布，原 0.1.0 标签和 trunk 规范保持不变。

### 历史源码依据

下载两个官方仓库完整历史，对比适配所用的类型、安装、更新与底层约束接口：

- SnapKit 3.0.0 的 `layoutConstraints` 为 private，3.2.0 虽已公开，但仍使用旧 SDK 的 Auto Layout 类型和浮点优先级。4.0.0 尚未修复新版 Swift 中已改名的 `NSLayoutRelation` / `NSLayoutAttribute`，并且 podspec 未声明 Swift 版本。直接以 Swift 5 编译原始 4.0.0 源码，报这两个类型已改名的错误，因此不把它纳入当前 Swift 5 接入范围。
- [SnapKit 4.0.1 的类型别名](https://github.com/SnapKit/SnapKit/blob/4.0.1/Source/Typealiases.swift)添加 Swift 4.2 及以上的类型分支，[podspec](https://github.com/SnapKit/SnapKit/blob/4.0.1/SnapKit.podspec)声明 Swift 4.0；其 `ConstraintMakerFinalizable.constraint` 和 `Constraint.layoutConstraints` 已公开。4.0.1 与 4.2.0 的 Source 目录相同；到 5.0.0，本适配层涉及的三个文件仅 Constraint.swift 的弃用声明发生变化。随后检查 5.6.0 / 5.7.1 的对应接口和 constant 更新流程，适配无需版本分支。
- [SnapKit 5.7.1 → 6.0.0 的变更](https://github.com/SnapKit/SnapKit/compare/5.7.1...6.0.0)移除了 SnapKit.podspec；6.0.0 的 Package.swift 要求 Swift tools 6.0、最低 iOS 14。当前库只提供 CocoaPods subspec，因此保留 `< 6.0`，未宣称支持 SnapKit 6。
- Masonry 0.4.0 尚无 `mas_remakeConstraints`，0.5.0 加入复合属性链、remake 和更新时的 relation 匹配修复。但 0.5.0–0.5.2 的 MASUtilities.h 用枚举保存浮点优先级常量。固定 0.5.0 的真实工程构建失败：`integer constant expression must have integer type`。
- [Masonry 0.5.3 的修复提交](https://github.com/SnapKit/Masonry/commit/4bf0d0f)将优先级定义改成有类型的常量，解决上述编译问题。[变更记录](https://github.com/SnapKit/Masonry/blob/v1.1.0/CHANGELOG.md)也记录该修复。检查 0.5.3、0.6.0、0.6.4、1.0.0 和 1.1.0 的 `MASViewConstraint.install`、`layoutConstraint`、`MASCompositeConstraint.childConstraints`，登记所需的选择器与安装后读取方式保持可用。由于使用私有接口，保留 `< 2.0`，避免自动接受未来主版本的内部实现变动。

### 本次构建及行为测试

环境沿用 Xcode 27.1、iOS 26.5 iPhone 17 Pro 模拟器。仅在 xcodebuild 调用中设置 `IPHONEOS_DEPLOYMENT_TARGET=15.0` 和 `CODE_SIGNING_ALLOWED=NO`；未改现有签名、证书及 Bundle ID。

| 固定依赖组合 | 静态库 | 静态 framework | 每种配置测试数 |
| --- | --- | --- | --- |
| SnapKit 4.0.1 | 通过 | 通过 | 9 |
| Masonry 0.5.3 | 通过 | 通过 | 8 |
| SnapKit 4.0.1 + Masonry 0.5.3 | 通过 | 通过 | 12 |
| SnapKit 5.7.1 + Masonry 1.1.0 | 通过 | 通过 | 12 |

合计 82 次 XCTest、0 失败；逐项核对 Podfile.lock 的实际依赖版本。覆盖隐藏期间更新、复合约束、remake、原约束引用更新、失活后重新激活和两个适配层混用。区间内其他版本为历史源码检查，本次未逐版本运行测试；iOS 13 构建运行的既有限制仍然存在。

验证生成脚本新增 `--masonry-version`，可以独立或同时固定两个库，并以版本后缀隔离工作区。复现下限组合：

```sh
python3 scripts/generate-validation.py --combination both --linkage all \
  --snapkit-version 4.0.1 --masonry-version 0.5.3
# 分别进入两个生成目录执行 pod install，再按已有验证命令运行 XCTest。
```

原始材料位于忽略的 `.build/dependency-history/`：两个官方 Git 历史副本、`snapkit4.0.0-typecheck.log`、`range-results.json`。17 个历史标签的公开接口/私有选择器检查及 commit SHA 记录于 `source-checks.json`。下限及当前版本组合的日志、lock 和 xcresult 在 `.build/fixtures/` 对应目录的 `compatibility*.log`、`Compatibility*.xcresult`。Masonry 0.5.0 负向构建日志位于 `both-framework-snapkit4.0.0-masonry0.5.0/compatibility.log`。

最终 `pod lib lint AutoCollapseKit.podspec --use-modular-headers --platforms=ios` 通过，涵盖默认 Core 和全部适配 subspec 的编译与 import 校验。仅使用前述 xcconfig 的部署版本覆盖，未使用允许警告或跳过校验选项。日志为 `.build/dependency-history/range-lint.log`，末尾为 `AutoCollapseKit passed validation`。

## 0.1.1 发布准备

用户授权以 0.1.1 发布本次依赖范围放宽。podspec 版本、CHANGELOG、README 接入示例及 Git tag 示例同步更新为 0.1.1。功能源码不变，沿用前述 82 次测试及历史源码检查；本次重新执行 0.1.1 的本地 lint、远程标签 lint 和 trunk 发布校验，结果在发布完成后记录。

0.1.1 本地 `pod lib lint` 通过，包含所有 subspec 编译和导入，未跳过检查或允许警告。Example 重新 `pod install`，锁文件同步至 0.1.1，实际布局依赖仍为 SnapKit 5.7.1 / Masonry 1.1.0；演示 App 的模拟器构建通过。安装前后比较主工程与 Pods 工程的证书/签名字段及 Bundle ID，保持完全一致。日志位于 `.build/release/0.1.1/local-lint.log`、`demo-install.log`、`demo-build.log`。

## 0.1.1 发布结果

2026-10-12 11:50:41（Asia/Shanghai）发布完成，CocoaPods 官方记录为 2026-10-12 03:50:41 UTC。

- 发布提交 `63df0c1675db2977ed306cf9fdb48674f0831008`；main 和带注释的 `0.1.1` 标签已推送至 GitHub，远程标签解引用指向该提交。公开标签 podspec 与本地发布文件完全一致，未覆盖 0.1.0 标签。
- 本地 `pod lib lint`、从远程标签下载的 `pod spec lint` 均通过，覆盖全部 subspec 编译与导入；未允许警告或跳过检查。库行为沿用依赖范围验证的 82 次 XCTest、0 失败。0.1.1 的演示 App 重新安装本地依赖并构建通过。
- `pod trunk push AutoCollapseKit.podspec --use-modular-headers` 返回 `AutoCollapseKit (0.1.1) successfully published`；`pod trunk info` 已列出 0.1.1。官方规范接口返回的 JSON 与本地 `pod ipc spec` 完全一致，包含 SnapKit `>= 4.0.1, < 6.0`、Masonry `>= 0.5.3, < 2.0`。
- [0.1.1 源码](https://github.com/OrisunWang/AutoCollapseKit/tree/0.1.1)；[CocoaPods](https://cocoapods.org/pods/AutoCollapseKit)。README、CHANGELOG 和 Example/Podfile.lock 已同步版本。

原始日志、远程 refs 和规范比对材料位于忽略的 `.build/release/0.1.1/`：`local-lint.log`、`remote-lint.log`、`trunk-push.log`、`trunk-after.log`、`remote-refs.log`、`local-spec.json`、`trunk-spec.json`。本次没有修改证书、签名配置或 Bundle ID；iOS 13 构建运行的既有限制仍然保留。
