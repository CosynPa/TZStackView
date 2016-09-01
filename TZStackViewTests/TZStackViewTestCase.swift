//
//  StackViewTest.swift
//  TZStackView
//
//  Created by Tom van Zummeren on 12/06/15.
//  Copyright © 2015 Tom van Zummeren. All rights reserved.
//

import Foundation
import XCTest

@testable import TZStackView

func delay(_ delay:Double, closure:@escaping ()->()) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + delay, execute: closure)
}

class TZStackViewTestCase: XCTestCase {
    
    var uiStackView: UIStackView!
    var tzStackView: TZStackView!

    func recreateStackViews(_ createSubviews: () -> [UIView]) {
        // don't use old views otherwise some old spacer views and constraints are left
        // don't remove old view to avoid layout engine internal error
        
        // Create stack views with same views
        uiStackView = UIStackView(arrangedSubviews: createSubviews())
        uiStackView.translatesAutoresizingMaskIntoConstraints = false
        tzStackView = TZStackView(arrangedSubviews: createSubviews())
        tzStackView.translatesAutoresizingMaskIntoConstraints = false
        
        let window = UIApplication.shared.windows[0]
        window.addSubview(uiStackView)
        window.addSubview(tzStackView)
    }
    
    func logAllConstraints() {
        print("================= UISTACKVIEW (\(uiStackView.constraints.count)) =================")
        print("subviews: \(uiStackView.subviews)")
        printConstraints(uiStackView.constraints)
        print("")
        for subview in uiStackView.arrangedSubviews {
            print("\(subview):")
            printConstraints(nonContentSizeLayoutConstraints(subview))
        }

        print("================= TZSTACKVIEW (\(tzStackView.constraints.count)) =================")
        print("subviews: \(tzStackView.subviews)")
        printConstraints(tzStackView.constraints)
        print("")
        for subview in tzStackView.arrangedSubviews {
            print("\(subview):")
            printConstraints(nonContentSizeLayoutConstraints(subview))
        }
    }
    
    func verifyConstraints(log: Bool = false) {
        // Force constraints to be created
        uiStackView.setNeedsUpdateConstraints()
        uiStackView.updateConstraintsIfNeeded()
        
        tzStackView.setNeedsUpdateConstraints()
        tzStackView.updateConstraintsIfNeeded()

        if log {
            logAllConstraints()
        }
        // Assert same constraints are created
        assertSameConstraints(nonMarginsLayoutConstraints(uiStackView), nonMarginsLayoutConstraints(tzStackView))
        
        for (index, uiArrangedSubview) in uiStackView.arrangedSubviews.enumerated() {
            let tzArrangedSubview = tzStackView.arrangedSubviews[index]
            
            let uiConstraints = nonContentSizeLayoutConstraints(uiArrangedSubview)
            let tzConstraints = nonContentSizeLayoutConstraints(tzArrangedSubview)
            
            // Assert same constraints are created
            assertSameConstraints(uiConstraints, tzConstraints)
        }
    }
    
    fileprivate func nonContentSizeLayoutConstraints(_ view: UIView) -> [NSLayoutConstraint] {
        return view.constraints.filter({ "\(type(of: $0))" != "NSContentSizeLayoutConstraint" })
    }
    
    fileprivate func nonMarginsLayoutConstraints(_ view: UIView) -> [NSLayoutConstraint] {
        return view.constraints.filter { aConstraint in
            if let identifier = aConstraint.identifier {
                return !identifier.hasSuffix("Margin-guide-constraint")
            } else {
                return true
            }
        }
    }
    
