import SnapKit
import UIKit

/// Terminal markers for constraints created by make/remake/prepareConstraints.
extension ConstraintMakerFinalizable {
    /// Folds every native constraint in this description to zero when its owner hides.
    @discardableResult
    public func ac_makeCollapsible() -> ConstraintMakerFinalizable {
        ac_makeCollapsibleTo(0)
    }

    /// Uses a signed raw constant. Call after offset/inset/priority/labeled because
    /// reading `constraint` materializes SnapKit's lazy description. Do not mark in
    /// updateConstraints: its description is temporary rather than the installed one.
    @discardableResult
    public func ac_makeCollapsibleTo(_ constant: CGFloat) -> ConstraintMakerFinalizable {
        for nativeConstraint in constraint.layoutConstraints {
            ac_registerConstraint(nativeConstraint, constant)
        }
        return self
    }
}
