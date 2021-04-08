//
//  MPVolumeView+Extension.swift
//  CLIPlayer
//
//  Created by EA on 08/04/2021.
//

import MediaPlayer

extension MPVolumeView {
  var airplayButton: UIButton? {
    for subView in subviews {
      if let button = subView as? UIButton {
        return button
      }
    }
    return nil
  }
}
