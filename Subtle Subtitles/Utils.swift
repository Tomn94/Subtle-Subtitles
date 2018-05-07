//
//  Utils.swift
//  Subtle Subtitles
//
//  Created by Thomas Naudet on 25/11/2016.
//  Copyright © 2016 Thomas Naudet. All rights reserved.
//  This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/
//

import UIKit

extension UINavigationController {
    @objc func popToRootViewController(completion: @escaping ()->()) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        self.popViewController(animated: true)
        CATransaction.commit()
    }
}

extension UserDefaults {
    
    /// Stored color or returns white
    @objc func color(forKey key: String) -> UIColor {
        var color = UIColor.white
        if let colorData = data(forKey: key) {
            color = NSKeyedUnarchiver.unarchiveObject(with: colorData) as? UIColor ?? color
        }
        return color
    }
    
    func set(_ color: UIColor?, forKey key: String) {
        var colorData: NSData?
        if let color = color {
            colorData = NSKeyedArchiver.archivedData(withRootObject: color) as NSData?
        }
        set(colorData, forKey: key)
    }
    
}

extension UIColor {
    var isTooBright: Bool {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let score = (r + g + b) / 3
        
        return score > (192 / 255)
    }
}

private let characterEntities: [String : Character] = [
    // XML predefined entities:
    "&quot;"    : "\"",
    "&amp;"     : "&",
    "&apos;"    : "'",
    "&lt;"      : "<",
    "&gt;"      : ">",
    
    // HTML character entity references:
    "&nbsp;"    : "\u{00a0}",
    "&iexcl;"   : "¡",
    "&pound;"   : "£",
    "&sect;"    : "§",
    "&copy;"    : "©",
    "&para;"    :  "¶",
    "&middot;"  : "·",
    "&laquo;"   : "«",
    "&iquest;"  : "¿",
    "&raquo;"   : "»",
    "&diams;"   : "♦"
]

extension NSString {
    
    func decodeNumeric(_ string : String, base : Int) -> Character? {
        guard let code = UInt32(string, radix: base),
              let uniScalar = UnicodeScalar(code) else {
                return nil
        }
        return Character(uniScalar)
    }
    
    func decode(_ entity: String) -> Character? {
        if entity.hasPrefix("&#x") || entity.hasPrefix("&#X"){
            return decodeNumeric(String(entity.suffix(from: entity.index(entity.startIndex, offsetBy: 3))), base: 16)
        } else if entity.hasPrefix("&#") {
            return decodeNumeric(String(entity.suffix(from: entity.index(entity.startIndex, offsetBy: 2))), base: 10)
        }
        return characterEntities[entity]
    }
    
    @objc func decodeEntities() -> NSString {
        var result = ""
        var position = 0
        var notFinished = true
        
        // Find the next '&' and copy the characters preceding it to `result`:
        while notFinished {
            let ampRange = self.range(of: "&", options: [], range: NSMakeRange(position, self.length - position))
            if ampRange.location == NSNotFound {
                notFinished = false
            } else {
                result = result.appending(self.substring(with: NSMakeRange(position, ampRange.location - position)))
                position = ampRange.location
                
                // Find the next ';' and copy everything from '&' to ';' into `entity`
                let semiRange = self.range(of: ";", options: [], range: NSMakeRange(position, self.length - position))
                if semiRange.location != NSNotFound {
                    let entity = self.substring(with: NSMakeRange(position, semiRange.location - position))
                    position = semiRange.location + 1
                    
                    if let decoded = decode(entity) {
                        // Replace by decoded character:
                        result.append(decoded)
                    } else {
                        // Invalid entity, copy verbatim:
                        result = result.appending(entity)
                    }
                } else {
                    // No matching ';'.
                    break
                }
            }
        }
        // Copy remaining characters to `result`:
        result = result.appending(self.substring(with: NSMakeRange(position, self.length - position)))
        return result as NSString
    }
}
