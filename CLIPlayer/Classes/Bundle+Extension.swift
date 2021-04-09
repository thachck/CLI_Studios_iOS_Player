//
//  Bundle+Extension.swift
//  CLIPlayer
//
//  Created by EA on 09/04/2021.
//

import Foundation

extension Bundle {
  public class var cliPlayerBundle: Bundle {
    let bundlePath = Bundle(for: CLIPlayerController.self).path(forResource: "CLIPlayer", ofType: "bundle")!
    return Bundle(path: bundlePath)!
  }
}
