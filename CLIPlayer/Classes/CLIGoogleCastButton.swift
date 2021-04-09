//
//  CLIGoogleCastButton.swift
//  CLIPlayer
//
//  Created by EA on 12/04/2021.
//

import GoogleCast

class CLIGoogleCastButton: GCKUICastButton {

  required init(coder decoder: NSCoder) {
    super.init(coder: decoder)
    if let inactiveImage = UIImage(named: "chromecast_white", in: Bundle.cliPlayerBundle, compatibleWith: nil), let activeImage = UIImage(named: "chromecast_blue", in: Bundle.cliPlayerBundle, compatibleWith: nil), let loadingImage1 = UIImage(named: "chromecast_loading_s1", in: Bundle.cliPlayerBundle, compatibleWith: nil), let loadingImage2 = UIImage(named: "chromecast_loading_s2", in: Bundle.cliPlayerBundle, compatibleWith: nil) {
      setInactiveIcon(inactiveImage, activeIcon: activeImage, animationIcons: [loadingImage1, loadingImage2, activeImage])
    }

    imageEdgeInsets = .init(top: 6, left: 6, bottom: 6, right: 6)
    contentHorizontalAlignment = .fill;
    contentVerticalAlignment = .fill;
    imageView?.contentMode = .scaleAspectFit
  }
}
