//
//  CLIPlayerConfig.swift
//  CLIPlayer
//
//  Created by Buu Bui on 06/04/2021.
//

public struct CLIPlayerConfig {
  public init(classTitleFont: UIFont = .fontWithName("Oxygen", ofSize: 14, weight: .bold), classDescriptionFont: UIFont = .fontWithName("Oxygen", ofSize: 12), endClassButtonFont: UIFont = .fontWithName("WorkSans", ofSize: 17, weight: .bold), currentTimeFont: UIFont = .fontWithName("Oxygen", ofSize: 16), seekOverlayFont: UIFont = .fontWithName("Oxygen", ofSize: 16), modalTitleFont: UIFont = .fontWithName("Oxygen", ofSize: 20), modalItemFont: UIFont = .fontWithName("Oxygen", ofSize: 16)) {
    self.classTitleFont = classTitleFont
    self.classDescriptionFont = classDescriptionFont
    self.endClassButtonFont = endClassButtonFont
    self.currentTimeFont = currentTimeFont
    self.seekOverlayFont = seekOverlayFont
    self.modalTitleFont = modalTitleFont
    self.modalItemFont = modalItemFont
  }
  
  
  var classTitleFont: UIFont = .fontWithName("Oxygen", ofSize: 14, weight: .bold)
  var classDescriptionFont: UIFont = .fontWithName("Oxygen", ofSize: 12)
  var endClassButtonFont: UIFont = .fontWithName("WorkSans", ofSize: 17, weight: .bold)
  var currentTimeFont: UIFont = .fontWithName("Oxygen", ofSize: 16)
  var seekOverlayFont: UIFont = .fontWithName("Oxygen", ofSize: 16)
  var modalTitleFont: UIFont = .fontWithName("Oxygen", ofSize: 20)
  var modalItemFont: UIFont = .fontWithName("Oxygen", ofSize: 16)
  
  var selectorModalConfig: SelectorModalConfig {
    return SelectorModalConfig(titleFont: modalTitleFont, itemFont: modalItemFont)
  }
}
