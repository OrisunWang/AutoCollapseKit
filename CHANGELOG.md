# 版本记录

## 0.1.0

- 首次发布 Core、SnapKit、Masonry 三个独立 subspec，支持单独及同时接入。
- 开启 ac_autoCollapseWhenHidden 后，视图显隐自动折叠和恢复已标记约束。
- 支持零值及自定义有符号折叠常量，隐藏期间更新后恢复最新展开值。
- 公开接口统一 ac_ 前缀，弱引用管理原生约束与视图。
- 提供 Swift/UIKit 演示 App、中文接入文档和隔离接入测试。
