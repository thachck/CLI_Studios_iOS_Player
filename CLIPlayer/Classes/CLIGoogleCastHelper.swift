//
//  GoogleCastHelper.swift
//  CLIStudios
//
//  Created by East Agile on 1/31/18.
//  Copyright © 2018 CLI Studios. All rights reserved.
//

import GoogleCast

let kPrefPreloadTime = "preload_time_sec"
let kThumbnailWidth = 405
let kThumbnailHeight = 720
let kPosterWidth = 675
let kPosterHeight = 1200
let kCustomChannelNamespace = "urn:x-cast:com.cli.custom"
let kApplicationStateChangedType = "ApplicationStateChanged"

enum ApplicationState: Int {
  case active
  case inactive

  func data() -> [String: Any] {
    switch self {
      case .active:
        return ["message": "Active", "code": rawValue]
      case .inactive:
        return ["message": "Inactive", "code": rawValue]
    }
  }
}

public protocol CLIVideo {

}

public class CLIGoogleCastHelper: NSObject {

  static let shared = CLIGoogleCastHelper()
  var startTime: TimeInterval = 0
  var mediaController: GCKUIMediaController!

  // chrome cast sdk sends the same event every ~5-10 seconds so we need this to differentiate the user action from the automated ones
  var previousPlayingState: GCKMediaPlayerState! = .unknown
  var currentVideo: CLIVideo?
  var textChannel: GCKGenericChannel?
  var pendingMessage: String?

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

  override init() {
    super.init()

    mediaController = GCKUIMediaController()
    mediaController.delegate = self

    GCKCastContext.sharedInstance().sessionManager.add(self)
    NotificationCenter.default.addObserver(self, selector: #selector(showExpandedPlayer), name: NSNotification.Name.gckExpandedMediaControlsTriggered, object: nil)
  }

  @objc func showExpandedPlayer() {
//    let controller = UIViewController.chromeCastExpandedPlayerController()
//    controller.modalPresentationStyle = .fullScreen
//    UIViewController.topMostController().present(controller, animated: true)
  }

  func setupCustomChannel() {
    guard let session = GCKCastContext.sharedInstance().sessionManager.currentCastSession else { return }

    if let textChannel = textChannel {
      session.remove(textChannel)
    }

    let newChannel = GCKGenericChannel(namespace: kCustomChannelNamespace)
    textChannel = newChannel
    newChannel.delegate = self
    session.add(newChannel)
  }

  func sendApplicationState(_ state: ApplicationState) {
    var data = state.data()
    data["type"] = kApplicationStateChangedType

    if let json = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted), let jsonString = String(data: json, encoding: .utf8) {
      sendMessage(jsonString)
    }

  }

  func sendMessage(_ message: String) {
    guard let textChannel = textChannel else {
      pendingMessage = message
      return
    }

    var error: GCKError?
    textChannel.sendTextMessage(message, error: &error)
    if error != nil {
      print("√√Error sending text message \(error.debugDescription)")
      pendingMessage = message
    }
  }

  func resendMessage() {
    guard let textChannel = textChannel, let pendingMessage = pendingMessage else { return }

    var error: GCKError?
    textChannel.sendTextMessage(pendingMessage, error: &error)
    if let error = error {
      print("√√Error sending text message \(error.debugDescription)")
    } else {
      self.pendingMessage = nil
    }
  }

  func playSelectedItemRemotely(mediaInfo: GCKMediaInformation) {
    trackVideoProgress()
    loadMedia(mediaInfo: mediaInfo, byAppending: false)
  }

  func enqueueSelectedItemRemotely(mediaInfo: GCKMediaInformation) {
    self.loadMedia(mediaInfo: mediaInfo, byAppending: true)
    let message = "Added \"\(mediaInfo.metadata?.string(forKey: kGCKMetadataKeyTitle) ?? "")\" to queue."
    print(message)
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

  func trackVideoProgress() {
//    if let video = currentVideo {
//      if startTime != 0 {
//        let playingDuration = Date().timeIntervalSince1970 - startTime
//        startTime = 0
//        let roundedDuration = playingDuration.rounded(toPlaces: 2)
//        User.currentUser()?.requestTrackClassView(videoId: video.id, duration: roundedDuration, userStudioAssignmentId: video.userStudioAssignmentId)
//        AmplitudeService.trackEvent(event: .playVideo(video, roundedDuration, .videoDetailScreen, "Chromecast"))
//      }
//    }
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

extension CLIGoogleCastHelper: GCKUIMediaControllerDelegate {

  // "PLAY" / "PAUSE" events
  public func mediaController(_ mediaController: GCKUIMediaController, didUpdate mediaStatus: GCKMediaStatus) {
    switch mediaStatus.playerState {
      case .playing:
        if previousPlayingState != .playing {
          startTime = Date().timeIntervalSince1970
        }
      case .paused, .idle:
        if previousPlayingState == .playing {
          trackVideoProgress()
        }
      default:
        break
    }

    previousPlayingState = mediaStatus.playerState
  }

}

extension CLIGoogleCastHelper: GCKSessionManagerListener {

  // "STOP" event
  public func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKCastSession, withError error: Error?) {
    textChannel = nil
    if previousPlayingState == .playing {
      trackVideoProgress()
    }
  }

  public func sessionManager(_ sessionManager: GCKSessionManager, didResumeCastSession session: GCKCastSession) {
    setupCustomChannel()
  }

  public func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKCastSession) {
    setupCustomChannel()
  }
}

extension CLIGoogleCastHelper: GCKGenericChannelDelegate {
  public func cast(_ channel: GCKGenericChannel, didReceiveTextMessage message: String, withNamespace protocolNamespace: String) {
    print("√√√didReceiveTextMessage", message, protocolNamespace)
  }

  public func castChannelDidConnect(_ channel: GCKGenericChannel) {
    DispatchQueue.main.asyncAfter(deadline: .now()) {
      self.resendMessage()
    }
  }
}
