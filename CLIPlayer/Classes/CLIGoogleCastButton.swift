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
    applyCastStyle()
  }

  func applyCastStyle() {
    let castStyle = GCKUIStyle.sharedInstance()

    castStyle.castViews.backgroundColor = .black
    castStyle.castViews.headingTextColor = .white
    castStyle.castViews.bodyTextColor = .white
    castStyle.castViews.iconTintColor = .white
    castStyle.castViews.captionTextColor = .white
    castStyle.castViews.sliderProgressColor = .main

    castStyle.castViews.deviceControl.connectionController.backgroundColor = .black
    castStyle.castViews.deviceControl.connectionController.navigation.headingTextColor = .white
    castStyle.castViews.deviceControl.connectionController.navigation.bodyTextColor = .white
    castStyle.castViews.deviceControl.connectionController.navigation.captionTextColor = .white
    castStyle.castViews.deviceControl.connectionController.navigation.iconTintColor = .white
    castStyle.castViews.deviceControl.connectionController.sliderProgressColor = .main
    castStyle.castViews.deviceControl.connectionController.sliderSecondaryProgressColor = .main

    castStyle.castViews.deviceControl.backgroundColor = .blue
    castStyle.castViews.deviceControl.bodyTextColor = .white
    castStyle.castViews.deviceControl.headingTextColor = .white
    castStyle.castViews.deviceControl.captionTextColor = .white
    castStyle.castViews.deviceControl.iconTintColor = .white
    castStyle.castViews.deviceControl.buttonTextColor = .white
    castStyle.castViews.deviceControl.buttonTextColor = .white

    castStyle.castViews.deviceControl.deviceChooser.backgroundColor = .black
    castStyle.castViews.deviceControl.deviceChooser.iconTintColor = .white
    castStyle.castViews.deviceControl.deviceChooser.headingTextColor = .white
    castStyle.castViews.deviceControl.deviceChooser.captionTextColor = .white
    castStyle.castViews.deviceControl.deviceChooser.bodyTextColor = .white
    castStyle.castViews.deviceControl.deviceChooser.buttonTextColor = .white

    // Refresh all currently visible views with the assigned styles.
    castStyle.apply()
  }
}
