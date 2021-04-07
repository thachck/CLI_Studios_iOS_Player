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
    let player = CLIPlayerController.instance()
    player.url = videoUrl
    player.setClassTitle("Movement Speaks: \"Do I Do\"")
    player.setClassDescription(artistName: "Brandon O'Neal", duration: "45:16", genre: "Jazz", level: "Beginner")
    present(player, animated: true)
  }

  @IBAction func playVimeoTapped(_ sender: Any) {
    let player = CLIPlayerController.instance()
    player.vimeoCode = "401102121"
    player.setClassTitle("Too Good at Goodbyes")
    player.setClassDescription(artistName: "Mark Meismer", duration: "1:25:05", genre: "All Styles", level: "All Levels")
    present(player, animated: true)
  }
}
