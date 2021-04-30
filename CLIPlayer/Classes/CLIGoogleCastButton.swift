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
    if let inactiveImage = UIImage.cliPlayerChromeCast, let activeImage = UIImage.cliPlayerChromeCastActive, let loadingImage1 = UIImage.cliPlayerChromeCastLoading1, let loadingImage2 = UIImage.cliPlayerChromeCastLoading2 {
      setInactiveIcon(inactiveImage, activeIcon: activeImage, animationIcons: [loadingImage1, loadingImage2, activeImage])
    }

    imageEdgeInsets = .init(top: 6, left: 6, bottom: 6, right: 6)
    contentHorizontalAlignment = .fill;
    contentVerticalAlignment = .fill;
    imageView?.contentMode = .scaleAspectFit
    _isHidden = isHidden
    CLIGoogleCastButton.applyCastStyle()
  }

  class func applyCastStyle() {
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

  var forceHidden: Bool? {
    didSet {
      if let forceHidden = forceHidden {
        super.isHidden = forceHidden
      } else {
        super.isHidden = _isHidden
      }
    }
  }

  var _isHidden: Bool = false

  override var isHidden: Bool {
    get {
      super.isHidden
    }
    set {
      _isHidden = newValue
      if forceHidden == nil {
        super.isHidden = newValue
      }
    }
  }
}
