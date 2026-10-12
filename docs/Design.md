# AutoCollapseKit 产品与技术设计

## 产品目标与功能范围
为 UIKit 视图提供按约束标记的隐藏折叠能力。支持原生 Auto Layout、SnapKit、Masonry，以及同一视图混用。只修改标记约束的 constant，不增加零宽高约束，不改变优先级、关系或 multiplier。首版 iOS 13+，Swift 5，CocoaPods 支持本地源码及公开版本接入；按用户授权发布至 GitHub 和 CocoaPods trunk。

## 用户流程与模块
1. 设置 `view.ac_autoCollapseWhenHidden = true`。
2. 创建或重建约束，在 offset/inset/priority 等设置结束后调用 `ac_makeCollapsible()` 或 `ac_makeCollapsibleTo()`。
3. 修改 `view.isHidden`。隐藏应用折叠常量；显示恢复最新展开值。

Core 仅依赖 UIKit，以 Objective-C 实现供 Objective-C 和 Swift 共用。SnapKit subspec 使用 Swift 扩展；Masonry subspec 使用 Objective-C Category。UIKit 是需求中的 Auto Layout 接口所在平台。按用户要求，演示 App 使用 Swift + UIKit，入口和 SceneDelegate 创建原生标签栏、导航及 UIViewController 页面；不使用 SwiftUI。Masonry 调用保留 Objective-C 桥接。

## 业务规则与状态转换
- 开关默认关闭。先隐藏后开启、先开启后登记均立即同步；重复设置状态不会重新保存展开值。
- 关闭开关立即恢复展开值，同时保留标记，方便再次启用。
- 折叠常量默认零；自定义常量为底层有符号 constant，bottom/right 不自动反转。
- 展开时外部更新常量直接生效；隐藏时外部更新写入展开值，约束继续保持折叠值。内部状态切换不能作为外部更新记录。
- 标记属于 firstItem 为 UIView 的视图，或 firstItem 为 UILayoutGuide 的 owningView。不跟随祖先的 hidden 状态。
- 登记不激活约束。非激活约束也同步状态，重新激活时无需重新标记。视图与约束释放后弱引用自动清理。
- 标记仅用于 make/remake（或 prepare），不要在 updateConstraints 中重复标记。SnapKit update 使用临时描述，重复标记可能修改临时 constant，破坏更新值。
- 动画由调用者在共同父视图上执行 layoutIfNeeded；库不强制刷新。

## 数据模型与并发
ACKCollapseRecord 关联在 NSLayoutConstraint 上：expandedConstant（最近一次外部更新）、collapsedConstant（标记接口更新）、owner（弱引用所属视图）、internalWriteDepth（阻止内部写入覆盖展开值）。UIView 关联开关与弱引用约束集合。登记重复使用同一记录，仅改变折叠值，不重拍展开值。

所有已启用/已标记对象的访问在主线程进行；错误线程操作在 Debug 断言，Release 拒绝执行库管理的写入。未启用视图和未标记约束保持系统行为。

## Runtime 与异常处理
Core 首次使用时 dispatch_once 交换 UIView.setHidden: 与 NSLayoutConstraint.setConstant:。私有方法统一 ac_ 前缀，并使用 ac_autoCollapse_ 命名运行时钩子以减少 Category 选择器冲突，交换保留原实现并仅对受管对象生效。Masonry 首次标记时交换 MASViewConstraint.install，在原安装完成后登记。私有 layoutConstraint/childConstraints 访问通过集中封装和 respondsToSelector 检查；不兼容版本 Debug 断言、Release 输出诊断并跳过标记。

Core 不自动解除约束或修正业务布局冲突；标记的是 constant 而非尺寸本身，有 multiplier 的尺寸约束归零 constant 不保证尺寸归零。必须移除旧 aif_* 扩展，避免旧实现额外生成零宽高约束。子类必须调用 super 的 setHidden:；重写且不调用 super 无法被 UIView 入口拦截。其他库交换相同方法时需保留原实现链。

## 技术与交付约束
公开属性、方法及登记函数统一 ac_；内部类型继续使用 ACK，私有 Runtime 方法使用 ac_autoCollapse_。Core 导出的底层登记函数为 ac_registerConstraint，两个适配层共用。不修改第三方源码、现有 App Bundle ID、证书、Development Team、签名或描述文件。新建演示 App 初始 Bundle ID 为 com.example.AutoCollapseKitDemo。不依赖 AIFFoundation。每个功能类型、方法、属性和主要 UI 组件说明用途与更新来源。发布仓库为 https://github.com/OrisunWang/AutoCollapseKit，作者 Orisun Wang；项目所有者明确确认采用 MIT License。版本与源码 tag 保持一致，发布过程及实际结果见 Release.md 和 Validation.md。

## 验收标准
四个隔离组合 Core/SnapKit/Masonry/Both 均可静态库及静态 framework 接入。覆盖开关顺序、重复显隐、关闭恢复、自定义负值、复合约束、隐藏期间更新、重建、失活/激活、混用、弱引用释放和不影响未标记对象。执行 pod lib lint、模拟器构建、XCTest 和演示运行；实际结果与限制记录在 Validation.md。

## 演示工程构建配置
演示 App 最低 iOS 15。Example Podfile 同步声明 iOS 15，并在 post_install 中将依赖目标的部署版本设为至少 iOS 15，保证重新安装依赖后的 Xcode 直接构建可用；不降低更高版本的依赖目标，不修改库的 iOS 13 声明或签名相关配置。

UIKit 演示入口通过 AppDelegate 提供 scene 配置，Example/Info.plist 显式登记 ACKDemoSceneDelegate，保证已有场景恢复时仍创建窗口。project.yml 是该场景配置的生成来源。页面状态读取已安装的 NSLayoutConstraint.constant，展示真实折叠结果；三个页面分别持有自己的开关和展开高度。

## 适配依赖版本范围

当前源码允许 SnapKit `>= 4.0.1, < 6.0`、Masonry `>= 0.5.3, < 2.0`。下限来自原始历史源码检查及真实构建、布局测试：SnapKit 4.0.1 修复新版 Swift Auto Layout 类型别名并声明 Swift 版本；Masonry 0.5.3 修复旧枚举优先级的编译问题。SnapKit 6.0.0 已移除 podspec，当前 CocoaPods 接入不扩展至该主版本；Masonry 私有接口保持主版本上限，避免接受未经检查的未来内部实现。

标记、更新、折叠与恢复逻辑沿用现有实现，无需针对旧版本增加分支或修改第三方源码。具体历史源码依据、验证组合与发布生效范围见 Validation.md 的“依赖范围放宽”。
