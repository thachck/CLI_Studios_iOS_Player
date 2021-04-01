//
//  UIImage+Extension.swift
//  CLIPlayer
//
//  Created by admin on 31/03/2021.
//

import Foundation

extension UIImage {
  class func makeCircleImage(size: CGSize, backgroundColor: UIColor) -> UIImage? {
      UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
      let context = UIGraphicsGetCurrentContext()
      context?.setFillColor(backgroundColor.cgColor)
      context?.setStrokeColor(UIColor.clear.cgColor)
      let bounds = CGRect(origin: .zero, size: size)
      context?.addEllipse(in: bounds)
      context?.drawPath(using: .fill)
      let image = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()
      return image
  }
}

