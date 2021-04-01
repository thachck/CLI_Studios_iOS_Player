//
//  CLIControlButton.swift
//  CLIPlayer
//
//  Created by admin on 01/04/2021.
//

import UIKit

class CLIControlButton: UIButton {

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    contentHorizontalAlignment = .fill;
    contentVerticalAlignment = .fill;
    imageView?.contentMode = .scaleAspectFit
    imageEdgeInsets = .init(top: 6, left: 6, bottom: 6, right: 6)
  }
}
