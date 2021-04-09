//
//  AppDelegate.swift
//  CLIPlayer
//
//  Created by buubui on 03/30/2021.
//  Copyright (c) 2021 buubui. All rights reserved.
//

import UIKit
import GoogleCast

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GCKLoggerDelegate {
  var window: UIWindow?
  let googleCastAppId = "27C3512B"
  let kDebugLoggingEnabled = true


  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    let options = GCKCastOptions(discoveryCriteria: GCKDiscoveryCriteria(applicationID: googleCastAppId))
    options.physicalVolumeButtonsWillControlDeviceVolume = true
    GCKCastContext.setSharedInstanceWith(options)
    GCKCastContext.sharedInstance().useDefaultExpandedMediaControls = false
    GCKLogger.sharedInstance().delegate = self
    return true
  }

  func logMessage(_ message: String,
                  at level: GCKLoggerLevel,
                  fromFunction function: String,
                  location: String) {
    if (kDebugLoggingEnabled) {
      print(function + " - " + message)
    }
  }
}
