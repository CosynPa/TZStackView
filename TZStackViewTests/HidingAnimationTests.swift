//
//  HidingAnimationTests.swift
//  TZStackView
//
//  Created by CosynPa on 3/6/16.
//  Copyright © 2016 Tom van Zummeren. All rights reserved.
//

import Foundation
import UIKit
import XCTest
import TZStackView

class HidingAnimationTests: TZStackViewTestCase {
    var uiTestView: UIView!
    var tzTestView: UIView!
    
    func createTestViews() -> [UIView] {
        var views = [UIView]()
        for i in 0 ..< 5 {
            views.append(TestView(index: i, size: CGSize(width: 100 * (i + 1), height: 100 * (i + 1))))
        }
        return views
    }
    
    override func setUp() {
        super.setUp()
        
        recreateStackViews(createTestViews)
        
        uiTestView = uiStackView.arrangedSubviews.last!
        tzTestView = tzStackView.arrangedSubviews.last!
    }
    
    // If you are not animating the hidden property, the hidden property should be set immediately
    func testNonAnimatingHidden() {
        let expectation = self.expectation(description: "delay")
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            self.uiTestView.isHidden = true
            self.tzTestView.isHidden = true
            
            XCTAssert(self.uiTestView.isHidden)
            XCTAssert(self.tzTestView.isHidden)
            XCTAssert(self.uiTestView.layer.isHidden)
            XCTAssert(self.tzTestView.layer.isHidden)
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.2) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 100, handler: nil)
    }
    
    // If you are not animating the hidden property, the hidden property should be set immediately
    func testNonAnimatingHiddenWithOther() {
        let expectation = self.expectation(description: "delay")
        
        uiTestView.backgroundColor = UIColor.clear
        tzTestView.backgroundColor = UIColor.clear
        UIView.animate(withDuration: 2) {
            self.uiTestView.backgroundColor = UIColor.green
            self.tzTestView.backgroundColor = UIColor.green
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            self.uiTestView.isHidden = true
            self.tzTestView.isHidden = true
            
            XCTAssert(self.uiTestView.isHidden)
            XCTAssert(self.tzTestView.isHidden)
            XCTAssert(self.uiTestView.layer.isHidden)
            XCTAssert(self.tzTestView.layer.isHidden)
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.2) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 100, handler: nil)
    }
    
    func animationHiddenWithDelay(_ delay: TimeInterval) {
        let expectation = self.expectation(description: "delay")
        
        let duration = 1.0
        
        UIView.animate(withDuration: duration, delay: delay, options: [],
            animations: { () -> Void in
                self.uiTestView.isHidden = true
                self.tzTestView.isHidden = true
                
                // Note uiTestView.hidden == true, tzTestView.hidden == false
                
                // The presentation should not be hidden.
                XCTAssert(!self.uiTestView.layer.isHidden)
                XCTAssert(!self.tzTestView.layer.isHidden)
                
            }, completion: { _ in
                XCTAssert(self.uiTestView.isHidden)
                XCTAssert(self.tzTestView.isHidden)
                XCTAssert(self.uiTestView.layer.isHidden)
                XCTAssert(self.tzTestView.layer.isHidden)
        })
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration + delay + 0.2) {
            XCTAssert(self.uiTestView.isHidden)
            XCTAssert(self.tzTestView.isHidden)
            XCTAssert(self.uiTestView.layer.isHidden)
            XCTAssert(self.tzTestView.layer.isHidden)
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration + delay + 0.4) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 100, handler: nil)
    }
    
    func testAnimatingHidden() {
        animationHiddenWithDelay(0)
    }
    
    func testAnimatingHiddenWithDelay() {
        animationHiddenWithDelay(1)
    }
    
    func testAnimatingHiddenWithOther() {
        let expectation = self.expectation(description: "delay")
        
        UIView.animate(withDuration: 1) {
            self.uiTestView.isHidden = true
            self.tzTestView.isHidden = true
        }
        
        uiTestView.backgroundColor = UIColor.clear
        tzTestView.backgroundColor = UIColor.clear
        UIView.animate(withDuration: 2) {
            self.uiTestView.backgroundColor = UIColor.green
            self.tzTestView.backgroundColor = UIColor.green
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.2) {
            // The view should be hidden after the hiding animation completes even if there are still other animations
            XCTAssert(self.uiTestView.isHidden)
            XCTAssert(self.tzTestView.isHidden)
            XCTAssert(self.uiTestView.layer.isHidden)
            XCTAssert(self.tzTestView.layer.isHidden)
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.2) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 100, handler: nil)
    }
    
    // The completion callback of an animation should be called
    func testHidingAnimationCallback() {
        let expectation = self.expectation(description: "delay")
        
        var uiCompletionCalled = false
        var tzCompletionCalled = false
        
        UIView.animate(withDuration: 1,
            animations: {
                self.uiTestView.isHidden = true
            }, completion: { _ in
                uiCompletionCalled = true
        })
        
        UIView.animate(withDuration: 1,
            animations: {
                self.tzTestView.isHidden = true
            }, completion: { _ in
                tzCompletionCalled = true
        })
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.2) {
            XCTAssert(uiCompletionCalled)
            XCTAssert(tzCompletionCalled)
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.4) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 100, handler: nil)
    }
    
    // The completion callback of an animation should be called when the animation is canceled
    func testHidingAnimationCallbackCancel() {
        let expectation = self.expectation(description: "delay")
        
        var uiCompletionCalled = false
        var tzCompletionCalled = false
        
        UIView.animate(withDuration: 1,
            animations: {
                self.uiTestView.isHidden = true
            }, completion: { finished in
                uiCompletionCalled = true
                XCTAssert(!finished)
        })
        
        UIView.animate(withDuration: 1,
            animations: {
                self.tzTestView.isHidden = true
            }, completion: { finished in
                tzCompletionCalled = true
                XCTAssert(!finished)
        })
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            // This will cancel the animation
            self.uiStackView.removeFromSuperview()
            self.tzStackView.removeFromSuperview()
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.7) {
            XCTAssert(uiCompletionCalled)
            XCTAssert(tzCompletionCalled)
            XCTAssert(self.uiTestView.isHidden)
            XCTAssert(self.tzTestView.isHidden)
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.4) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 100, handler: nil)
    }
    
    // When set the hidden property in the middle of an animation, the hidden property should be updated eventually
    func hidingAnimationSetAgainFirstHidden(_ firstHidden: Bool, withAnimation: Bool) {
        let expectation = self.expectation(description: "delay")
        
        uiTestView.isHidden = firstHidden
        tzTestView.isHidden = firstHidden
        
        UIView.animate(withDuration: 2) {
            self.uiTestView.isHidden = !firstHidden
            self.tzTestView.isHidden = !firstHidden
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            if !withAnimation {
                self.uiTestView.isHidden = firstHidden
                self.tzTestView.isHidden = firstHidden
            } else {
                UIView.animate(withDuration: 2) {
                    self.uiTestView.isHidden = firstHidden
                    self.tzTestView.isHidden = firstHidden
                    
                    // Animating, the presentation is not hidden
                    XCTAssert(!self.uiTestView.layer.isHidden)
                    XCTAssert(!self.tzTestView.layer.isHidden)
                }
            }
            
            // Note, here we don't expect the hidden property to be the right value even when without animation,
        }
        
        let endTime = !withAnimation ? 2.2 : 3.2
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + endTime) {
            XCTAssert(self.uiTestView.isHidden == firstHidden)
            XCTAssert(self.tzTestView.isHidden == firstHidden)
        }
                
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + endTime + 0.2) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 100, handler: nil)
    }
    
    func testHidingAnimationSetAgainFirstNotHidden() {
        hidingAnimationSetAgainFirstHidden(false, withAnimation: false)
    }
    
    func testHidingAnimationSetAgainFirstHidden() {
        hidingAnimationSetAgainFirstHidden(true, withAnimation: false)
    }
    
    func testHidingAnimationSetAgainFirstNotHiddenWithAnimation() {
        hidingAnimationSetAgainFirstHidden(false, withAnimation: true)
    }
    
    func testHidingAnimationSetAgainFirstHiddenWithAnimation() {
        hidingAnimationSetAgainFirstHidden(true, withAnimation: true)
    }
}
