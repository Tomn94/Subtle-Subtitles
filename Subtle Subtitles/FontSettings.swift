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
    
    @objc public static let settingsFontNameKey = "preferredFont"
    @objc public static let settingsFontColorKey = "preferredColor"
    @objc public static let settingsFontSizeKey = "defaultPointSize"  // !!!: Changing this needs changing registerDefaults in Data
    @objc public static let settingsFontSizeMin: Double = 10
    @objc public static let settingsFontSizeMax: Double = 200
    
    /// Available encodings
    var encodings: [(name: String, value: UInt)] = [
        ("Automatic Encoding".localized, 0),
        ("UTF-8".localized, String.Encoding.utf8.rawValue),
        ("Western (Latin-1/ISO 8859-1)".localized, String.Encoding.isoLatin1.rawValue),
        ("Central European (Latin-2/ISO 8859-2)".localized, String.Encoding.isoLatin2.rawValue),
        ("Central European (Windows 1250)".localized, String.Encoding.windowsCP1250.rawValue),
        ("Cyrillic (Windows 1251)".localized, String.Encoding.windowsCP1251.rawValue),
        ("Western (Windows 1252)".localized, String.Encoding.windowsCP1252.rawValue),
        ("Greek (Windows 1253)".localized, String.Encoding.windowsCP1253.rawValue),
        ("Turkish (Windows 1254)".localized, String.Encoding.windowsCP1254.rawValue),
        ("Japanese (EUC-JP)".localized, String.Encoding.japaneseEUC.rawValue),
        ("Japanese (Shift JIS)".localized, String.Encoding.shiftJIS.rawValue),
        ("Japanese (ISO 2022)".localized, String.Encoding.iso2022JP.rawValue),
        ("ASCII".localized, String.Encoding.ascii.rawValue),
        ("ASCII (Non-Lossy)".localized, String.Encoding.nonLossyASCII.rawValue),
        ("Unicode/UTF-16".localized, String.Encoding.unicode.rawValue),
        ("UTF-16 BE".localized, String.Encoding.utf16BigEndian.rawValue),
        ("UTF-16 LE".localized, String.Encoding.utf16LittleEndian.rawValue),
        ("UTF-32".localized, String.Encoding.utf32.rawValue),
        ("UTF-32 BE".localized, String.Encoding.utf32BigEndian.rawValue),
        ("UTF-32 LE".localized, String.Encoding.utf32LittleEndian.rawValue),
        ("Classic Mac OS".localized, String.Encoding.macOSRoman.rawValue),
        ("NEXTSTEP".localized, String.Encoding.nextstep.rawValue),
        ("Adobe Symbol".localized, String.Encoding.symbol.rawValue)
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
                UIKeyCommand(input: UIKeyInputRightArrow, modifierFlags: [], action: #selector(enterKey)),
                
                UIKeyCommand(input: "+", modifierFlags: [.command], action: #selector(zoomText(_:)),
                             discoverabilityTitle: "Enlarge Text Size".localized),
                UIKeyCommand(input: "-", modifierFlags: [.command], action: #selector(zoomText(_:)),
                             discoverabilityTitle: "Reduce Text Size".localized),
                
                UIKeyCommand(input: UIKeyInputEscape, modifierFlags: [], action: #selector(close),
                    discoverabilityTitle: "Dismiss Display Settings".localized)
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
        lastSel = encodings.index { $0.value == selectedLanguage } ?? 0
        
        /* Init view */
        let backView = UIView()
        backView.backgroundColor = UIColor(white: 0.23, alpha: 1)
        tableView.backgroundView = backView
        
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: Notification.Name(rawValue: "fontChanged"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: Notification.Name(rawValue: "colorChanged"), object: nil)
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
            if indexPath.row == 0 {
                identifier += "Menu"
            } else if indexPath.row == 1 {
                identifier += "Color"
            } else {
                identifier += "Size"
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
                let colorCell = cell as! FontColorCell
                colorCell.display(color: defaults.color(forKey: FontSettings.settingsFontColorKey))
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
            cell.accessoryType = encoding.value == UInt(defaults.integer(forKey: "preferredEncoding")) ? .checkmark : .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                self.performSegue(withIdentifier: "fontSettingsDetailSegue", sender: self)
            } else if indexPath.row == 1 {
                self.performSegue(withIdentifier: "colorSettingsDetailSegue", sender: self)
            }
        } else {
            /* Change checkmarks ✓ */
            tableView.cellForRow(at: IndexPath(row: lastSel, section: 1))?.accessoryType = .none
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
            lastSel = indexPath.row;
            
            /* Validate setting */
            let language = encodings[indexPath.row];
            UserDefaults.standard.setValue(language.value, forKey: "preferredEncoding")
            
            /* Apply on text */
            NotificationCenter.default.post(name: Notification.Name(rawValue: "updateEncoding"), object: nil)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    /// Reload font settings after change in sub-menus
    @objc func reload() {
        let currentKeyboardSelection = (tableView as! KBTableView).currentlyFocussedIndex
        self.tableView.reloadData()
        (tableView as! KBTableView).currentlyFocussedIndex = currentKeyboardSelection
    }
    
    // MARK: - Keyboard
    
    @objc func keyArrow(_ sender: UIKeyCommand) {
        let kbTableView = tableView as! KBTableView
        if sender.input == UIKeyInputUpArrow {
            kbTableView.upCommand()
        } else {
            kbTableView.downCommand()
        }
    }
    
    @objc func enterKey() {
        let kbTableView = tableView as! KBTableView
        kbTableView.returnCommand()
    }
    
    @IBAction func close() {
        dismiss(animated: true, completion: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "fontSettingsDismissed"), object: nil)
    }
    
    @objc func zoomText(_ sender: UIKeyCommand) {
        let stepperIndexPath = IndexPath(row: 2, section: 0)
        if let sizeCell = self.tableView(tableView, cellForRowAt: stepperIndexPath) as? FontSizeCell {
            sizeCell.stepper.value += sender.input == "-" ? -1 : 1
            sizeCell.updateLabel()
            self.tableView.reloadRows(at: [stepperIndexPath], with: .none)
        }
    }
    
}
