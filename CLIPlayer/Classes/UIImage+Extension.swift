//
//  UIImage+Extension.swift
//  CLIPlayer
//
//  Created by admin on 31/03/2021.
//

import Foundation

extension UIImage {
  public class var cliPlayerMuted: UIImage? {
    UIImage(named: "plyr-muted", in: Bundle.cliPlayerBundle, compatibleWith: nil)
  }

  public class var cliPlayerVolume: UIImage? {
    UIImage(named: "plyr-volume", in: Bundle.cliPlayerBundle, compatibleWith: nil)
  }

  public class var cliPlayerEnterFullScreen: UIImage? {
    UIImage(named: "plyr-enter-fullscreen", in: Bundle.cliPlayerBundle, compatibleWith: nil)
  }

  public class var cliPlayerExitFullScreen: UIImage? {
    UIImage(named: "plyr-exit-fullscreen", in: Bundle.cliPlayerBundle, compatibleWith: nil)
  }

  public class var cliPlayerPause: UIImage? {
    UIImage(named: "plyr-pause", in: Bundle.cliPlayerBundle, compatibleWith: nil)
  }

  public class var cliPlayerPlay: UIImage? {
    UIImage(named: "plyr-play", in: Bundle.cliPlayerBundle, compatibleWith: nil)
  }

  public class var cliPlayerChromeCast: UIImage? {
    UIImage(named: "chromecast_white", in: Bundle.cliPlayerBundle, compatibleWith: nil)
  }

  public class var cliPlayerChromeCastActive: UIImage? {
    UIImage(named: "chromecast_blue", in: Bundle.cliPlayerBundle, compatibleWith: nil)
  }

  public class var cliPlayerChromeCastLoading1: UIImage? {
    UIImage(named: "chromecast_loading_s1", in: Bundle.cliPlayerBundle, compatibleWith: nil)
  }

  public class var cliPlayerChromeCastLoading2: UIImage? {
    UIImage(named: "chromecast_loading_s2", in: Bundle.cliPlayerBundle, compatibleWith: nil)
  }

  public class var cliPlayerAirPlay: UIImage? {
    UIImage(named: "airplay_white", in: Bundle.cliPlayerBundle, compatibleWith: nil)
  }

  public class func cliPlayerSpeed(_ speed: Float) -> UIImage? {
    UIImage(named: String(format: "plyr-speed-%.1fx", speed), in: Bundle.cliPlayerBundle, compatibleWith: nil)
  }

  public class func makeCircleImage(size: CGSize, backgroundColor: UIColor) -> UIImage? {
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

