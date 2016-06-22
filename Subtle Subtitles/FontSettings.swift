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
    
    var encodings: [(name: String, value: NSStringEncoding)] = [
        ("UTF-8".localized, NSUTF8StringEncoding),
        ("Western (Latin-1/ISO 8859-1)".localized, NSISOLatin1StringEncoding),
        ("Central European (Latin-2/ISO 8859-2)".localized, NSISOLatin2StringEncoding),
        ("Central European (Windows 1250)".localized, NSWindowsCP1250StringEncoding),
        ("Cyrillic (Windows 1251)".localized, NSWindowsCP1251StringEncoding),
        ("Western (Windows 1252)".localized, NSWindowsCP1252StringEncoding),
        ("Greek (Windows 1253)".localized, NSWindowsCP1253StringEncoding),
        ("Turkish (Windows 1254)".localized, NSWindowsCP1254StringEncoding),
        ("Japanese (EUC-JP)".localized, NSJapaneseEUCStringEncoding),
        ("Japanese (Shift JIS)".localized, NSShiftJISStringEncoding),
        ("Japanese (ISO 2022)".localized, NSISO2022JPStringEncoding),
        ("ASCII".localized, NSASCIIStringEncoding),
        ("ASCII (Non-Lossy)".localized, NSNonLossyASCIIStringEncoding),
        ("Unicode/UTF-16".localized, NSUnicodeStringEncoding),
        ("UTF-16 BE".localized, NSUTF16BigEndianStringEncoding),
        ("UTF-16 LE".localized, NSUTF16LittleEndianStringEncoding),
        ("UTF-32".localized, NSUTF32StringEncoding),
        ("UTF-32 BE".localized, NSUTF32BigEndianStringEncoding),
        ("UTF-32 LE".localized, NSUTF32LittleEndianStringEncoding),
        ("Classic Mac OS".localized, NSMacOSRomanStringEncoding),
        ("NEXTSTEP".localized, NSNEXTSTEPStringEncoding),
        ("Adobe Symbol".localized, NSSymbolStringEncoding)
    ]
    var lastSel = 0
    
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
        
        title = "Encoding Settings".localized
        
        let betterTableView = tableView as! KBTableView
        betterTableView.onSelection = { indexPath in
            self.tableView(betterTableView, didSelectRowAtIndexPath: indexPath)
        }
        betterTableView.onFocus = { current, previous in
            if let previous = previous {
                betterTableView.deselectRowAtIndexPath(previous, animated: false)
            }
            if let current = current {
                betterTableView.selectRowAtIndexPath(current, animated: false, scrollPosition: .Middle)
            }
        }
        
        let selectedLanguage = UInt(NSUserDefaults.standardUserDefaults().integerForKey("preferredEncoding"))
        lastSel = encodings.indexOf({ (element) -> Bool in
            element.value == selectedLanguage
        }) ?? 0
        
        let backView = UIView()
        backView.backgroundColor = UIColor(white: 0.2, alpha: 1)
        tableView.backgroundView = backView
        tableView.separatorColor = UIColor.darkGrayColor()
        tableView.tintColor      = UIColor.lightGrayColor()
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "fontSettingsCell")
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let indexPath = NSIndexPath(forRow: lastSel, inSection: 0)
        (tableView as! KBTableView).currentlyFocussedIndex = indexPath
        tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Middle, animated: true)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return encodings.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Tip: Pinch to change the text size of the subtitles".localized
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let tableViewHeaderFooterView = view as? UITableViewHeaderFooterView {
            tableViewHeaderFooterView.textLabel?.text = self.tableView(tableView, titleForHeaderInSection: section)
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("fontSettingsCell", forIndexPath: indexPath)
        
        cell.backgroundColor = UIColor(white:0.2, alpha:1) // iPad fix
        cell.selectedBackgroundView = UIView(frame: cell.bounds)
        cell.selectedBackgroundView!.backgroundColor = UIColor.darkGrayColor()
        cell.textLabel!.textColor = UIColor.whiteColor()
        cell.textLabel!.text = encodings[indexPath.row].name.localized
        
        let defaults = NSUserDefaults.standardUserDefaults()
        cell.accessoryType = encodings[indexPath.row].value == UInt(defaults.integerForKey("preferredEncoding")) ? .Checkmark : .None
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.cellForRowAtIndexPath(NSIndexPath(forRow: lastSel, inSection: 0))?.accessoryType = .None
        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = .Checkmark
        lastSel = indexPath.row;
        
        let language = encodings[indexPath.row];
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setValue(language.value, forKey: "preferredEncoding")
        defaults.synchronize()
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        NSNotificationCenter.defaultCenter().postNotificationName("updateEncoding", object: nil)
        close()
    }
    
    // MARK: - Keyboard
    
    func keyArrow(sender: UIKeyCommand) {
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
        dismissViewControllerAnimated(true, completion: nil)
    }
    
}