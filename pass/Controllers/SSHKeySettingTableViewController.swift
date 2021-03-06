//
//  SSHKeySettingTableViewController.swift
//  pass
//
//  Created by Mingshen Sun on 25/1/2017.
//  Copyright © 2017 Bob Sun. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

class SSHKeySettingTableViewController: UITableViewController {

    @IBOutlet weak var passphraseTextField: UITextField!
    @IBOutlet weak var privateKeyURLTextField: UITextField!
    @IBOutlet weak var publicKeyURLTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        passphraseTextField.text = Defaults[.gitRepositorySSHPrivateKeyPassphrase]
        privateKeyURLTextField.text = Defaults[.gitRepositorySSHPrivateKeyURL]?.absoluteString
        publicKeyURLTextField.text = Defaults[.gitRepositorySSHPublicKeyURL]?.absoluteString
        var doneBarButtonItem: UIBarButtonItem?

        doneBarButtonItem = UIBarButtonItem(title: "Done",
                                            style: UIBarButtonItemStyle.done,
                                            target: self,
                                            action: #selector(doneButtonTapped(_:)))
        navigationItem.rightBarButtonItem = doneBarButtonItem
        navigationItem.title = "SSH Key"
    }
    
    func doneButtonTapped(_ sender: UIButton) {
        Defaults[.gitRepositorySSHPublicKeyURL] = URL(string: publicKeyURLTextField.text!)
        Defaults[.gitRepositorySSHPrivateKeyURL] = URL(string: privateKeyURLTextField.text!)
        Defaults[.gitRepositorySSHPrivateKeyPassphrase] = passphraseTextField.text!
        
        do {
            try Data(contentsOf: Defaults[.gitRepositorySSHPublicKeyURL]!).write(to: Globals.sshPublicKeyURL, options: .atomic)
            try Data(contentsOf: Defaults[.gitRepositorySSHPrivateKeyURL]!).write(to: Globals.sshPrivateKeyURL, options: .atomic)
        } catch {
            print(error)
        }

        navigationController!.popViewController(animated: true)
    }

}
