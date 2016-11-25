//
//  FontSettings.swift
//  Subtle Subtitles
//
//  Created by Thomas Naudet on 19/06/2016.
//  Copyright © 2016 Thomas Naudet. All rights reserved.
//  This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/
//

import UIKit

class FontSettings: UITableViewController {
    
    public static let settingsFontNameKey = "preferredFont"
    public static let settingsFontColorKey = "preferredColor"
    public static let settingsFontSizeKey = "defaultPointSize"  // !!!: Changing this needs changing registerDefaults in Data
    public static let settingsFontSizeMin: Double = 10
    public static let settingsFontSizeMax: Double = 200
    
    /// Available encodings
    var encodings: [(name: String, value: String.Encoding)] = [
        ("UTF-8".localized, String.Encoding.utf8),
        ("Western (Latin-1/ISO 8859-1)".localized, .isoLatin1),
        ("Central European (Latin-2/ISO 8859-2)".localized, .isoLatin2),
        ("Central European (Windows 1250)".localized, .windowsCP1250),
        ("Cyrillic (Windows 1251)".localized, .windowsCP1251),
        ("Western (Windows 1252)".localized, .windowsCP1252),
        ("Greek (Windows 1253)".localized, .windowsCP1253),
        ("Turkish (Windows 1254)".localized, .windowsCP1254),
        ("Japanese (EUC-JP)".localized, .japaneseEUC),
        ("Japanese (Shift JIS)".localized, .shiftJIS),
        ("Japanese (ISO 2022)".localized, .iso2022JP),
        ("ASCII".localized, .ascii),
        ("ASCII (Non-Lossy)".localized, .nonLossyASCII),
        ("Unicode/UTF-16".localized, .unicode),
        ("UTF-16 BE".localized, .utf16BigEndian),
        ("UTF-16 LE".localized, .utf16LittleEndian),
        ("UTF-32".localized, .utf32),
        ("UTF-32 BE".localized, .utf32BigEndian),
        ("UTF-32 LE".localized, .utf32LittleEndian),
        ("Classic Mac OS".localized, .macOSRoman),
        ("NEXTSTEP".localized, .nextstep),
        ("Adobe Symbol".localized, .symbol)
    ]
    var lastSel = 0
    
    /// Set iPad keyboard shortcuts
    override var keyCommands: [UIKeyCommand]? {
        if #available(iOS 9, *) {
            return [
                UIKeyCommand(input: UIKeyInputUpArrow, modifierFlags: [], action: #selector(keyArrow(_:)),
                    discoverabilityTitle: "Select Previous Encoding".localized),
                
                UIKeyCommand(input: UIKeyInputDownArrow, modifierFlags: [], action: #selector(keyArrow(_:)),
                    discoverabilityTitle: "Select Next Encoding".localized),
                
                UIKeyCommand(input: "\r", modifierFlags: [], action: #selector(enterKey),
                    discoverabilityTitle: "Choose Encoding".localized),
                
                UIKeyCommand(input: UIKeyInputEscape, modifierFlags: [], action: #selector(close),
                    discoverabilityTitle: "Dismiss".localized)
            ]
        } else {
            return []
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Text Settings Title".localized
        
        /* Init shortcuts */
        let betterTableView = tableView as! KBTableView
        betterTableView.onSelection = { (indexPath: IndexPath) in
            self.tableView(betterTableView, didSelectRowAt: indexPath)
        }
        betterTableView.onFocus = { (current: IndexPath?, previous: IndexPath?) in
            if let previous = previous {
                betterTableView.deselectRow(at: previous, animated: false)
            }
            if let current = current {
                betterTableView.selectRow(at: current, animated: false, scrollPosition: .middle)
            }
        }
        
        /* Init selected encoding with saved value */
        let selectedLanguage = UInt(UserDefaults.standard.integer(forKey: "preferredEncoding"))
        lastSel = encodings.index { $0.value.rawValue == selectedLanguage } ?? 0
        
        /* Init view */
        let backView = UIView()
        backView.backgroundColor = UIColor(white: 0.23, alpha: 1)
        tableView.backgroundView = backView
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let indexPath = IndexPath(row: lastSel, section: 0)
        (tableView as! KBTableView).currentlyFocussedIndex = indexPath
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 3
        }
        return encodings.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Text Section Title".localized
        }
        return "Encoding Section Title".localized
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return "Tip: Pinch to change the text size of the subtitles".localized
        }
        return nil
    }
    
    
    /// Set tableView content
    ///   Section 1: Font, Color, Size
    ///   Section 2: Encodings
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        /* BASIC SETUP */
        var identifier = "fontSettingsCell"
        if indexPath.section == 0 {
            if indexPath.row == 2 {
                identifier += "Size"
            } else {
                identifier += "Menu"
            }
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        let defaults = UserDefaults.standard
        
        cell.backgroundColor = UIColor(white:0.2, alpha:1) // iPad fix
        cell.selectedBackgroundView = UIView(frame: cell.bounds)
        cell.selectedBackgroundView!.backgroundColor = UIColor.darkGray
        cell.textLabel!.textColor = UIColor.white
        
        /* ADEQUATE SETUP */
        /* Text */
        if indexPath.section == 0 {
            /* Font */
            if indexPath.row == 0 {
                cell.textLabel?.text = "Font menu".localized
                if let preferredFont = defaults.string(forKey: FontSettings.settingsFontNameKey) {
                    cell.detailTextLabel?.text = preferredFont
                } else {
                    cell.detailTextLabel?.text = "Default font".localized;
                }
            }
            /* Color */
            else if indexPath.row == 1 {
                cell.textLabel?.text = "Color menu".localized
                cell.detailTextLabel?.text = defaults.string(forKey: "preferredColor")
            }
            /* Size */
            else {
                let sizeCell = cell as! FontSizeCell
                sizeCell.stepper.maximumValue = FontSettings.settingsFontSizeMax
                sizeCell.stepper.value = round(Double(UserDefaults.standard.float(forKey: FontSettings.settingsFontSizeKey)))
                sizeCell.stepper.minimumValue = FontSettings.settingsFontSizeMin
                sizeCell.updateLabel()
            }
        }
        /* Encodings */
        else {
            // Display each name and check the selected
            let encoding = encodings[indexPath.row]
            cell.textLabel?.text = encoding.name.localized
            cell.accessoryType = encoding.value.rawValue == UInt(defaults.integer(forKey: "preferredEncoding")) ? .checkmark : .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                self.performSegue(withIdentifier: "fontSettingsDetailSegue", sender: self)
            } else if indexPath.row == 2 {
                
            }
        } else {
            /* Change checkmarks ✓ */
            tableView.cellForRow(at: IndexPath(row: lastSel, section: 0))?.accessoryType = .none
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
            lastSel = indexPath.row;
            
            /* Validate setting */
            let language = encodings[indexPath.row];
            let defaults = UserDefaults.standard
            defaults.setValue(language.value.rawValue, forKey: "preferredEncoding")
            
            /* Apply on text */
            NotificationCenter.default.post(name: Notification.Name(rawValue: "updateEncoding"), object: nil)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Keyboard
    
    func keyArrow(_ sender: UIKeyCommand) {
        let kbTableView = tableView as! KBTableView
        if sender.input == UIKeyInputUpArrow {
            kbTableView.upCommand()
        } else {
            kbTableView.downCommand()
        }
    }
    
    func enterKey() {
        let kbTableView = tableView as! KBTableView
        kbTableView.returnCommand()
    }
    
    @IBAction func close() {
        dismiss(animated: true, completion: nil)
    }
    
}
