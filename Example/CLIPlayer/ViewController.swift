//
//  ViewController.swift
//  CLIPlayer
//
//  Created by buubui on 03/30/2021.
//  Copyright (c) 2021 buubui. All rights reserved.
//

import UIKit
import CLIPlayer
import GoogleCast

class ViewController: UIViewController {
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if let delegate = UIApplication.shared.delegate as? AppDelegate {
      delegate.orientationLock = .landscapeRight
      UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
    }
  }

  @IBAction func playHLSTapped(_ sender: Any) {
    let videoUrl = URL(string: "https://d2t9el598942m2.cloudfront.net/MovementSpeaks_2221_Brandon_Oneal_BegJazz/MovementSpeaks_2221_Brandon_Oneal_BegJazz.m3u8")
    let player = CLIPlayerController.instance()
    player.url = videoUrl
    let title = "Movement Speaks: \"Do I Do\""
    let thumbnail = "https://d22g5lrmqfbqur.cloudfront.net/videos/thumbnails/000/003/617/w1000/Brandon.jpeg?1614813096"
    player.setClassTitle(title)
    player.setClassDescription(artistName: "Brandon O'Neal", duration: "45:16", genre: "Jazz", level: "Beginner")
    let metadata = GCKMediaMetadata()
    metadata.setString(title, forKey: kGCKMetadataKeyTitle)
    let image = GCKImage(url: URL(string: thumbnail)!, width: 405, height: 720)
    metadata.addImage(image)
    metadata.setString(thumbnail, forKey: "cli_cast_thumbnail")
    player.googleCastMetadata = metadata
    present(player, animated: true)
  }

  @IBAction func playVimeoTapped(_ sender: Any) {
    let player = CLIPlayerController.instance()
    player.vimeoCode = "401102121"
    let title = "Too Good at Goodbyes"
    let thumbnail = "https://d22g5lrmqfbqur.cloudfront.net/videos/thumbnails/000/001/809/w1000/_Mark_Meismer_-_Too_Good_At_Goodbyes_16x9.jpg?1595325042"
    player.setClassTitle(title)
    player.setClassDescription(artistName: "Mark Meismer", duration: "1:25:05", genre: "All Styles", level: "All Levels")
    let metadata = GCKMediaMetadata()
    metadata.setString(title, forKey: kGCKMetadataKeyTitle)
    let image = GCKImage(url: URL(string: thumbnail)!, width: 405, height: 720)
    metadata.addImage(image)
    metadata.setString(thumbnail, forKey: "cli_cast_thumbnail")
    player.googleCastMetadata = metadata
    present(player, animated: true)
  }
}
