//
//  CLPlayerController.swift
//  BPlayer
//
//  Created by admin on 26/03/2021.
//

import UIKit
import CoreMedia
import AVFoundation
import Player
import YTVimeoExtractor
import AVKit
import GoogleCast

public enum CLIVideoType {
  case hls
  case vimeo
}


public struct CLIVideoQuality: Equatable {
  var width: Int = 0
  var height: Int = 0
  var bandwidth: Double = 0
  var url: URL?
  var title: String {
    if self == .zero {
      return "Auto"
    } else {
      switch height {
        case 2160:
          return "4K"
        default:
          return "\(height)p"
      }
    }
  }
  static var zero: CLIVideoQuality { CLIVideoQuality(width: 0, height: 0, bandwidth: 0) }
}

 @objc public protocol CLIPlayerControllerDelegate {
  @objc optional func playerControllerWillAppear(_ player: CLIPlayerController)
  @objc optional func playerControllerWillDisapear(_ player: CLIPlayerController)
  @objc optional func playerControllerDidDisapear(_ player: CLIPlayerController)
}

public class CLIPlayerController: UIViewController {
  //MARK: IBOutlets
  @IBOutlet weak var playerContainerView: UIView!
  @IBOutlet weak var controlsContainerView: UIView!
  @IBOutlet weak var playButton: UIButton!
  @IBOutlet weak var qualityButton: UIButton!
  @IBOutlet weak var closeButton: UIButton!
  @IBOutlet weak var endClassButton: UIButton!
  @IBOutlet weak var volumeButton: UIButton!
  @IBOutlet weak var mirrorButton: UIButton!
  @IBOutlet weak var speedButton: UIButton!
  @IBOutlet weak var fillModeButton: UIButton!
  @IBOutlet weak var airPlayButton: CLIAirPlayButton!
  @IBOutlet weak var googleCastButton: CLIGoogleCastButton!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet weak var progressSlider: UISlider!
  @IBOutlet weak var currentTimeLabel: UILabel!
  @IBOutlet weak var topControlsView: UIView!
  @IBOutlet weak var bottomControlsView: UIView!
  @IBOutlet weak var progressContainerView: UIStackView!
  @IBOutlet weak var topControlsStackView: UIStackView!
  @IBOutlet weak var externalPlayerMaskView: UIView!
  @IBOutlet weak var externalPlayerDeviceLabel: UILabel!
  @IBOutlet weak var externalPlayerTitleLabel: UILabel!
  @IBOutlet weak var externalPlayerImageView: UIImageView!

  //MARK: Properties
  public override var prefersStatusBarHidden: Bool { true }
  public var config: CLIPlayerConfig? {
    didSet {
      applyConfig()
    }
  }
  public var delegate: CLIPlayerControllerDelegate?
  var player: Player!
  public var initialTimeInterval: TimeInterval = 0
  public var hideControlsTimeInterval: TimeInterval = 3
  public var url: URL? {
    didSet {
      if let url = url {
        player.url = url
        player.playFromBeginning()

        parseHlsInfo(url: url)
      }
    }
  }
  public var vimeoCode: String? {
    didSet {
      if let vimeoCode = vimeoCode {
        playVimeo(vimeoCode)
      }
    }
  }
  public var googleCastMetadata: GCKMediaMetadata?

  public private(set) var videoType: CLIVideoType = .hls
  var videoQualities: [CLIVideoQuality] = [] {
    didSet {
      DispatchQueue.main.async { [weak self] in
        self?.reloadQualitySetting()
      }
    }
  }

  public var currentQuality = CLIVideoQuality.zero {
    didSet {
      if videoType == .hls {
        player.preferredMaximumResolution = CGSize(width: currentQuality.width, height: currentQuality.height)
        player.preferredPeakBitRate = currentQuality.bandwidth
      } else {
        initialTimeInterval = player.currentTimeInterval
        player.url = currentQuality.url
      }
    }
  }

