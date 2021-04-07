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
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet weak var progressSlider: UISlider!
  @IBOutlet weak var currentTimeLabel: UILabel!
  @IBOutlet weak var topControlsView: UIView!
  @IBOutlet weak var bottomControlsView: UIView!
  @IBOutlet weak var progressContainerView: UIStackView!
  @IBOutlet weak var bottomControlButtonsContainerView: UIStackView!
  @IBOutlet weak var rewindInfoContainerView: UIStackView!
  @IBOutlet weak var forwardInfoContainerView: UIStackView!
  @IBOutlet weak var forwardOverlayContainerView: UIView!
  @IBOutlet weak var rewindOverlayContainerView: UIView!
  @IBOutlet weak var rewindArrowsContainer: UIStackView!
  @IBOutlet weak var forwardArrowsContainer: UIStackView!
  @IBOutlet weak var forwardOverlayLabel: UILabel!
  @IBOutlet weak var rewindOverlayLabel: UILabel!
  
  //MARK: Properties
  public override var prefersStatusBarHidden: Bool { true }
  public var config: CLIPlayerConfig! {
    didSet {
      applyConfig()
    }
  }
  public var forceLandscape = true
  public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    forceLandscape ? .landscape : .all
  }
  public override var shouldAutorotate: Bool { true }

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
      player.rate = currentSpeed
      speedButton.setImage(UIImage(named: String(format: "plyr-speed-%.1fx", currentSpeed), in: Bundle(for: Self.self), compatibleWith: nil), for: .normal)
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
  private var sliderIsDragging = false
  //MARK: Setups
    
  public class func instance() -> CLIPlayerController {
      let storyboard = UIStoryboard(name: "CLIPlayer", bundle: Bundle(for: Self.self))
      let controller = storyboard.instantiateViewController(withIdentifier: String(describing: Self.self)) as! CLIPlayerController
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
  }

  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    setUpUI()
    try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
  }

  public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    setUpUI()
  }

  func initPlayer() {
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

  func applyConfig() {
    titleLabel.font = config.classTitleFont
    descriptionLabel.font = config.classDescriptionFont
    endClassButton.titleLabel?.font = config.endClassButtonFont
    currentTimeLabel.font = config.currentTimeFont
    rewindOverlayLabel.font = config.seekOverlayFont
    forwardOverlayLabel.font = config.seekOverlayFont
  }

  private var isLandscape: Bool {
    forceLandscape ? true : UIDevice.current.orientation.isLandscape
  }

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
      if self?.player.playbackState == .playing {
        self?.hideControls(true)
      } else {
        self?.delayHidingControls()
      }
    }
  }
  
  private func showSelectorModalController(_ modalController: SelectorModalViewController) {
    present(modalController, animated: true, completion: nil)
    modalController.config = config.selectorModalConfig
  }

  //MARK: Actions
  @IBAction func playButtonTapped(_ sender: Any) {
    delayHidingControls()
    if player.playbackState == .playing {
      player.pause()
    } else {
      player.playFromCurrentTime()
    }
  }

  @IBAction func controlsViewTappped(_ sender: Any) {
    hideControls(false)
    bottomControlsView.isHidden = false
    delayHidingControls()
  }

  @IBAction func rewindButtonTapped(_ sender: Any) {
    delayHidingControls()
    let newTime = max(player.currentTimeInterval - 15, 0)
    player.seek(to: CMTimeMake(value: Int64(newTime), timescale: 1))
  }

  @IBAction func forwardButtonTapped(_ sender: Any) {
    delayHidingControls()
    let newTime = min(player.currentTimeInterval + 15, player.maximumDuration - 1)
    player.seek(to: CMTimeMake(value: Int64(newTime), timescale: 1))
  }

  @IBAction func mirrorButtonTapped(_ sender: Any) {
    delayHidingControls()
    isMirrored = !isMirrored
  }

  @IBAction func volumeButtonTapped(_ sender: Any) {
    delayHidingControls()
    player.muted = !player.muted
    let imageName = player.muted ? "plyr-muted" : "plyr-volume"
    volumeButton.setImage(UIImage(named: imageName, in: Bundle(for: Self.self), compatibleWith: nil), for: .normal)
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
    guard let touch = event.allTouches?.first, touch.phase != .ended, player.maximumDuration != .nan else {
      sliderIsDragging = false
      let newTime = Double(progressSlider.value) * player.maximumDuration
      player.seek(to: CMTimeMake(value: Int64(newTime), timescale: 1))
      return
    }
    sliderIsDragging = true
  }

  @IBAction func fillModeButtonTapped(_ sender: Any) {
    delayHidingControls()
    player.playerView.playerFillMode = player.playerView.playerFillMode == .resizeAspect ? .resizeAspectFill : .resizeAspect
    let imageName = player.playerView.playerFillMode == .resizeAspect ? "plyr-enter-fullscreen" : "plyr-exit-fullscreen"
    fillModeButton.setImage(UIImage(named: imageName, in: Bundle(for: Self.self), compatibleWith: nil), for: .normal)
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
    dismiss(animated: true, completion: nil)
  }
  
  @IBAction func rewindTapGestureTapped(_ sender: Any) {
    rewindButtonTapped(sender)
    animateOverlaySeekButton(container: rewindOverlayContainerView, infoView: rewindInfoContainerView, arrowsContainer: rewindArrowsContainer, toLeft: false)
  }
  
  @IBAction func forwardTapGestureTapped(_ sender: Any) {
    forwardButtonTapped(sender)
    animateOverlaySeekButton(container: forwardOverlayContainerView, infoView: forwardInfoContainerView, arrowsContainer: forwardArrowsContainer, toLeft: true)
  }
}

