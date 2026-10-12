import UIKit
import SnapKit
import AutoCollapseKit

/// UIKit application entry point; the scene delegate owns each window and its controllers.
@main
final class ACKDemoAppDelegate: UIResponder, UIApplicationDelegate {
    /// Supplies the UIKit scene delegate explicitly instead of relying on a storyboard.
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "AutoCollapseKit", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = ACKDemoSceneDelegate.self
        configuration.sceneClass = UIWindowScene.self
        return configuration
    }
}

/// Builds a native tab/navigation hierarchy for the three layout integrations.
final class ACKDemoSceneDelegate: UIResponder, UIWindowSceneDelegate {
    /// Created on scene connection; retained here so UIKit can display its controller tree.
    var window: UIWindow?

    /// Installs the example tabs into the window provided by the connecting UIKit scene.
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let tabController = UITabBarController()
        tabController.viewControllers = ACKDemoMode.allCases.enumerated().map { index, mode in
            let navigation = UINavigationController(rootViewController: ACKDemoViewController(mode: mode))
            navigation.navigationBar.prefersLargeTitles = true
            navigation.tabBarItem = UITabBarItem(title: mode.title, image: UIImage(systemName: mode.symbol), tag: index)
            return navigation
        }
        let sceneWindow = UIWindow(windowScene: windowScene)
        sceneWindow.rootViewController = tabController
        window = sceneWindow
        sceneWindow.makeKeyAndVisible()
    }
}

/// Chooses which adapter owns height and top spacing on the same view.
enum ACKDemoMode: CaseIterable {
    case snapKit, masonry, mixed

    /// Display title derived from the adapter selection and used by navigation and tabs.
    var title: String {
        switch self {
        case .snapKit: return "SnapKit"
        case .masonry: return "Masonry"
        case .mixed: return "混合使用"
        }
    }

    /// Native SF Symbol derived from the selected adapter for the tab bar.
    var symbol: String {
        switch self {
        case .snapKit: return "s.square"
        case .masonry: return "m.square"
        case .mixed: return "square.stack.3d.up"
        }
    }
}

/// Pure Swift/UIKit controls drive ordinary isHidden and updateConstraints operations.
final class ACKDemoViewController: UIViewController {
    /// Fixed at construction; identifies the adapter on this page.
    private let mode: ACKDemoMode
    /// Native preview owned by this controller; switch/button handlers update its state.
    private let demonstration: ACKDemoUIView
    /// Latest requested expanded height, changed only by the update-height button.
    private var requestedHeight: CGFloat = 64
    /// User updates this control to opt into or out of constraint folding.
    private let enabledSwitch = UISwitch()
    /// User updates this control to set the preview panel's actual hidden property.
    private let hiddenSwitch = UISwitch()
    /// Controller refreshes its title after height changes; touch events request updates.
    private let updateButton = UIButton(type: .system)
    /// Controller refreshes this label from the preview's real constraint constant.
    private let statusLabel = UILabel()

    /// Creates an independent demonstration and state for each tab.
    init(mode: ACKDemoMode) {
        self.mode = mode
        demonstration = ACKDemoUIView(mode: mode, height: 64)
        super.init(nibName: nil, bundle: nil)
        title = mode.title
    }

    /// No storyboard is used because the layout adapter is a required construction input.
    required init?(coder: NSCoder) { fatalError("Use init(mode:)") }

    /// Lays out accessible, scrollable controls around a preview using native UIKit.
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        navigationItem.largeTitleDisplayMode = .always

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let content = UIStackView()
        content.axis = .vertical
        content.spacing = 20
        content.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(content)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
            content.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32)
        ])

        let heading = makeLabel("隐藏视图，折叠标记的约束", style: .title2)
        heading.accessibilityTraits.insert(.header)
        content.addArrangedSubview(heading)
        content.addArrangedSubview(makeLabel("标记高度和顶部间距。隐藏期间更新高度，再显示时恢复最新值。", color: .secondaryLabel))

        // Only this outer preview is arranged; the folding panel is NOT a stack child.
        demonstration.backgroundColor = .secondarySystemGroupedBackground
        demonstration.layer.cornerRadius = 16
        demonstration.translatesAutoresizingMaskIntoConstraints = false
        demonstration.heightAnchor.constraint(greaterThanOrEqualToConstant: 240).isActive = true
        content.addArrangedSubview(demonstration)

        enabledSwitch.isOn = true
        enabledSwitch.accessibilityIdentifier = "auto-collapse-enabled"
        hiddenSwitch.accessibilityIdentifier = "panel-hidden"
        enabledSwitch.addTarget(self, action: #selector(switchDidChange), for: .valueChanged)
        hiddenSwitch.addTarget(self, action: #selector(switchDidChange), for: .valueChanged)
        content.addArrangedSubview(makeSwitchRow("自动折叠", control: enabledSwitch))
        content.addArrangedSubview(makeSwitchRow("隐藏内容", control: hiddenSwitch))

        // UIKit's filled configuration supplies a system button appearance on iOS 15+.
        var buttonConfiguration = UIButton.Configuration.filled()
        buttonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        updateButton.configuration = buttonConfiguration
        updateButton.accessibilityIdentifier = "update-height"
        updateButton.addTarget(self, action: #selector(updateHeightDidTap), for: .touchUpInside)
        content.addArrangedSubview(updateButton)

        statusLabel.numberOfLines = 0
        statusLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .monospacedSystemFont(ofSize: 17, weight: .regular))
        statusLabel.adjustsFontForContentSizeCategory = true
        statusLabel.accessibilityIdentifier = "constraint-status"
        content.addArrangedSubview(statusLabel)
        content.addArrangedSubview(makeLabel("未标记的宽度保持不变。关闭自动折叠会恢复展开高度，但视图依然隐藏。", style: .footnote, color: .secondaryLabel))
        synchronizePreview()
    }

    /// Creates multiline Dynamic Type text used by the page's explanatory components.
    private func makeLabel(_ text: String, style: UIFont.TextStyle = .body, color: UIColor = .label) -> UILabel {
        let label = UILabel()
        label.text = text
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: style)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = color
        return label
    }

    /// Keeps a readable title next to a system switch with its own accessibility label.
    private func makeSwitchRow(_ title: String, control: UISwitch) -> UIStackView {
        let label = makeLabel(title)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        control.accessibilityLabel = title
        control.setContentCompressionResistancePriority(.required, for: .horizontal)
        let row = UIStackView(arrangedSubviews: [label, control])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        return row
    }

    /// Both switches synchronize without altering the stored expanded-height request.
    @objc private func switchDidChange(_ sender: UISwitch) {
        synchronizePreview()
    }

    /// Ordinary DSL updates are intentionally performed even while the panel is hidden.
    @objc private func updateHeightDidTap(_ sender: UIButton) {
        requestedHeight = requestedHeight == 64 ? 96 : 64
        synchronizePreview()
    }

    /// Reads the real native height for status, rather than estimating it from the toggles.
    private func synchronizePreview() {
        demonstration.update(height: requestedHeight, hidden: hiddenSwitch.isOn, enabled: enabledSwitch.isOn)
        statusLabel.text = "请求展开高度：\(Int(requestedHeight)) pt\n当前约束高度：\(Int(demonstration.currentHeight)) pt"
        var configuration = updateButton.configuration ?? .filled()
        configuration.title = "更新展开高度：\(Int(requestedHeight)) → \(requestedHeight == 64 ? 96 : 64)"
        updateButton.configuration = configuration
    }
}