  public var currentSpeed: Float = 1.0 {
    didSet {
      rate = currentSpeed
      speedButton.setImage(UIImage(named: String(format: "plyr-speed-%.1fx", currentSpeed), in: Bundle.cliPlayerBundle, compatibleWith: nil), for: .normal)
    }
  }
  public var isMirrored = false {
    didSet {
      player.view.flipX()
      mirrorButton.flipX()
    }
  }
  private var vimeoVideo: YTVimeoVideo?
  private var vimeoSortedQualities: [Int] = []
  private let hlsParser = HLSParser()
  private var hidingControlTimer: Timer?
  private var delaySeekTimer: Timer?
  private var delaySetEstimatedTimeTimer: Timer?
  private var sliderIsDragging = false
  private var googleCastController: GCKUIMediaController?
  private var estimatedCurrentTime: TimeInterval? {
    didSet {
      if let estimatedCurrentTime = estimatedCurrentTime, !player.maximumDuration.isNaN {
        progressSlider.value = Float(estimatedCurrentTime / player.maximumDuration)
        updateCurrentTimeText(estimatedCurrentTime)
      }
    }
  }
  //MARK: Setups

  public class func instance() -> CLIPlayerController {
    let controller = UIStoryboard.cliPlayerStoryboard.instantiateViewController(withIdentifier: String(describing: Self.self)) as! CLIPlayerController
    controller.modalPresentationStyle = .fullScreen
    controller.modalTransitionStyle = .crossDissolve
    _ = controller.view
    return controller
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    initPlayer()
    if config == nil {
      config = CLIPlayerConfig()
    }

    setUpGoogleCast()
    setUpNotificationListeners()
  }

  public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let controller = segue.destination as? OverlaySeekButtonViewController {
      _ = controller.view
      controller.isRewind = segue.identifier == "RewindEmbedSegue"
      controller.infoOffset = controller.isRewind ? 50 : -50
      controller.onSingleTapped = { [weak self] in
        self?.controlsViewTappped(nil)
      }
      controller.onDoubleTapped = { [weak self] in
        if let self = self {
          controller.isRewind ? self.rewindButtonTapped(nil) : self.forwardButtonTapped(nil)
        }
      }
    }
  }

  private func setUpGoogleCast() {
    GCKCastContext.sharedInstance().sessionManager.add(self)
  }

  private func setUpNotificationListeners() {
//    AirPlay notification
    NotificationCenter.default.addObserver(self, selector: #selector(self.screenConnectionChanged(_:)), name: .MPVolumeViewWirelessRouteActiveDidChange, object: nil)
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self, name: .MPVolumeViewWirelessRouteActiveDidChange, object: nil)
  }

  public override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
