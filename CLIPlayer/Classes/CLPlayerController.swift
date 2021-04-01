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
    self == .zero ? "Auto" : "\(height)"
  }
  static var zero: CLIVideoQuality { CLIVideoQuality(width: 0, height: 0, bandwidth: 0) }
}

public class CLIPlayerController: UIViewController {
  @IBOutlet weak var playerContainerView: UIView!
  @IBOutlet weak var controlsContainerView: UIView!

  @IBOutlet weak var playButton: UIButton!
  @IBOutlet weak var qualityButton: UIButton!
  @IBOutlet weak var closeButton: UIButton!
  @IBOutlet weak var endClassButton: UIButton!
  @IBOutlet weak var volumeButton: UIButton!
  @IBOutlet weak var mirrorButton: UIButton!
  @IBOutlet weak var speedButton: UIButton!

  @IBOutlet weak var progressSlider: UISlider!
  @IBOutlet weak var currentTimeLabel: UILabel!
  @IBOutlet weak var topControlsView: UIStackView!
  @IBOutlet weak var bottomControlsView: UIStackView!
  @IBOutlet weak var progressContainerView: UIStackView!
  @IBOutlet weak var bottomControlButtonsContainerView: UIStackView!

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
  private var seekingTimer: Timer?
  private var sliderIsDragging = false

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  convenience init() {
    self.init(nibName: String(describing: Self.self), bundle: Bundle(for: Self.self))
    modalPresentationStyle = .fullScreen
    _ = self.view
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    initPlayer()
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

  private func setUpUI() {
    setUpCloseButton()
    setUpCurrentTimeLabel()
  }

  private func setUpCloseButton() {
    closeButton.isHidden =  UIDevice.current.orientation.isLandscape
    endClassButton.isHidden = !closeButton.isHidden
  }

  private func setUpCurrentTimeLabel() {
    if UIDevice.current.orientation.isLandscape {
      bottomControlButtonsContainerView.insertArrangedSubview(currentTimeLabel, at: 4)
    } else {
      progressContainerView.addArrangedSubview(currentTimeLabel)
    }
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
      self?.topControlsView.isHidden = true
      self?.bottomControlsView.isHidden = true
    }
  }

  private func delaySeek() {
    if let seekingTimer = seekingTimer {
      seekingTimer.invalidate()
    }
    seekingTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] (timer) in
      if let self = self {
        let newTime = Double(self.progressSlider.value) * self.player.maximumDuration
        self.player.seek(to: CMTimeMake(value: Int64(newTime), timescale: 1))
      }

    }
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
    let modalController = SelectorModalViewController()
    modalController.title = "Select Quality"
    modalController.items = videoQualities.map { (quality) -> SelectorModalItem in
      let title = quality.title
      return SelectorModalItem(title: title, selected: quality == currentQuality) { [weak self] _ in
        self?.currentQuality = quality
      }
    }

    present(modalController, animated: true, completion: nil)
  }

  @IBAction func progressSliderValueChanged(_ sender: UISlider, forEvent event: UIEvent) {
    delayHidingControls()
    print("progressSliderValueChanged: ", progressSlider.value)
    guard let touch = event.allTouches?.first, touch.phase != .ended else {
      sliderIsDragging = false
      let newTime = Double(progressSlider.value) * player.maximumDuration
      player.seek(to: CMTimeMake(value: Int64(newTime), timescale: 1))
      return
    }
    sliderIsDragging = true
    // not ended yet
    //    delaySeek()
  }

  @IBAction func fillModeButtonTapped(_ sender: Any) {
    delayHidingControls()
    player.playerView.playerFillMode = player.playerView.playerFillMode == .resizeAspect ? .resizeAspectFill : .resizeAspect
  }

  @IBAction func speedButtonTapped(_ sender: Any) {
    delayHidingControls()
    let speeds: [Float] = [0.7, 0.8, 0.9, 1]
    let modalController = SelectorModalViewController()
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

