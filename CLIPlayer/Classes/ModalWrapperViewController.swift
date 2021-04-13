//
//  ModalWrapperViewController.swift
//  CLIPlayer
//
//  Created by EA on 14/04/2021.
//

import UIKit

class ModalWrapperViewController: UIViewController {
  @IBOutlet weak var stackView: UIStackView!

  public class func instance() -> ModalWrapperViewController {
    let controller = UIStoryboard.cliPlayerStoryboard.instantiateViewController(withIdentifier: String(describing: Self.self)) as! ModalWrapperViewController
    controller.modalPresentationStyle = .overCurrentContext
    controller.modalTransitionStyle = .crossDissolve
    return controller
  }

  func addViewController(_ viewController: UIViewController) {
    addChild(viewController)
    _ = view
    _ = viewController.view
    stackView.addArrangedSubview(viewController.view)
    viewController.didMove(toParent: self)
  }

  @IBAction func viewOutsideDidTapped(_ sender: Any) {
    closeModal()
  }

  func closeModal() {
    dismiss(animated: true, completion: nil)
  }

}
