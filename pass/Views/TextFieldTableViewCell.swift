//
//  TextFieldTableViewCell.swift
//  pass
//
//  Created by Mingshen Sun on 10/2/2017.
//  Copyright © 2017 Bob Sun. All rights reserved.
//

import UIKit

class TextFieldTableViewCell: UITableViewCell {

    @IBOutlet weak var contentTextField: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
