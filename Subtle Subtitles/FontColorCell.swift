//
//  FontColorCell.swift
//  Subtle Subtitles
//
//  Created by Thomas Naudet on 26/11/2016.
//  Copyright © 2016 Thomas Naudet. All rights reserved.
//  This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/
//

import UIKit

class FontColorCell: UITableViewCell {

    @IBOutlet weak var colorWell: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        colorWell.layer.cornerRadius = 3
    }
    
    /// Avoid selection to clear color well background color
    override func setSelected(_ selected: Bool, animated: Bool) {
        let backgroundColor = colorWell.backgroundColor ?? .white
        
        super.setSelected(selected, animated: animated)
        
        display(color: backgroundColor)
    }
    
    /// Avoid keyboard selection to clear color well background color
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        let backgroundColor = colorWell.backgroundColor ?? .white
        
        super.setHighlighted(highlighted, animated: animated)
        
        display(color: backgroundColor)
    }
    
    /// Change color well color
    func display(color: UIColor) {
        colorWell.backgroundColor = color
    }
}
