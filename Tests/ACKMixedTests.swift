#if ACK_HAS_SNAPKIT && ACK_HAS_MASONRY
import XCTest
import UIKit
import SnapKit
import AutoCollapseKit

/// The same first-item view owns constraints created by both independent adapters.
final class ACKMixedTests: XCTestCase {
    /// SnapKit height and Masonry top spacing share one fold transition and latest updates.
    func testBothAdaptersOnTheSameView() {
        let parent = UIView()
        let previous = UIView()
        let view = UIView()
        parent.addSubview(previous)
        parent.addSubview(view)
        var height: Constraint!
        view.snp.makeConstraints { make in
            height = make.height.equalTo(44).ac_makeCollapsible().constraint
        }
        ACKMasonryExample.installTop(on: view, below: previous)
        let top = parent.constraints.first { $0.firstItem === view && $0.firstAttribute == .top }!
        view.ac_autoCollapseWhenHidden = true
        view.isHidden = true
        XCTAssertEqual(height.layoutConstraints[0].constant, 0)
        XCTAssertEqual(top.constant, 0)
        view.snp.updateConstraints { $0.height.equalTo(80) }
        top.constant = 20
        view.isHidden = false
        XCTAssertEqual(height.layoutConstraints[0].constant, 80)
        XCTAssertEqual(top.constant, 20)
    }
}
#endif
