//
//  LanguagesTable.swift
//  Subtle Subtitles
//
//  Created by Thomas Naudet on 11/06/2016.
//  Copyright © 2016 Thomas Naudet. All rights reserved.
//  This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/
//

import UIKit

class LanguagesTable: UITableViewController {
    
    var languages: [(id: String, name: String)] = []
    var lastSel = 0
    let minTimeAskLang: NSTimeInterval = 30
    var lastAskLang: NSTimeInterval = 0
    
    override var keyCommands: [UIKeyCommand]? {
        if #available(iOS 9, *) {
            return [
                UIKeyCommand(input: UIKeyInputUpArrow, modifierFlags: [], action: #selector(keyArrow(_:)),
                    discoverabilityTitle: "Select Previous Language".localized),
                
                UIKeyCommand(input: UIKeyInputDownArrow, modifierFlags: [], action: #selector(keyArrow(_:)),
                    discoverabilityTitle: "Select Next Language".localized),
                
                UIKeyCommand(input: "\r", modifierFlags: [], action: #selector(enterKey),
                    discoverabilityTitle: "Choose Language".localized),
                
                UIKeyCommand(input: UIKeyInputLeftArrow, modifierFlags: [.Command], action: #selector(back),
                    discoverabilityTitle: "Back to Settings".localized),
                UIKeyCommand(input: ",", modifierFlags: [.Command], action: #selector(back)),
                
                UIKeyCommand(input: UIKeyInputEscape, modifierFlags: [], action: #selector(close),
                    discoverabilityTitle: "Dismiss Languages".localized)
            ]
        } else {
            return []
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Second Search Language".localized
        
        let betterTableView = KBTableView(frame: tableView.frame, style: tableView.style)
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
        tableView = betterTableView
        
        let backView = UIView()
        backView.backgroundColor = UIColor(white: 0.2, alpha: 1)
        tableView.backgroundView = backView
        tableView.separatorColor = .darkGrayColor()
        tableView.tintColor      = .lightGrayColor()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: #selector(refreshLangs))
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "langageSettingsCell")
        
        let defaults = NSUserDefaults.standardUserDefaults()
        languages = [(id: defaults.stringForKey("langID")!, name: defaults.stringForKey("langName")!)]
        loadLanguages()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(loadLanguages),
                                                         name: "updateLangages", object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let indexPath = NSIndexPath(forRow: lastSel, inSection: 0)
        (tableView as! KBTableView).currentlyFocussedIndex = indexPath
        tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Middle, animated: true)
    }
    
    func loadLanguages() {
        if let languagesNames = Data.sharedData().langNames,
            let languagesIDs  = Data.sharedData().langIDs {
            let langs: [(id: String, name: String)] = Array(Zip2Sequence(languagesIDs as! [String], languagesNames as! [String]))
            
            languages = langs.sort({ (first, second) -> Bool in
                return first.name.localized.localizedCaseInsensitiveCompare(second.name) == .OrderedAscending
            })
            
            let selectedLanguage = NSUserDefaults.standardUserDefaults().stringForKey("langID")
            lastSel = languages.indexOf({ (element) -> Bool in
                element.id == selectedLanguage
            }) ?? 0
            
            tableView.reloadData()
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return languages.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let langNames = Data.sharedData().langNames where langNames.count > 0 {
            return nil
        }
        return "Second Search Language Empty".localized
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("langageSettingsCell", forIndexPath: indexPath)
        
        cell.backgroundColor = UIColor(white:0.2, alpha:1) // iPad fix
        cell.selectedBackgroundView = UIView(frame: cell.bounds)
        cell.selectedBackgroundView!.backgroundColor = UIColor.darkGrayColor()
        cell.textLabel!.textColor = UIColor.whiteColor()
        cell.textLabel!.text = languages[indexPath.row].name.localized
        
        let defaults = NSUserDefaults.standardUserDefaults()
        cell.accessoryType = languages[indexPath.row].id == defaults.stringForKey("langID") ? .Checkmark : .None

        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.cellForRowAtIndexPath(NSIndexPath(forRow: lastSel, inSection: 0))?.accessoryType = .None
        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = .Checkmark
        lastSel = indexPath.row;
        
        let language = languages[indexPath.row];
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setValue(language.id,   forKey: "langID")
        defaults.setValue(language.name, forKey: "langName")
        defaults.synchronize()
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        NSNotificationCenter.defaultCenter().postNotificationName("updateLanguage", object: nil)
    }
    
    func refreshLangs() {
        let currentTime = NSDate.timeIntervalSinceReferenceDate()
        if currentTime - lastAskLang > minTimeAskLang {
            if let downloader = Data.sharedData().downloader {
                Data.sharedData().openSubtitlerDidLogIn(downloader)
            }
            lastAskLang = currentTime
        }
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
    
    func back() {
        navigationController?.popViewControllerAnimated(true)
    }
    
    func close() {
        dismissViewControllerAnimated(true, completion: nil)
    }

}
