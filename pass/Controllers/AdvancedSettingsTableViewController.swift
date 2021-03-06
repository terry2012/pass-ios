//
//  AdvancedSettingsTableViewController.swift
//  pass
//
//  Created by Mingshen Sun on 7/2/2017.
//  Copyright © 2017 Bob Sun. All rights reserved.
//

import UIKit
import SVProgressHUD

class AdvancedSettingsTableViewController: UITableViewController {

    @IBOutlet weak var eraseDataTableViewCell: UITableViewCell!
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.cellForRow(at: indexPath) == eraseDataTableViewCell {
            print("erase data")
            let alert = UIAlertController(title: "Erase Password Store Data?", message: "This will delete all local data and settings. Password store data on your remote server will not be affected.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Erase Password Data", style: UIAlertActionStyle.destructive, handler: {[unowned self] (action) -> Void in
                SVProgressHUD.show(withStatus: "Erasing ...")
                DispatchQueue.global(qos: .userInitiated).sync {
                    PasswordStore.shared.erase()
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(Notification(name: Notification.Name("passwordStoreErased")))
                        self.navigationController!.popViewController(animated: true)
                        SVProgressHUD.showSuccess(withStatus: "Done")
                        SVProgressHUD.dismiss(withDelay: 1)
                    }
                }
            }))
            alert.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.cancel, handler:nil))
            self.present(alert, animated: true, completion: nil)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

}
