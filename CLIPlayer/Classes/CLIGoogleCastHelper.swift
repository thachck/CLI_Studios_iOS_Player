//
//  GoogleCastHelper.swift
//  CLIStudios
//
//  Created by East Agile on 1/31/18.
//  Copyright © 2018 CLI Studios. All rights reserved.
//

import GoogleCast

let kPrefPreloadTime = "preload_time_sec"


public class CLIGoogleCastHelper: NSObject {

  static let shared = CLIGoogleCastHelper()

  var remoteMediaClient: GCKRemoteMediaClient? {
    GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient
  }

  var mediaStatus: GCKMediaStatus? {
    remoteMediaClient?.mediaStatus
  }

  var mediaPlayerState: GCKMediaPlayerState? {
    mediaStatus?.playerState
  }

  var isPlaying: Bool {
    mediaPlayerState == GCKMediaPlayerState.playing
  }

  /**
   * Loads the currently selected item in the current cast media session.
   * @param appending If YES, the item is appended to the current queue if there
   * is one. If NO, or if
   * there is no queue, a new queue containing only the selected item is created.
   */

  func loadMedia(mediaInfo: GCKMediaInformation, byAppending appending: Bool) {
    print("enqueue item \(String(describing: mediaInfo))")
    if let remoteMediaClient = GCKCastContext.sharedInstance().sessionManager.currentCastSession?.remoteMediaClient {
      let builder = GCKMediaQueueItemBuilder()
      builder.mediaInformation = mediaInfo
      builder.autoplay = true
      builder.preloadTime = TimeInterval(UserDefaults.standard.integer(forKey: kPrefPreloadTime))
      let item = builder.build
      if (remoteMediaClient.mediaStatus != nil) && appending {
        let request = remoteMediaClient.queueInsert(item(), beforeItemWithID: kGCKMediaQueueInvalidItemID)
        request.delegate = self
      } else {
        let options = GCKMediaLoadOptions()
        options.autoplay = true
        let request = remoteMediaClient.loadMedia(mediaInfo, with: options)
        request.delegate = self
      }
    }
  }
}

// MARK: - GCKRequestDelegate

extension CLIGoogleCastHelper: GCKRequestDelegate {

  public func requestDidComplete(_ request: GCKRequest) {
    print("request \(Int(request.requestID)) completed")
  }

  public func request(_ request: GCKRequest, didFailWithError error: GCKError) {
    print("request \(Int(request.requestID)) failed with error \(error)")
  }
}
