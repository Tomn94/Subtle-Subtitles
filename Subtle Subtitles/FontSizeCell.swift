//
//  FontSizeCell.swift
//  Subtle Subtitles
//
//  Created by Thomas Naudet on 26/11/2016.
//  Copyright © 2016 Thomas Naudet. All rights reserved.
//  This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/
//

import UIKit

class FontSizeCell: UITableViewCell {
    
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var sizeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if #available(iOS 9.0, *) {
            self.sizeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: self.sizeLabel.font.pointSize, weight: .regular)
        }
        self.stepper.addTarget(self, action: #selector(updateLabel), for: .valueChanged)
    }
    
    @objc func updateLabel() {
        /* Update label with new size */
        self.sizeLabel.text = String(Int(stepper.value)) + " pt"
        UserDefaults.standard.set(Float(stepper.value), forKey: FontSettings.settingsFontSizeKey)
        
        /* Apply on text */
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateDisplaySettings"), object: nil)
    }
    
}