//    Please check this workaround after update Google Cast version
    if let navController = viewControllerToPresent as? UINavigationController, let rootController = navController.viewControllers.first, String(describing: type(of: rootController)) == "GCKUIDeviceConnectionViewController" {
      let modalController = ModalWrapperViewController.instance()
      modalController.addViewController(navController)
      navController.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
      super.present(modalController, animated: flag, completion: completion)
    } else {
      super.present(viewControllerToPresent, animated: flag, completion: completion)
    }

  }
  
  @objc func volumeViewTapped(_ sender: Any?) {
    print("volumeViewTapped")
    delayHidingControls()
  }

  public override func viewWillAppear(_ animated: Bool) {
    delegate?.playerControllerWillAppear?(self)
    super.viewWillAppear(animated)
    setUpUI()
    try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
  }

  public override func viewWillDisappear(_ animated: Bool) {
    delegate?.playerControllerWillDisapear?(self)
    super.viewWillDisappear(animated)
  }

  public override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    delegate?.playerControllerDidDisapear?(self)
  }

  public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    setUpUI()
  }

  private func initPlayer() {
    player = Player()
    player.playerDelegate = self
    player.playbackDelegate = self
    player.view.frame = playerContainerView.bounds
    player.playerView.backgroundColor = .black
    addChild(player)
    playerContainerView.addSubview(player.view)
    player.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    player.didMove(toParent: self)
    hideControls(true)
  }

  private func applyConfig() {
    if let config = config {
      titleLabel.font = config.classTitleFont
      descriptionLabel.font = config.classDescriptionFont
      endClassButton.titleLabel?.font = config.endClassButtonFont
      currentTimeLabel.font = config.currentTimeFont
      externalPlayerTitleLabel.font = config.airPlayTitleFont
      externalPlayerDeviceLabel.font = config.airPlayDeviceFont

      for controller in children {
        if let seekController = controller as? OverlaySeekButtonViewController {
          seekController.timeLabel.font = config.seekOverlayFont
        }
      }
    }
  }

  private var isLandscape: Bool {
    UIDevice.current.orientation.isLandscape
  }

  //MARK: Actions
  @IBAction func playButtonTapped(_ sender: Any) {
    delayHidingControls()
    if isPlaying {
      pause()
    } else {
      playFromCurrentTime()
    }
  }

  @IBAction func controlsViewTappped(_ sender: Any?) {
    hideControls(false)
    bottomControlsView.isHidden = false
    delayHidingControls()
  }

  @IBAction func rewindButtonTapped(_ sender: Any?) {
    delayHidingControls()
    seek(to: -15, relative: true)
  }

  @IBAction func forwardButtonTapped(_ sender: Any?) {
    delayHidingControls()
    seek(to: 15, relative: true)
  }

  @IBAction func mirrorButtonTapped(_ sender: Any) {
    delayHidingControls()
    isMirrored = !isMirrored
  }

  @IBAction func volumeButtonTapped(_ sender: Any) {
    delayHidingControls()
    let newMuted = !muted
    muted = newMuted
    let imageName = newMuted ? "plyr-muted" : "plyr-volume"
    volumeButton.setImage(UIImage(named: imageName, in: Bundle.cliPlayerBundle, compatibleWith: nil), for: .normal)
  }

  @IBAction func qualityButtonTapped(_ sender: Any) {
    delayHidingControls()
    let modalController = SelectorModalViewController.instance()
    modalController.title = "Select Quality"
    modalController.items = videoQualities.map { (quality) -> SelectorModalItem in
      let title = quality.title
      return SelectorModalItem(title: title, selected: quality == currentQuality) { [weak self] _ in
        self?.currentQuality = quality
      }
    }
    
    showSelectorModalController(modalController)
  }

  @IBAction func progressSliderValueChanged(_ sender: UISlider, forEvent event: UIEvent) {
    delayHidingControls()
    print("progressSliderValueChanged: ", progressSlider.value)
    guard let touch = event.allTouches?.first, touch.phase != .ended else {
      sliderIsDragging = false
      if !googleCasting && !player.maximumDuration.isNaN {
        let newTime = Double(progressSlider.value) * player.maximumDuration
        seekInternalPlayer(to: newTime, relative: false)
      }

      return
    }
    sliderIsDragging = true
  }

  @IBAction func fillModeButtonTapped(_ sender: Any) {
    delayHidingControls()
    player.playerView.playerFillMode = player.playerView.playerFillMode == .resizeAspect ? .resizeAspectFill : .resizeAspect
    let imageName = player.playerView.playerFillMode == .resizeAspect ? "plyr-enter-fullscreen" : "plyr-exit-fullscreen"
    fillModeButton.setImage(UIImage(named: imageName, in: Bundle.cliPlayerBundle, compatibleWith: nil), for: .normal)
  }

  @IBAction func speedButtonTapped(_ sender: Any) {
    delayHidingControls()
    let speeds: [Float] = [0.7, 0.8, 0.9, 1]
    let modalController = SelectorModalViewController.instance()
    modalController.title = "Select Speed"
    modalController.items = speeds.map { (speed) -> SelectorModalItem in
      let title = speed == 1 ? "Normal" : "\(speed)x"
      return SelectorModalItem(title: title, selected: currentSpeed == speed) { [weak self] _ in
        self?.currentSpeed = speed
      }
    }

    present(modalController, animated: true, completion: nil)
  }

  @IBAction func closeButtonTapped(_ sender: Any) {
    stop()
    dismiss(animated: true, completion: nil)
  }

  @IBAction func airplayButtonTapped(_ sender: Any) {
    delayHidingControls()
    airPlayButton.showAirPlayModal()
  }
  @IBAction func googleCastButtonTapped(_ sender: Any) {
    delayHidingControls()
  }
}

//MARK: Private methods
extension CLIPlayerController {
  private func setUpUI() {
    setUpCloseButton()
  }

  private func setUpCloseButton() {
    closeButton.isHidden =  isLandscape
    endClassButton.isHidden = !closeButton.isHidden
  }

  private func hideControls(_ isHidden: Bool) {
    topControlsView.isHidden = isHidden
    bottomControlsView.isHidden = isHidden
  }

