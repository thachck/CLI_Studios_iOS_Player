//
//  UiView+Extensions.swift
//  BPlayer
//
//  Created by admin on 24/03/2021.
//

import UIKit


extension UIView {

    /// Flip view horizontally.
    func flipX() {
        transform = CGAffineTransform(scaleX: -transform.a, y: transform.d)
    }

    /// Flip view vertically.
    func flipY() {
        transform = CGAffineTransform(scaleX: transform.a, y: -transform.d)
    }
 }