    func assertSameConstraints(_ uiConstraints: [NSLayoutConstraint], _ tzConstraints: [NSLayoutConstraint]) {
        func getGuides(_ constraints: [NSLayoutConstraint]) -> [NSObject] {
            var result = Set<NSObject>()
            
            for aConstraint in constraints {
                let firstItem = aConstraint.firstItem
                if firstItem is _TZSpacerView || firstItem is UILayoutGuide {
                    result.insert(firstItem as! NSObject)
                }
                
                if let secondItem = aConstraint.secondItem , secondItem is _TZSpacerView || secondItem is UILayoutGuide {
                    result.insert(secondItem as! NSObject)
                }
            }
            
            return Array(result)
        }
        
        let uiGuides = getGuides(uiConstraints)
        let tzGuides = getGuides(tzConstraints)
        
        XCTAssertEqual(uiGuides.count, tzGuides.count, "Number of layout guides")

        let uiGrouped = Array(uiConstraints.enumerated()).groupBy{ (index, constraint) in constraint.identifier ?? "" }
        let tzGrouped = Array(tzConstraints.enumerated()).groupBy{ (index, constraint) in constraint.identifier ?? "" }
        
        identifierLoop: for (identifier, uiGroup) in uiGrouped {
            let tzIdentifier = identifier.hasPrefix("UI") ? "TZ" + String(identifier.characters.dropFirst("UI".characters.count)) : identifier
            if let tzGroup = tzGrouped[tzIdentifier] {
                XCTAssertEqual(uiGroup.count, tzGroup.count, "Number of constraints with identifier \(identifier)")
                guard uiGroup.count == tzGroup.count else {
                    continue
                }
               
                var tzGroupLeft = tzGroup
                for (index, uiConstraint) in uiGroup { // note, the index is the index of uiConstraints, not uiGroup
                    let tzIndex = tzGroupLeft.index { (_, tzConstraint) in
                        return isSameConstraint(uiConstraint, tzConstraint) || isSameConstraintFlipped(uiConstraint, tzConstraint)
                    }
                    
                    if let tzIndex = tzIndex {
                        tzGroupLeft.remove(at: tzIndex)
                    } else {
                        XCTAssert(false, "Constraints at index \(index) do not match\n== EXPECTED ==\n\(uiConstraint.readableString())\n\n== POSSIBLE ACTUAL ==\n\(tzConstraints[index].readableString())\n\n")
                        continue identifierLoop
                    }
                }
            } else {
                XCTAssert(false, "EXPECTED constraints with identifier \(identifier) have no match")
            }
        }
        
        for (identifier, _) in tzGrouped {
            let uiIdentifier = identifier.hasPrefix("TZ") ? "UI" + String(identifier.characters.dropFirst("TZ".characters.count)) : identifier
            if let _ = uiGrouped[uiIdentifier] {
                // nothing to check unless UI constraints have two same constraints
            } else {
                XCTAssert(false, "UNEXPECTED extra constraints with identifier \(identifier)")
            }
        }
    }
    
    fileprivate func isSameConstraint(_ layoutConstraint1: NSLayoutConstraint, _ layoutConstraint2: NSLayoutConstraint) -> Bool {
        if !viewsEqual(layoutConstraint1.firstItem, layoutConstraint2.firstItem) {
            return false
        }
        if !viewsEqual(layoutConstraint1.secondItem, layoutConstraint2.secondItem) {
            return false
        }
        if layoutConstraint1.firstAttribute != layoutConstraint2.firstAttribute {
            return false
        }
        if layoutConstraint1.secondAttribute != layoutConstraint2.secondAttribute {
            return false
        }
        if layoutConstraint1.relation != layoutConstraint2.relation {
            return false
        }
        if fabs(layoutConstraint1.multiplier - layoutConstraint2.multiplier) > 0.001 {
            return false
        }
        if fabs(layoutConstraint1.constant - layoutConstraint2.constant) > 0.001 {
            return false
        }
        if fabs(layoutConstraint1.priority - layoutConstraint2.priority) > 0.001 {
            return false
        }
        if !isSameIdentifier(layoutConstraint1.identifier, layoutConstraint2.identifier) {
            return false
        }
        return true
    }
    