  private func delayHidingControls() {
    if let hidingControlTimer = hidingControlTimer {
      hidingControlTimer.invalidate()
    }
    hidingControlTimer = Timer.scheduledTimer(withTimeInterval: hideControlsTimeInterval, repeats: false) { [weak self] (timer) in
      if self?.isPlaying == true {
        self?.hideControls(true)
      } else {
        self?.delayHidingControls()
      }
    }
  }

  private func showSelectorModalController(_ modalController: SelectorModalViewController) {
    present(modalController, animated: true, completion: nil)
    modalController.config = config?.selectorModalConfig
  }

  private func refreshPlayButtonImage() {
    if isPlaying {
      playButton.setImage(UIImage(named: "plyr-pause", in: Bundle.cliPlayerBundle, compatibleWith: nil), for: .normal)
    } else {
      playButton.setImage(UIImage(named: "plyr-play", in: Bundle.cliPlayerBundle, compatibleWith: nil), for: .normal)
    }
  }

  private func reloadQualitySetting() {
    qualityButton.isHidden = videoQualities.isEmpty
  }

  private func parseHlsInfo(url: URL) {
    if url.pathExtension == "m3u8" {
      videoType = .hls
      self.videoQualities = []
      hlsParser.parseStreamTags(url: url) { (hlsStreamInfos) in
        var qualities = hlsStreamInfos.map { CLIVideoQuality(width: $0.width ?? 0, height: $0.height ?? 0, bandwidth: Double($0.bandwidth ?? 0), url: $0.url) }
        qualities.insert(CLIVideoQuality.zero, at: 0)
        self.videoQualities = qualities
      } failedBlock: { (error) in
        print("parse error--", error!)
      }
    }
  }

  private func playVimeo(_ code: String) {
    vimeoSortedQualities = []
    YTVimeoExtractor.shared().fetchVideo(withIdentifier: code, withReferer: nil) { [weak self] (video, error) in
      if let video = video {
        self?.vimeoVideo = video
        self?.videoType = .vimeo
        let keys = (video.streamURLs.keys.compactMap { ($0 as? Int) }).sorted()
        self?.vimeoSortedQualities = keys
        self?.videoQualities = keys.map { CLIVideoQuality(width: 0, height: $0, bandwidth: 0, url: video.streamURLs[$0]) }
        if let lastQuality = self?.videoQualities.last {
          self?.currentQuality = lastQuality
        }
      }
    }
  }
  
  @objc func screenConnectionChanged(_ notification: Notification) {
    if airPlayButton.isWirelessRouteActive {
      playFromCurrentTime()
      refreshPlayerForAirplay()
    } else {
      refreshInternalPlayer()
    }
  }

  private func refreshPlayerForGoogleCast() {
    externalPlayerImageView.image = UIImage(named: "chromecast_white", in: Bundle.cliPlayerBundle, compatibleWith: nil)
    externalPlayerDeviceLabel.text = " "
    externalPlayerTitleLabel.text = "Chrome Cast"
    externalPlayerMaskView.isHidden = false
    mirrorButton.isHidden = true
    qualityButton.isHidden = true
    fillModeButton.isHidden = true
    airPlayButton.forceHidden = true
  }

  private func refreshPlayerForAirplay() {
    externalPlayerDeviceLabel.text = " "
    externalPlayerTitleLabel.text = "AirPlay"
    externalPlayerImageView.image = UIImage(named: "airplay_white", in: Bundle.cliPlayerBundle, compatibleWith: nil)
    let currentRoute = AVAudioSession.sharedInstance().currentRoute
    for output in currentRoute.outputs {
      if output.portType == AVAudioSession.Port.airPlay {
        externalPlayerDeviceLabel.text = "This video is playing on \"\(output.portName)\""
        break
      }
    }
    externalPlayerMaskView.isHidden = false
    mirrorButton.isHidden = true
    fillModeButton.isHidden = true
    googleCastButton.isHidden = true
    rate = currentSpeed
  }

  private func refreshInternalPlayer() {
    externalPlayerMaskView.isHidden = true
    mirrorButton.isHidden = false
    googleCastButton.isHidden = false
    fillModeButton.isHidden = false
    airPlayButton.forceHidden = nil
    airPlayButton.showIfAvailable()
    reloadQualitySetting()
    rate = currentSpeed
  }
}

