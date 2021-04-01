//
//  SelectorModalViewController.swift
//  CLIPlayer
//
//  Created by admin on 01/04/2021.
//

import UIKit

struct SelectorModalItem {
  var title: String?
  var selected = false
  var handler: (SelectorModalItem) -> Void
}

class SelectorModalViewController: UIViewController {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var tableView: UITableView!
  var items: [SelectorModalItem] = []
  var isPresenting = false

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  convenience init() {
    self.init(nibName: String(describing: Self.self), bundle: Bundle(for: Self.self))
    modalPresentationStyle = .overCurrentContext
//    transitioningDelegate = self
  }

  override func viewDidLoad() {
    super.viewDidLoad()
//    tableView.reloadData()
    titleLabel.text = title
    tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))
    tableView.tableFooterView?.backgroundColor = .clear
  }

  @IBAction func viewOutsideDidTapped(_ sender: Any) {
    closeModal()
  }

  @IBAction func closeButtonTapped(_ sender: Any) {
    closeModal()
  }

  func closeModal() {
    dismiss(animated: true, completion: nil)
  }
}

extension SelectorModalViewController: UITableViewDelegate, UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int { 1 }
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell()
    cell.backgroundColor = .darkGray
    let item = items[indexPath.row]
    cell.textLabel?.text = item.title
    cell.textLabel?.textColor = .white
    cell.tintColor = .white
    if item.selected {
      cell.accessoryType = .checkmark
    }

    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let item = items[indexPath.row]
    item.handler(item)
    closeModal()
  }
}
