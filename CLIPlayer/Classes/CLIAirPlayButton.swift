//
//  CLIAirPlayButton.swift
//  CLIPlayer
//
//  Created by EA on 08/04/2021.
//

import UIKit
import MediaPlayer

class CLIAirPlayButton: CLIControlButton {
  private var _volumeView: MPVolumeView!
  var isWirelessRouteActive: Bool { _volumeView.isWirelessRouteActive }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    _volumeView = MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 1, height: 1))
    _volumeView.showsVolumeSlider = false
    addSubview(_volumeView)
    clipsToBounds = true
    if let airplayButton = _volumeView.airplayButton {
      airplayButton.addObserver(self, forKeyPath: "alpha", options: .new, context: nil)
      airplayButton.addObserver(self, forKeyPath: "selected", options: .new, context: nil)
    }
  }
  
  func showAirPlayModal() {
    _volumeView.airplayButton?.sendActions(for: .touchUpInside)
  }
  
  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    if let button = object as? UIButton {
      switch keyPath {
        case "alpha":
          self.isHidden = button.alpha == 0
        case "selected":
          isSelected = button.isSelected
        default:
          return
      }
    }
  }
  
  deinit {
    _volumeView.airplayButton?.removeObserver(self, forKeyPath: "alpha")
    _volumeView.airplayButton?.removeObserver(self, forKeyPath: "selected")
  }
}