//MARK: Player Delegate
extension CLIPlayerController: PlayerDelegate, PlayerPlaybackDelegate {
  public func playerReady(_ player: Player) {
    print("playerReady")
    if initialTimeInterval > 0 {
      player.seek(to: CMTimeMake(value: Int64(initialTimeInterval), timescale: 1))
      initialTimeInterval = 0
    }
    hideControls(false)
    delayHidingControls()
    if airPlayButton.isWirelessRouteActive {
      playFromCurrentTime()
    }
  }

  public func playerPlaybackStateDidChange(_ player: Player) {
    print("playerPlaybackStateDidChange: ", player.playbackState)
    if googleCasting {
      return
    }
    refreshPlayButtonImage()
  }

  public func playerBufferingStateDidChange(_ player: Player) {
    print("playerBufferingStateDidChange: ", player.bufferingState)
  }

  public func playerBufferTimeDidChange(_ bufferTime: Double) {
  }

  public func player(_ player: Player, didFailWithError error: Error?) {
    print("didFailWithError", error!)
  }

  public func playerCurrentTimeDidChange(_ player: Player) {
    if googleCasting || player.currentTimeInterval.isNaN || player.maximumDuration.isNaN || estimatedCurrentTime != nil {
      return
    }

    let currentTimeInterval = player.currentTimeInterval

    let progress = currentTimeInterval / player.maximumDuration
    if !sliderIsDragging {
      progressSlider.value = Float(progress)
    }

    updateCurrentTimeText(currentTimeInterval)
  }

  func updateCurrentTimeText(_ currentTimeInterval: TimeInterval) {
    let currentSeconds = Int(currentTimeInterval)
    currentTimeLabel.text = String(format: "%02d:%02d", currentSeconds / 60, currentSeconds % 60)
  }

  public func playerPlaybackWillStartFromBeginning(_ player: Player) {
    print("playerPlaybackWillStartFromBeginning")
  }

  public func playerPlaybackDidEnd(_ player: Player) {
    print("playerPlaybackDidEnd")
  }

  public func playerPlaybackWillLoop(_ player: Player) {
    print("playerPlaybackWillLoop")
  }

  public func playerPlaybackDidLoop(_ player: Player) {
    print("playerPlaybackDidLoop")
  }
}

//MARK: Google Cast Listeners
extension CLIPlayerController: GCKSessionManagerListener {
  public func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKCastSession) {
    print("didStart session: GCKCastSession", session)
    session.remoteMediaClient?.add(self)
    player.pause()
    googleCastController = GCKUIMediaController()
    googleCastController?.delegate = self
    googleCastController?.streamPositionSlider = progressSlider
    googleCastController?.streamPositionLabel = currentTimeLabel
    if let url = player.url {
      let builder = GCKMediaInformationBuilder(contentURL: url)
      builder.metadata = googleCastMetadata
      CLIGoogleCastHelper.shared.loadMedia(mediaInfo: builder.build(), byAppending: false)
    }
    refreshPlayerForGoogleCast()
    if let friendlyName = session.device.friendlyName {
      externalPlayerDeviceLabel.text = "This video is playing on \"\(friendlyName)\""
    }

  }


  public func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKCastSession, withError error: Error?) {
    let currentTime = googleCastController?.lastKnownStreamPosition
    googleCastController?.streamPositionSlider = nil
    googleCastController?.streamPositionLabel = nil
    googleCastController?.delegate = nil
    googleCastController = nil

    refreshInternalPlayer()

    if let currentTime = currentTime {
      if currentTime.isNaN {
        seek(to: 0, relative: false)
        stop()
      } else {
        seek(to: currentTime, relative: false)
        playFromCurrentTime()
      }
    }

    session.remoteMediaClient?.remove(self)
  }
}

extension CLIPlayerController: GCKRemoteMediaClientListener {
  public func remoteMediaClient(_ client: GCKRemoteMediaClient, didStartMediaSessionWithID sessionID: Int) {
    rate = currentSpeed
    seek(to: player.currentTimeInterval, relative: false)
  }
}

extension CLIPlayerController: GCKUIMediaControllerDelegate {
  public func mediaController(_ mediaController: GCKUIMediaController, didUpdate playerState: GCKMediaPlayerState, lastStreamPosition streamPosition: TimeInterval) {
    refreshPlayButtonImage()
  }
}

