//
//  ViewController.swift
//  CLIPlayer
//
//  Created by buubui on 03/30/2021.
//  Copyright (c) 2021 buubui. All rights reserved.
//

import UIKit
import CLIPlayer

class ViewController: UIViewController {

  @IBAction func playHLSTapped(_ sender: Any) {
    let videoUrl = URL(string: "https://d2t9el598942m2.cloudfront.net/MovementSpeaks_2221_Brandon_Oneal_BegJazz/MovementSpeaks_2221_Brandon_Oneal_BegJazz.m3u8")
    let player = CLIPlayerController()
    player.url = videoUrl
    present(player, animated: true)
  }

  @IBAction func playVimeoTapped(_ sender: Any) {
    let player = CLIPlayerController()
    player.vimeoCode = "401102121"
    present(player, animated: true)
  }
}