    fileprivate func isSameConstraintFlipped(_ layoutConstraint1: NSLayoutConstraint, _ layoutConstraint2: NSLayoutConstraint) -> Bool {
        func flipRelation(_ relation: NSLayoutRelation) -> NSLayoutRelation {
            switch relation {
            case .equal:
                return .equal
            case .greaterThanOrEqual:
                return .lessThanOrEqual
            case .lessThanOrEqual:
                return .greaterThanOrEqual
            }
        }

        func flipConstraint(_ constraint: NSLayoutConstraint) -> NSLayoutConstraint {
            guard constraint.multiplier != 0 else {
                return constraint
            }
            
            guard let secondItem = constraint.secondItem else {
                return constraint
            }
            
            let flipped = NSLayoutConstraint(item: secondItem,
                attribute: constraint.secondAttribute,
                relatedBy: constraint.multiplier > 0 ? flipRelation(constraint.relation) : constraint.relation,
                toItem: constraint.firstItem,
                attribute: constraint.firstAttribute,
                multiplier: 1 / constraint.multiplier,
                constant: -constraint.constant / constraint.multiplier)
            
            flipped.identifier = constraint.identifier
            flipped.priority = constraint.priority
            
            return flipped
        }
        
        return isSameConstraint(layoutConstraint1, flipConstraint(layoutConstraint2))
    }

    fileprivate func printConstraints(_ constraints: [NSLayoutConstraint]) {
        for constraint in constraints {
            print(constraint.readableString())
        }
    }
    
    fileprivate func viewsEqual(_ object1: AnyObject?, _ object2: AnyObject?) -> Bool {
        if object1 == nil && object2 == nil {
            return true
        }
        if let view1 = object1 as? TestView, let view2 = object2 as? TestView , view1 == view2 {
            return true
        }
        if let label1 = object1 as? TestLabel, let label2 = object2 as? TestLabel , label1 == label2 {
            return true
        }
        if object1 is UIStackView && object2 is TZStackView {
            return true
        }
        if object1 is TZStackView && object2 is UIStackView {
            return true
        }
        // Wish I could assert more accurately than this
        if let object1 = object1 as? UILayoutGuide, let object2 = object2 as? _TZSpacerView
            , isSameIdentifier(object1.identifier, object2.identifier) {
            return true
        }
        // Wish I could assert more accurately than this
        if let object1 = object1 as? _TZSpacerView, let object2 = object2 as? UILayoutGuide
            , isSameIdentifier(object1.identifier, object2.identifier) {
            return true
        }
        return false
    }
    
    fileprivate func isSameIdentifier(_ identifier1: String, _ identifier2: String) -> Bool {
        func hasPrefix(_ str: String) -> Bool {
            return str.hasPrefix("UI") || str.hasPrefix("TZ")
        }
        
        func dropPrefix(_ str: String) -> String {
            return String(str.characters.dropFirst("UI".characters.count))
        }
        
        return identifier1 == identifier2 || (hasPrefix(identifier1) && hasPrefix(identifier2) && dropPrefix(identifier1) == dropPrefix(identifier2))
    }
    
    fileprivate func isSameIdentifier(_ identifier1: String?, _ identifier2: String?) -> Bool {
        switch (identifier1, identifier2) {
        case (nil, nil):
            return true
        case (.some, nil), (nil, .some):
            return false
        case (.some(let id1), .some(let id2)):
            return isSameIdentifier(id1, id2)
        }
    }

    func assertSameOrder(_ uiTestViews: [UIView], _ tzTestViews: [UIView]) {
        for (index, uiView) in uiTestViews.enumerated() {
            let tzView = tzTestViews[index]

            let result: Bool
            if let uiTestView = uiView as? TestView, let tzTestView = tzView as? TestView {
                result = uiTestView == tzTestView
            } else if let uiTestLabel = uiView as? TestLabel, let tzTestLabel = tzView as? TestLabel {
                result = uiTestLabel == tzTestLabel
            } else {
                result = true
            }

            XCTAssertTrue(result, "Views at index \(index) do not match\n== EXPECTED ==\n\(uiView.description)\n\n== ACTUAL ==\n\(tzView.description)\n\n")
        }
    }

    func verifyArrangedSubviewConsistency() {
        XCTAssertEqual(uiStackView.arrangedSubviews.count, tzStackView.arrangedSubviews.count, "Number of arranged subviews")

        let uiArrangedSubviews = uiStackView.arrangedSubviews
        let tzArrangedSubviews = tzStackView.arrangedSubviews

        assertSameOrder(uiArrangedSubviews, tzArrangedSubviews)

        for tzTestView in tzArrangedSubviews {
            let result = tzStackView.subviews.contains(tzTestView)

            XCTAssertTrue(result, "\(tzTestView.description) is in arranged subviews but is not actually a subview")
        }
    }
}
