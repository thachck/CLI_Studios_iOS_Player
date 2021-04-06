//
//  UIFont+Extension.swift
//  CLIPlayer
//
//  Created by Buu Bui on 06/04/2021.
//

extension UIFont {
  public class func fontWithName(_ name: String, ofSize fontSize: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
    let font: UIFont? = {
      switch (weight) {
      case .regular: return UIFont(name: "\(name)-Regular", size: fontSize)
      case .bold: return UIFont(name: "\(name)-Bold", size: fontSize)
      default: return nil
      }
    }()
    return font ?? .systemFont(ofSize: fontSize, weight: weight)
  }
}
