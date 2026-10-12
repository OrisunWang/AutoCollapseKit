#if ACK_HAS_SNAPKIT
import XCTest
import UIKit
import SnapKit
import AutoCollapseKit

/// Real SnapKit tests guard lazy materialization and updates of installed constraints.
final class ACKSnapKitTests: XCTestCase {
    /// Hidden updates use the installed object; temporary update descriptions stay unmarked.
    func testHiddenUpdateRemakeAndActivation() {
        let view = UIView()
        view.ac_autoCollapseWhenHidden = true
        var height: Constraint!
        view.snp.makeConstraints { make in
            height = make.height.equalTo(44).ac_makeCollapsible().constraint
        }
        view.isHidden = true
        XCTAssertEqual(height.layoutConstraints[0].constant, 0)
        view.snp.updateConstraints { $0.height.equalTo(88) }
        XCTAssertEqual(height.layoutConstraints[0].constant, 0)
        view.isHidden = false
        XCTAssertEqual(height.layoutConstraints[0].constant, 88)
        height.update(offset: 96)
        view.isHidden = true
        height.deactivate()
        height.update(offset: 100)
        height.activate()
        XCTAssertEqual(height.layoutConstraints[0].constant, 0)
        view.isHidden = false
        XCTAssertEqual(height.layoutConstraints[0].constant, 100)
        view.isHidden = true
        view.snp.remakeConstraints { make in
            height = make.height.equalTo(70).ac_makeCollapsibleTo(2).constraint
        }
        XCTAssertEqual(height.layoutConstraints[0].constant, 2)
        view.isHidden = false
        XCTAssertEqual(height.layoutConstraints[0].constant, 70)
    }

    /// `size` materializes multiple natives; prepare must not activate either one.
    func testPreparedCompositeAndInitiallyHidden() {
        let view = UIView()
        view.isHidden = true
        view.ac_autoCollapseWhenHidden = true
        let constraints = view.snp.prepareConstraints { make in
            make.size.equalTo(CGSize(width: 80, height: 40)).ac_makeCollapsible()
        }
        XCTAssertEqual(constraints[0].layoutConstraints.count, 2)
        for native in constraints[0].layoutConstraints {
            XCTAssertFalse(native.isActive)
            XCTAssertEqual(native.constant, 0)
        }
        constraints.forEach { $0.activate() }
        view.isHidden = false
        XCTAssertEqual(Set(constraints[0].layoutConstraints.map(\.constant)), Set([CGFloat(80), CGFloat(40)]))
    }

    /// Registered adapters do not change neighbouring unmarked constraints or inset signs.
    func testSignedBottomInsetAndUnmarkedWidth() {
        let parent = UIView()
        let view = UIView()
        parent.addSubview(view)
        var bottom: Constraint!
        view.snp.makeConstraints { make in
            bottom = make.bottom.equalToSuperview().inset(12).ac_makeCollapsibleTo(-3).constraint
            make.width.equalTo(80)
        }
        view.ac_autoCollapseWhenHidden = true
        view.isHidden = true
        XCTAssertEqual(bottom.layoutConstraints[0].constant, -3)
        XCTAssertEqual(view.constraints.first { $0.firstAttribute == .width }?.constant, 80)
        view.isHidden = false
        XCTAssertEqual(bottom.layoutConstraints[0].constant, -12)
    }
}
#endif
