# AutoCollapseKit

按需标记 UIKit 约束，在视图隐藏时应用折叠常量，显示时恢复最新展开值。支持原生 Auto Layout、SnapKit、Masonry，以及同一视图混用。

库支持 iOS 13+，Swift 5。演示 App 使用 Swift + UIKit 实现，最低 iOS 15。当前版本为 [`0.1.1`](https://cocoapods.org/pods/AutoCollapseKit)，通过 CocoaPods 接入；源码仓库为 [OrisunWang/AutoCollapseKit](https://github.com/OrisunWang/AutoCollapseKit)。默认安装 Core，不自动引入两套布局库。

当前源码的适配依赖范围：SnapKit `>= 4.0.1, < 6.0`，Masonry `>= 0.5.3, < 2.0`；可沿用宿主项目在范围内的版本，无需升级到 5.6 / 1.1。0.1.1 提供放宽后的依赖范围；0.1.0 保留原范围。下限依据、历史版本编译限制与测试结果见 [docs/Validation.md](docs/Validation.md#依赖范围放宽)。

## CocoaPods 接入

选择以下适配组合之一，默认只安装 Core：

```ruby
# 原生 Auto Layout；等价于 AutoCollapseKit/Core。
pod 'AutoCollapseKit', '~> 0.1.1'
```

```ruby
# 仅 SnapKit，自动包含 Core 和 SnapKit。
pod 'AutoCollapseKit/SnapKit', '~> 0.1.1'
```

```ruby
# 仅 Masonry，自动包含 Core 和 Masonry，不编译本库的 Swift 适配源码。
pod 'AutoCollapseKit/Masonry', '~> 0.1.1'
```

```ruby
# 同时接入；Core 共享，不重复安装。
pod 'AutoCollapseKit/SnapKit', '~> 0.1.1'
pod 'AutoCollapseKit/Masonry', '~> 0.1.1'
```

开发或调试本地源码时，把版本参数替换为 `:path`；从 GitHub 指定版本接入时使用 `:git` 和 `:tag`：

```ruby
pod 'AutoCollapseKit/SnapKit', :path => '../AutoCollapseKit'
pod 'AutoCollapseKit/Masonry', :git => 'https://github.com/OrisunWang/AutoCollapseKit.git', :tag => '0.1.1'
```

Swift 与 Objective-C 混用时建议在 Podfile 添加 `use_modular_headers!`；这样 Masonry 等 Objective-C 依赖具有模块声明，支持 Swift Pod 以静态库接入。也支持 `use_frameworks! :linkage => :static`。库不修改宿主签名配置或依赖源码。

## SnapKit

```swift
import UIKit
import SnapKit
import AutoCollapseKit

// 只有这个视图自己切换 isHidden 时触发它的约束变化。
view.ac_autoCollapseWhenHidden = true
view.snp.makeConstraints { make in
    // 标记必须位于链式调用末尾，先完成 offset/inset/priority/labeled。
    make.height.equalTo(44).ac_makeCollapsible()
    make.top.equalTo(previousView.snp.bottom).offset(12).ac_makeCollapsibleTo(0)
}
// 高度和上间距归零，不额外添加宽高约束。
view.isHidden = true
// 隐藏期间只更新值，不能重复标记临时的 update 描述。
view.snp.updateConstraints { make in
    make.height.equalTo(80)
}
// 恢复最新展开高度 80，而不是创建时的 44。
view.isHidden = false
```

支持 `makeConstraints`、`remakeConstraints`、`prepareConstraints` 创建时标记。后续可通过原约束引用 `update(offset:)`、`update(inset:)` 或 `updateConstraints` 更新。重建时需再次标记新约束。

**不要在 `updateConstraints` 中调用标记方法。**它使用临时约束描述，而不是已安装的约束。标记方法也不能放在 offset/inset/priority/labeled 之前，读取 SnapKit 的 lazy constraint 后后续 description 改动不会作用于已创建约束。

## Masonry

```objc
#import <AutoCollapseKit/AutoCollapseKit.h>
#import <AutoCollapseKit/MASConstraint+AutoCollapseKit.h>
#import <Masonry/Masonry.h>

// 所有这些 UI 操作必须在主线程执行。
view.ac_autoCollapseWhenHidden = YES;
[view mas_makeConstraints:^(MASConstraintMaker *make) {
    // 复合约束会递归标记所有叶节点。
    make.width.height.equalTo(@44).ac_makeCollapsible();
    make.top.equalTo(previousView.mas_bottom).offset(12).ac_makeCollapsibleTo(0);
}];
view.hidden = YES;
[view mas_updateConstraints:^(MASConstraintMaker *make) {
    // 更新已标记约束，无需也不要重新标记。
    make.width.height.equalTo(@80);
}];
view.hidden = NO;
```

## 原生约束与常量含义

```swift
// Core 提供相同的 native 标记能力，不会主动激活约束。
let height = view.heightAnchor.constraint(equalToConstant: 44)
height.ac_makeCollapsible()
height.isActive = true
view.ac_autoCollapseWhenHidden = true
```

`ac_makeCollapsibleTo(-3)` 指底层有符号 constant 为 -3，不是 inset 的 3。比如 SnapKit bottom.inset(12) 的展开 constant 为 -12，可以折叠到 -3。多属性描述会对每条底层约束应用相同折叠常量。

标记的归属是 **firstItem**，不是第二个引用视图；布局指南使用 owningView。若要隐藏 A 后改变间距，请以 A 为约束第一项建立对应约束。拥有 multiplier 或跨视图尺寸关系时，constant 归零不代表最终尺寸为零；请设计合适的约束表达式。

公开属性、方法及底层登记函数统一使用 `ac_` 前缀。自定义适配层可通过 `ac_registerConstraint(constraint, collapsedConstant)` 登记原生约束（主线程调用）；普通业务代码使用上面的链式标记即可。内部类型保留 `ACK`，运行时钩子使用 `ac_autoCollapse_`，不属于业务调用接口。

## 状态、动画与迁移

- 开关默认 false。对已隐藏视图开启立即折叠；关闭立即恢复展开值，但不会改变 isHidden。
- 重复显隐、重复开启、重复标记不会丢失展开值。隐藏时外部常量更新保存新值，仍保持折叠状态。
- 不增加零宽高约束、不改变优先级、不解除约束，也不调用 layoutIfNeeded。
- 内部记录和登记集合使用弱引用。失活约束继续跟随状态，以便重新激活；重建后的旧约束不会保留新 UI。
- 主线程以外的受管操作 Debug 断言、Release 拒绝执行。折叠值必须有限，布局指南必须已有 owningView。
- 子类重写 setHidden 必须调用 super；未调用 super 的子类和父视图隐藏不会触发子视图折叠。
- 原底层登记函数 `ACKRegisterConstraint` 改名为 `ac_registerConstraint`，调用方需要同步更新；不保留旧别名。
- 库使用一次性方法交换，请移除旧 `aif_*` 实现；与其他交换同一方法的库混用时，它们必须保留原实现链。

```swift
// 布局先稳定，再由调用者控制共同父视图上的动画。
container.layoutIfNeeded()
view.isHidden = true
UIView.animate(withDuration: 0.25) {
    container.layoutIfNeeded()
}
```

## 演示与验证

```sh
cd Example
xcodegen generate
pod install
open AutoCollapseKitDemo.xcworkspace
```

Example 的 Podfile 使用 iOS 15，并通过 `post_install` 将 Pods 各目标的最低构建版本提升到至少 iOS 15，避免 Xcode 27 的旧部署版本报错；高于 iOS 15 的依赖目标不会被降低。重新执行 `pod install` 后可直接从 Xcode 构建，不需要手动修改 Pods 工程或额外传入部署版本参数。这个设置仅用于演示工程，库的 podspec 仍声明 iOS 13。

选择 AutoCollapseKitDemo scheme 和 iOS 15+ 模拟器。SnapKit、Masonry、混合使用三个页面均可切换自动折叠、隐藏内容和更新展开高度。演示使用纯 Swift + UIKit：UIApplicationDelegate、UIWindowSceneDelegate、UITabBarController 和 UIViewController，不包含 SwiftUI。控制区使用 UIStackView，折叠面板使用普通 UIView 布局，不依赖 UIStackView 的隐藏行为。Masonry 的 Objective-C 调用桥接由 Swift 示例页面调用。

```sh
# 生成八个独立工作区，避免不同 subspec 之间的依赖泄漏。
python3 scripts/generate-validation.py
# 运行全部组合的安装、构建和 XCTest，需安装 CocoaPods、XcodeGen 和模拟器。
SIMULATOR_ID='<available-device-uuid>' bash scripts/validate.sh
# 验证两个适配层的依赖下限；生成静态库和静态 framework 工作区。
python3 scripts/generate-validation.py --combination both --linkage all \
  --snapkit-version 4.0.1 --masonry-version 0.5.3
```

测试工程产物位于忽略的 `.build/`。模拟器构建仅在 xcodebuild 调用中传入 `CODE_SIGNING_ALLOWED=NO`，不更改项目签名配置。实际验证结果见 [docs/Validation.md](docs/Validation.md)，完整行为设计见 [docs/Design.md](docs/Design.md)。

Xcode 27.1 不接受低于 iOS 15 的构建目标，因此验证脚本默认在命令行传入 `IPHONEOS_DEPLOYMENT_TARGET=15.0`。库的 podspec 仍声明 iOS 13；使用支持 iOS 13 的旧版 Xcode 可指定 `BUILD_DEPLOYMENT_TARGET=13.0` 验证。当前环境无法证明 iOS 13 的运行兼容性。

版本变更见 [CHANGELOG.md](CHANGELOG.md)，发布流程见 [docs/Release.md](docs/Release.md)。作者：Orisun Wang。

## 许可

本项目采用 [MIT License](LICENSE)，Copyright © 2026 Orisun Wang。SnapKit、Masonry 为独立依赖，许可见各自仓库。