//MARK: Player Controls
extension CLIPlayerController {
  public var googleCasting: Bool {
    googleCastController?.mediaLoaded == true
  }

  public var isPlaying: Bool {
    if googleCasting {
      return CLIGoogleCastHelper.shared.isPlaying
    }

    return player.playbackState == .playing
  }

  var muted: Bool {
    get {
      if googleCasting, let isMuted = CLIGoogleCastHelper.shared.mediaStatus?.isMuted {
        return isMuted
      }
      return player.muted
    }
    set {
      if googleCasting, let remoteMediaClient = CLIGoogleCastHelper.shared.remoteMediaClient {
        remoteMediaClient.setStreamMuted(newValue)
      } else {
        player.muted = newValue
      }
    }
  }

  var currentTimeInterval: TimeInterval {
    get {
      if googleCasting, let mediaStatus = CLIGoogleCastHelper.shared.mediaStatus {
        return mediaStatus.streamPosition
      }
      return player.currentTimeInterval
    }
    set {
      seek(to: newValue, relative: false)
    }
  }

  var rate: Float {
    get {
      if googleCasting, let mediaStatus = CLIGoogleCastHelper.shared.mediaStatus {
        return mediaStatus.playbackRate
      }
      return player.rate
    }
    set {
      if googleCasting, let client = CLIGoogleCastHelper.shared.remoteMediaClient {
        client.setPlaybackRate(newValue)
      } else {
        player.rate = newValue
      }
    }
  }

  func pause() {
    if googleCasting {
      CLIGoogleCastHelper.shared.remoteMediaClient?.pause()
    } else {
      player.pause()
    }
  }

  func playFromCurrentTime() {
    if googleCasting {
      CLIGoogleCastHelper.shared.remoteMediaClient?.play()
    } else {
      player.playFromCurrentTime()
    }
  }

  func delaySeekInternalPlayer(toTime: TimeInterval) {
    if let delaySeekTimer = delaySeekTimer {
      delaySeekTimer.invalidate()
    }

    delaySeekTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] (timer) in
      self?.player.seek(to: CMTimeMake(value: Int64(toTime), timescale: 1))
    }
  }

  func delaySetEstimatedCurrentTime(_ toTime: TimeInterval?) {
    if let delaySetEstimatedTimeTimer = delaySetEstimatedTimeTimer {
      delaySetEstimatedTimeTimer.invalidate()
    }

    delaySetEstimatedTimeTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] (timer) in
      self?.estimatedCurrentTime = toTime
    }
  }

  func seekInternalPlayer(to toTime: TimeInterval, relative: Bool) {
    if toTime.isNaN {
      return
    }
    let currentTimeInterval = estimatedCurrentTime ?? player.currentTimeInterval
    var newTime = relative ? currentTimeInterval + toTime : toTime
    newTime = min(newTime, player.maximumDuration - 1)
    newTime = max(newTime, 0)
    estimatedCurrentTime = newTime
    delaySeekInternalPlayer(toTime: newTime)
    delaySetEstimatedCurrentTime(nil)
  }

  func seekGoogleCastPlayer(to toTime: TimeInterval, relative: Bool) {
    let option = GCKMediaSeekOptions()
    option.interval = toTime
    option.relative = relative
    CLIGoogleCastHelper.shared.remoteMediaClient?.seek(with: option)
  }

  func seek(to toTime: TimeInterval, relative: Bool) {
    if googleCasting {
      seekGoogleCastPlayer(to: toTime, relative: relative)
    } else {
      seekInternalPlayer(to: toTime, relative: relative)
    }
  }

  func stop() {
    if GCKCastContext.sharedInstance().sessionManager.hasConnectedCastSession() {
      GCKCastContext.sharedInstance().sessionManager.endSessionAndStopCasting(true)
    } else {
      player.stop()
    }
  }
}

//MARK: Miscs
extension CLIPlayerController {
  public func setClassTitle(_ text: String?) {
    titleLabel.text = text
  }

  public func setClassDescription(_ text: String?) {
    descriptionLabel.text = text
  }

  public func setClassDescription(artistName: String, duration: String, genre: String, level: String) {
    let text = "\(artistName) | \(duration)\n\(genre) | \(level)"
    setClassDescription(text)
  }

  public func setEndClassButtonText(_ text: String?) {
    endClassButton.setTitle(text, for: .normal)
  }
}