extension CLIPlayerController {
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
        //        print("vimeo url----", video.streamURLs[keys[0]])
        self?.videoQualities = keys.map { CLIVideoQuality(width: 0, height: $0, bandwidth: 0, url: video.streamURLs[$0]) }
        if let lastQuality = self?.videoQualities.last {
          self?.currentQuality = lastQuality
        }
      }
    }
  }
}

extension CLIPlayerController: PlayerDelegate, PlayerPlaybackDelegate {
  public func playerReady(_ player: Player) {
    print("playerReady")
    if initialTimeInterval > 0 {
      player.seek(to: CMTimeMake(value: Int64(initialTimeInterval), timescale: 1))
      initialTimeInterval = 0
    }
    hideControls(false)
    delayHidingControls()
  }

  public func playerPlaybackStateDidChange(_ player: Player) {
    if player.playbackState == .playing {
      playButton.setImage(UIImage(named: "plyr-pause", in: Bundle(for: Self.self), compatibleWith: nil), for: .normal)
    } else {
      playButton.setImage(UIImage(named: "plyr-play", in: Bundle(for: Self.self), compatibleWith: nil), for: .normal)
    }
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
    if player.currentTimeInterval.isNaN || player.maximumDuration.isNaN {
      return
    }

    let progress = player.currentTimeInterval / player.maximumDuration
    if !sliderIsDragging {
      progressSlider.value = Float(progress)
    }

    let currentSeconds = Int(player.currentTimeInterval)
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
  
  func animateOverlaySeekButton(container: UIView, infoView: UIView, arrowsContainer: UIStackView, toLeft: Bool) {
    infoView.isHidden = false
    infoView.alpha = 1
    container.backgroundColor = .init(red: 1, green: 1, blue: 1, alpha: 0.4)
    container.layer.cornerRadius = container.frame.height / 2
    for subView in arrowsContainer.arrangedSubviews {
      subView.alpha = 0
    }
    if toLeft {
      arrowsContainer.arrangedSubviews[0].alpha = 1
    } else {
      arrowsContainer.arrangedSubviews[arrowsContainer.arrangedSubviews.count - 1].alpha = 1
    }
    let enumeratedItems = toLeft ? arrowsContainer.subviews.enumerated() : arrowsContainer.subviews.reversed().enumerated()
    for (index, item) in enumeratedItems {
      item.alpha = 0
      
      DispatchQueue.main.asyncAfter(deadline: .now() + (0.1 * Double(index))) {
        UIView.animate(withDuration: 0.2) {
          item.alpha = 1
        } completion: { (completed) in
          item.alpha = 0
        }
      }
    }
    
    UIView.animate(withDuration: 1) {
      infoView.alpha = 0
      container.backgroundColor = .clear
    } completion: { (completed) in
      infoView.isHidden = true
    }
  }
}
