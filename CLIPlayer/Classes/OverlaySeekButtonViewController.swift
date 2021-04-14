//
//  OverlaySeekButtonViewController.swift
//  CLIPlayer
//
//  Created by EA on 15/04/2021.
//

import UIKit

class OverlaySeekButtonViewController: UIViewController {
  @IBOutlet weak var infoView: UIStackView!
  @IBOutlet weak var arrowsContainer: UIStackView!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var infoVIewCenterXConstraint: NSLayoutConstraint!
  var numberOfSeconds = 15
  var arrowText: String = "◀" {
    didSet {
      for subview in arrowsContainer.subviews {
        if let label = subview as? UILabel {
          label.text = arrowText
        }
      }
    }
  }
  var isRewind = true {
    didSet {
      arrowText = isRewind ? "◀" : "▶"
    }
  }
  var infoOffset: CGFloat = 0 {
    didSet {
      infoVIewCenterXConstraint.constant = infoOffset
    }
  }

  var active = false
  var setActiveTimer: Timer?
  var onSingleTapped: (() -> Void)?
  var onDoubleTapped: (() -> Void)?
  var triggerTimes = 0 {
    didSet {
      timeLabel.text = "\(triggerTimes * numberOfSeconds) seconds"
    }
  }
  var operationQueue: OperationQueue? {
    willSet {
      operationQueue?.cancelAllOperations()
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(singleTapGestureTapped(_:)))
    tapGesture.delaysTouchesBegan = true
    let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(doubleTapGestureTapped(_:)))
    doubleTapGesture.numberOfTapsRequired = 2
    doubleTapGesture.delaysTouchesBegan = true

    view.addGestureRecognizer(tapGesture)
    view.addGestureRecognizer(doubleTapGesture)
  }

  private func delaySetActive(_ isActive: Bool, timeInterval: TimeInterval = 0.5) {
    if let setActiveTimer = setActiveTimer {
      setActiveTimer.invalidate()
    }
    setActiveTimer = nil
    setActiveTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] (timer) in
      self?.active = isActive
      self?.triggerTimes = 0
    }
  }

  @objc func singleTapGestureTapped(_ sender: Any) {
    onSingleTapped?()
    if active {
      doubleTapGestureTapped(sender)
    }
  }

  @objc func doubleTapGestureTapped(_ sender: Any) {
    triggerTimes += 1
    onDoubleTapped?()
    startAnimation()
  }

  private func startAnimation() {
    infoView.isHidden = false
    infoView.alpha = 1
    view.backgroundColor = .init(red: 1, green: 1, blue: 1, alpha: 0.4)
    view.layer.cornerRadius = view.frame.height / 2
    for subView in arrowsContainer.arrangedSubviews {
      subView.alpha = 0
    }
    if isRewind {
      arrowsContainer.arrangedSubviews[arrowsContainer.arrangedSubviews.count - 1].alpha = 1
    } else {
      arrowsContainer.arrangedSubviews[0].alpha = 1
    }
    let enumeratedItems = isRewind ? arrowsContainer.subviews.reversed().enumerated() : arrowsContainer.subviews.enumerated()
    operationQueue = OperationQueue()
    operationQueue?.maxConcurrentOperationCount = 1
    for (index, item) in enumeratedItems {
      item.alpha = 0
      operationQueue?.addOperation {
        DispatchQueue.main.asyncAfter(deadline: .now() + (0.1 * Double(index))) {
          UIView.animate(withDuration: 0.2, delay: 0, options: .beginFromCurrentState) {
            item.alpha = 1
          }
        }
      }
    }

    active = true
    delaySetActive(false, timeInterval: 1)
    UIView.animate(withDuration: 1, delay: 0, options: .allowUserInteraction) {
      self.infoView.alpha = 0
      self.view.backgroundColor = .clear
    }
  }

  deinit {
    setActiveTimer?.invalidate()
  }
}