/// Real native layout; no stack view participates in hiding the folding panel.
final class ACKDemoUIView: UIView {
    /// Fixed at construction; chooses the DSL used for ordinary height updates.
    private let mode: ACKDemoMode
    /// Last applied request, updated only when the controller asks for a new height.
    private var requestedHeight: CGFloat
    /// The folding view, owned by this preview and updated by the controller's controls.
    private let panel = UILabel()
    /// Found after installation; retained for reading the actual constant in the UI.
    private var heightConstraint: NSLayoutConstraint?
    /// Read by the controller after each transition to display the true constraint state.
    var currentHeight: CGFloat { heightConstraint?.constant ?? 0 }

    /// Installs native surrounding layout and marks constraints using the chosen adapters.
    init(mode: ACKDemoMode, height: CGFloat) {
        self.mode = mode
        requestedHeight = height
        super.init(frame: .zero)
        let header = UILabel()
        header.text = "上方内容"
        header.font = .preferredFont(forTextStyle: .headline)
        header.adjustsFontForContentSizeCategory = true
        let footer = UILabel()
        footer.text = "下方内容会随约束移动"
        footer.font = .preferredFont(forTextStyle: .body)
        footer.numberOfLines = 0
        footer.adjustsFontForContentSizeCategory = true
        panel.text = "可折叠内容"
        panel.font = .preferredFont(forTextStyle: .body)
        panel.adjustsFontForContentSizeCategory = true
        panel.textAlignment = .center
        panel.backgroundColor = .systemTeal
        panel.textColor = .white
        panel.layer.cornerRadius = 10
        panel.clipsToBounds = true
        panel.ac_autoCollapseWhenHidden = true
        for child in [header, panel, footer] {
            child.translatesAutoresizingMaskIntoConstraints = false
            addSubview(child)
            NSLayoutConstraint.activate([
                child.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
                child.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
            ])
        }
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            footer.topAnchor.constraint(equalTo: panel.bottomAnchor, constant: 12),
            // Grow the outer preview for larger text instead of clipping its last label.
            footer.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -20)
        ])
        switch mode {
        case .snapKit:
            panel.snp.makeConstraints { make in
                make.top.equalTo(header.snp.bottom).offset(12).ac_makeCollapsible()
                make.height.equalTo(height).ac_makeCollapsible()
            }
        case .masonry:
            ACKMasonryExample.installTop(on: panel, below: header)
            ACKMasonryExample.installHeight(on: panel, value: height)
        case .mixed:
            panel.snp.makeConstraints { $0.height.equalTo(height).ac_makeCollapsible() }
            ACKMasonryExample.installTop(on: panel, below: header)
        }
        heightConstraint = panel.constraints.first { $0.firstAttribute == .height && $0.secondItem == nil }
    }

    /// Storyboard construction is unsupported because the adapter is a required input.
    required init?(coder: NSCoder) { fatalError("Use init(mode:height:)") }

    /// Preserves fold state through the shared native setter hook during ordinary updates.
    func update(height: CGFloat, hidden: Bool, enabled: Bool) {
        panel.ac_autoCollapseWhenHidden = enabled
        if requestedHeight != height {
            switch mode {
            case .snapKit, .mixed: panel.snp.updateConstraints { $0.height.equalTo(height) }
            case .masonry: ACKMasonryExample.updateHeight(on: panel, value: height)
            }
            requestedHeight = height
        }
        panel.isHidden = hidden
    }
}
