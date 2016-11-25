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
    let minTimeAskLang: TimeInterval = 30
    var lastAskLang: TimeInterval = 0
    
    override var keyCommands: [UIKeyCommand]? {
        if #available(iOS 9, *) {
            return [
                UIKeyCommand(input: UIKeyInputUpArrow, modifierFlags: [], action: #selector(keyArrow(_:)),
                    discoverabilityTitle: "Select Previous Language".localized),
                
                UIKeyCommand(input: UIKeyInputDownArrow, modifierFlags: [], action: #selector(keyArrow(_:)),
                    discoverabilityTitle: "Select Next Language".localized),
                
                UIKeyCommand(input: "\r", modifierFlags: [], action: #selector(enterKey),
                             discoverabilityTitle: "Choose Language".localized),
                UIKeyCommand(input: UIKeyInputRightArrow, modifierFlags: [], action: #selector(enterKey)),
                
                UIKeyCommand(input: UIKeyInputLeftArrow, modifierFlags: [.command], action: #selector(back),
                    discoverabilityTitle: "Back to Settings".localized),
                UIKeyCommand(input: ",", modifierFlags: [.command], action: #selector(back)),
                
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
            self.tableView(betterTableView, didSelectRowAt: indexPath as IndexPath)
        }
        betterTableView.onFocus = { current, previous in
            if let previous = previous {
                betterTableView.deselectRow(at: previous as IndexPath, animated: false)
            }
            if let current = current {
                betterTableView.selectRow(at: current as IndexPath, animated: false, scrollPosition: .middle)
            }
        }
        tableView = betterTableView
        
        let backView = UIView()
        backView.backgroundColor = UIColor(white: 0.2, alpha: 1)
        tableView.backgroundView = backView
        tableView.separatorColor = .darkGray
//        tableView.tintColor      = .lightGray
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshLangs))
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "langageSettingsCell")
        
        let defaults = UserDefaults.standard
        languages = [(id: defaults.string(forKey: "langID")!, name: defaults.string(forKey: "langName")!)]
        loadLanguages()
        
        NotificationCenter.default.addObserver(self, selector: #selector(loadLanguages),
                                                         name: NSNotification.Name(rawValue: "updateLangages"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let indexPath = IndexPath(row: lastSel, section: 0)
        (tableView as! KBTableView).currentlyFocussedIndex = indexPath
        tableView.scrollToRow(at: indexPath, at: .middle, animated: false)
    }
    
    func loadLanguages() {
        if let languagesNames = Data.shared().langNames,
            let languagesIDs  = Data.shared().langIDs {
            let langs: [(id: String, name: String)] = Array(zip(languagesIDs as! [String], languagesNames as! [String]))
            
            languages = langs.sorted(by: { (first, second) -> Bool in
                return first.name.localized.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
            })
            
            let selectedLanguage = UserDefaults.standard.string(forKey: "langID")
            lastSel = languages.index(where: { (element) -> Bool in
                element.id == selectedLanguage
            }) ?? 0
            
            tableView.reloadData()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return languages.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let langNames = Data.shared().langNames, langNames.count > 0 {
            return nil
        }
        return "Second Search Language Empty".localized
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "langageSettingsCell", for: indexPath)
        
        cell.backgroundColor = UIColor(white:0.2, alpha:1) // iPad fix
        cell.selectedBackgroundView = UIView(frame: cell.bounds)
        cell.selectedBackgroundView!.backgroundColor = UIColor.darkGray
        cell.textLabel!.textColor = UIColor.white
        cell.textLabel!.text = languages[indexPath.row].name.localized
        
        let defaults = UserDefaults.standard
        cell.accessoryType = languages[indexPath.row].id == defaults.string(forKey: "langID") ? .checkmark : .none

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: IndexPath(row: lastSel, section: 0))?.accessoryType = .none
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        lastSel = indexPath.row;
        
        let language = languages[indexPath.row];
        let defaults = UserDefaults.standard
        defaults.setValue(language.id,   forKey: "langID")
        defaults.setValue(language.name, forKey: "langName")
        defaults.synchronize()
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateLanguage"), object: nil)
    }
    
    func refreshLangs() {
        let currentTime = Date.timeIntervalSinceReferenceDate
        if currentTime - lastAskLang > minTimeAskLang {
            if let downloader = Data.shared().downloader {
                Data.shared().openSubtitlerDidLog(in: downloader)
            }
            lastAskLang = currentTime
        }
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
    
    func back() {
        if let nav = self.navigationController {
            nav.popViewController(animated: true)
        }
    }
    
    func close() {
        dismiss(animated: true, completion: nil)
    }

}
