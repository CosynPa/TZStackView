//
//  TZStackViewAlignment.swift
//  TZStackView
//
//  Created by Tom van Zummeren on 15/06/15.
//  Copyright © 2015 Tom van Zummeren. All rights reserved.
//

import Foundation

/* Alignment—the layout transverse to the stacking axis.
*/
@objc public enum TZStackViewAlignment : Int {
    
    /* Align the leading and trailing edges of vertically stacked items
    or the top and bottom edges of horizontally stacked items tightly to the container.
    */
    case fill = 0
    
    /* Align the leading edges of vertically stacked items
    or the top edges of horizontally stacked items tightly to the relevant edge
    of the container
    */
    case leading = 1
    public static let top: TZStackViewAlignment = .leading
    
    // only valid for iOS 8 and later
    case firstBaseline = 2 // Valid for horizontal axis only
    
    /* Center the items in a vertical stack horizontally
    or the items in a horizontal stack vertically
    */
    case center = 3
    
    /* Align the trailing edges of vertically stacked items
    or the bottom edges of horizontally stacked items tightly to the relevant
    edge of the container
    */
    case trailing = 4
    public static let bottom: TZStackViewAlignment = .trailing
    case lastBaseline = 5 // Valid for horizontal axis only
}
