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
  var config: SelectorModalConfig! {
    didSet {
      applyConfig()
    }
  }
  
  public class func instance() -> SelectorModalViewController {
    let storyboard = UIStoryboard(name: "CLIPlayer", bundle: Bundle.cliPlayerBundle)
    let controller = storyboard.instantiateViewController(withIdentifier: String(describing: Self.self)) as! SelectorModalViewController
    controller.modalPresentationStyle = .overCurrentContext
    controller.modalTransitionStyle = .crossDissolve
    return controller
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    titleLabel.text = title
    tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 1))
    tableView.tableFooterView?.backgroundColor = .clear
    if config == nil {
      config = SelectorModalConfig()
    }
  }
  
  func applyConfig() {
    titleLabel.font = config.titleFont
  }
  
  @IBAction func viewOutsideDidTapped(_ sender: Any) {
    closeModal()
  }
  
  func closeModal() {
    dismiss(animated: true, completion: nil)
  }
}

extension SelectorModalViewController: UITableViewDelegate, UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int { 1 }
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 44 }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "SelectorCell") ?? UITableViewCell()
    let item = items[indexPath.row]
    cell.textLabel?.text = item.title
    cell.textLabel?.font = config.itemFont
    cell.accessoryType = item.selected ? .checkmark : .none
    
    return cell
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let item = items[indexPath.row]
    item.handler(item)
    closeModal()
  }
}
