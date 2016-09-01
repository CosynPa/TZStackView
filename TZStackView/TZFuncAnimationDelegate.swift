//
//  TZAnimationDelegate.swift
//  TZStackView
//
//  Created by CosynPa on 3/5/16.
//  Copyright © 2016 Tom van Zummeren. All rights reserved.
//

import Foundation
import QuartzCore

class TZFuncAnimationDelegate: NSObject, CAAnimationDelegate {
    private var completionFunc: ((CAAnimation, Bool) -> ())?
    
    init(completion: @escaping (CAAnimation, Bool) -> ()) {
        completionFunc = completion
    }
    
    @objc func animationDidStart(_ anim: CAAnimation) {

    }
    
    @objc func animationDidStop(_ anim: CAAnimation, finished: Bool) {
        completionFunc?(anim, finished)
    }
    
    func cancel(_ anim: CAAnimation) {
        completionFunc?(anim, false)
        completionFunc = nil
    }
}
