//
//  UIStoryBoard+Extension.swift
//  CLIPlayer
//
//  Created by EA on 14/04/2021.
//

import Foundation

extension UIStoryboard {
  class var cliPlayerStoryboard: UIStoryboard {
    UIStoryboard(name: "CLIPlayer", bundle: Bundle.cliPlayerBundle)
  }
}
