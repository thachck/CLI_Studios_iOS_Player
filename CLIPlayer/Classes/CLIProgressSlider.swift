//
//  CLIProgressSlider.swift
//  CLIPlayer
//
//  Created by admin on 31/03/2021.
//

import UIKit


class CLIProgressSlider: UISlider {
  var gradientLayer: CAGradientLayer?
  var minTrackStartColor = UIColor(red: 4.0/256, green: 118.0/256, blue: 177.0/256, alpha: 1)
  var minTrackEndColor = UIColor(red: 32.0/256, green: 248.0/256, blue: 225.0/256, alpha: 1)
  var thumbColor = UIColor(red: 32.0/256, green: 248.0/256, blue: 225.0/256, alpha: 1)
  var normalThumbWidth = 15
  var highlightedThumbWidth = 23

  override func draw(_ rect: CGRect) {
    super.draw(rect)
    setThumbImage(UIImage.makeCircleImage(size: CGSize(width: normalThumbWidth, height: normalThumbWidth), backgroundColor: thumbColor), for: .normal)
    setThumbImage(UIImage.makeCircleImage(size: CGSize(width: highlightedThumbWidth, height: highlightedThumbWidth), backgroundColor: thumbColor), for: .highlighted)
    tintColor = thumbColor
    minimumTrackTintColor = .clear
  }

  override func layoutSublayers(of layer: CALayer) {
    super.layoutSublayers(of: layer)

    for subview in subviews {
      subview.alpha = 1
    }
    var rect = trackRect(forBounds: self.bounds)
    rect.size.width = max(rect.size.width * CGFloat(value), 1)
    reloadGradientLayer(frame: rect, colors: [minTrackStartColor.cgColor, minTrackEndColor.cgColor])
  }

  func reloadGradientLayer(frame: CGRect, colors: [CGColor]) {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    if gradientLayer == nil {
      let newLayer = CAGradientLayer()
      gradientLayer = newLayer
      newLayer.colors = colors
      layer.insertSublayer(newLayer, at: 0)
      newLayer.frame = frame
      newLayer.masksToBounds = false

      newLayer.startPoint = CGPoint(x:0.0, y:0.5)
      newLayer.endPoint = CGPoint(x:1.0, y:0.5)
    } else if let gradientLayer = gradientLayer {
      gradientLayer.frame = frame
      gradientLayer.cornerRadius = frame.height / 2
    }
    CATransaction.commit()
  }

  override var alpha: CGFloat {
    get {
      super.alpha
    }
    set {
      print("😎set alpha", newValue)
      super.alpha = newValue
    }
  }
}
