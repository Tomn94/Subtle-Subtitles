//
//  SuggestionsTable.swift
//  Subtle Subtitles
//
//  Created by Thomas Naudet on 31/05/2016.
//  Copyright © 2016 Thomas Naudet. All rights reserved.
//  This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/
//

import UIKit

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}

extension NSString {
    @objc func increaseNumber(_ season: Bool) -> NSString {
        if self == "" {
            Data.feedback(afterAction: .error)
            return self;
        }
        do {
            defer {
                Data.feedback(afterAction: .success)
            }
            
            let regexS = try NSRegularExpression(pattern: "S[0-9]{1,2}", options: [.caseInsensitive])
            let regexE = try NSRegularExpression(pattern: "E[0-9]{1,2}", options: [.caseInsensitive])
            
            let regex = season ? regexS : regexE;
            let cc = self.length
            
            var range = regex.rangeOfFirstMatch(in: self as String, options: [], range: NSRange(location: 0, length: cc))
            if range.location == NSNotFound || range.location + 1 >= cc { // Pas trouvé
                if season {     // Si bouton S+1
                    // Si on a au moins l'épisode
                    range = regexE.rangeOfFirstMatch(in: self as String, options: [], range: NSRange(location: 0, length: cc))
                    if range.location != NSNotFound && range.location + 1 < cc {
                        // On rajoute la saison 1
                        let result = (self as NSString).substring(with: range)
                        return regexE.stringByReplacingMatches(in: self as String, options: [],
                                                                       range: NSRange(location: 0, length: cc),
                                                                       withTemplate: "S01" + result) as NSString
                    }
                } else {        // Si bouton E+1
                    // Si on a au moins la saison
                    range = regexS.rangeOfFirstMatch(in: self as String, options: [], range:NSRange(location: 0, length: cc))
                    if range.location != NSNotFound && range.location + 1 < cc {
                        // On rajoute l'épisode 1
                        let result = (self as NSString).substring(with: range)
                        return regexS.stringByReplacingMatches(in: self as String, options: [],
                                                                       range:NSRange(location: 0, length: cc),
                                                                       withTemplate: result + "E01") as NSString
                    }
                }
                
                var res = self
                // S'il n'y a ni Sxx ni Exx
                if !hasSuffix(" ") {
                    res = res.appending(" ") as NSString
                }
                res = res.appending("S01E01") as NSString
                return res
            } else {
                let result = (self as NSString).substring(with: NSRange(location: range.location + 1, length: range.length - 1))
                var intVal = Int(result) ?? 0
                if intVal < 99 {
                    intVal += 1
                }
                
                let letter = season ? "S" : "E"
                return regex.stringByReplacingMatches(in: self as String, options: [], range:NSRange(location: 0, length: cc),
                                                              withTemplate: String(format: "%@%02d", letter, intVal)) as NSString
            }
        } catch {}
        return self
    }
}


@objc
class SuggestionsTable: UITableViewController {
    
    @objc var suggestions: [String] = []
    @objc var searchController: UISearchController?
    @objc var searchBar: UISearchBar?
    
    override var keyCommands: [UIKeyCommand]? {
        if #available(iOS 9.0, *) {
            return [
                UIKeyCommand(input: "\r", modifierFlags: [], action: #selector(search(_:)),
                    discoverabilityTitle: "Search".localized),
                UIKeyCommand(input: "\r", modifierFlags: [.shift], action: #selector(search(_:)),
                    discoverabilityTitle: "Search English Subtitles".localized),
                UIKeyCommand(input: "\r", modifierFlags: [.alternate], action: #selector(search(_:)),
                    discoverabilityTitle: "Search using Second Language".localized),
                
                UIKeyCommand(input: "f", modifierFlags: [.command, .shift], action: #selector(switchLang(_:)),
                    discoverabilityTitle: "Switch to English".localized),
                UIKeyCommand(input: "f", modifierFlags: [.command, .alternate], action: #selector(switchLang(_:)),
                    discoverabilityTitle: "Switch to Second Language".localized),
                
                UIKeyCommand(input: "s", modifierFlags: [.command], action: #selector(increase(_:)),
                discoverabilityTitle: "Increase Season number".localized),
                UIKeyCommand(input: "e", modifierFlags: [.command], action: #selector(increase(_:)),
                    discoverabilityTitle: "Increase Episode number".localized),
                
                UIKeyCommand(input: UIKeyInputUpArrow, modifierFlags: [], action: #selector(keyArrow(_:)),
                    discoverabilityTitle: "Select Previous Suggestion".localized),
                
                UIKeyCommand(input: UIKeyInputDownArrow, modifierFlags: [], action: #selector(keyArrow(_:)),
                    discoverabilityTitle: "Select Next Suggestion".localized),
                
                UIKeyCommand(input: "\r", modifierFlags: [.command], action: #selector(enterKey)),
                UIKeyCommand(input: UIKeyInputRightArrow, modifierFlags: [], action: #selector(enterKey),
                             discoverabilityTitle: "Choose Suggestion".localized),
                
                UIKeyCommand(input: "f", modifierFlags: [.command], action: #selector(exit)),
                UIKeyCommand(input: UIKeyInputEscape, modifierFlags: [], action: #selector(exit),
                    discoverabilityTitle: "Exit Search".localized)
            ]
        } else {
            return []
        }
    }
    
    @objc class func simplerQuery(_ query: String) -> String {
        do {
            let regex = try NSRegularExpression(pattern: "S\\d{1,2}E\\d{1,2}", options: [.caseInsensitive])
            let res = regex.stringByReplacingMatches(in: query, options: [],
                                                             range: NSRange(location: 0, length: query.count),
                                                             withTemplate: "")
            return res.trimmingCharacters(in: .whitespaces)
            
        } catch {}
        return query;
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "suggestCell")
    }
    
    @objc func exit() {
        if let sb = searchBar, sb.isFirstResponder {
            sb.resignFirstResponder()
        } else if let sc = searchController {
            sc.isActive = false
        }
    }
    
    @objc func switchLang(_ sender: UIKeyCommand) {
        if let sb = searchBar {
            sb.selectedScopeButtonIndex = (sender.modifierFlags == [.command, .alternate]) ? 1 : 0
        }
    }
    
    @objc func increase(_ sender: UIKeyCommand) {
        if let sb = searchBar {
            let txt = sb.text! as NSString
            sb.text = txt.increaseNumber(sender.input == "s") as String
        }
    }
    
    @objc func search(_ sender: UIKeyCommand) {
        if let sb = searchBar {
            if sender.modifierFlags == [.shift] {
                sb.selectedScopeButtonIndex = 0
            } else if sender.modifierFlags == [.alternate] {
                sb.selectedScopeButtonIndex = 1
            }
            
            if let d = sb.delegate {
                d.searchBarSearchButtonClicked!(sb)
            }
        }
    }
    
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if UIDevice.current.userInterfaceIdiom == .phone {
            if let sb = searchBar {
                let statusBar: CGFloat = UIApplication.shared.statusBarFrame.size.height
                tableView.contentInset = UIEdgeInsets(top: sb.frame.size.height + statusBar, left: 0, bottom: 0, right: 0)
                automaticallyAdjustsScrollViewInsets = false
            }
        }
    }
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if let sb = searchBar {
            sb.resignFirstResponder()
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return suggestions.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // Aucune recherche précédemment stockée
        if let previous = UserDefaults.standard.object(forKey: "previousSearches"), (previous as AnyObject).count == 0 {
            return "No Previous Searches".localized
        }
        // Recherches stockées
        if suggestions.count > 0 {
            if let sb = searchBar,
                let txt = sb.text {
                if SuggestionsTable.simplerQuery(txt).isEmpty {
                    return "Previous Searches".localized      // Champ vide = liste complète
                }
                return "Previous Searches Matching".localized // Champ plein = correspondances
            }
        }
        // Aucune correspondance
        return "No Previous Matching".localized
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "suggestCell", for: indexPath)
        
        cell.textLabel?.text = suggestions[indexPath.row].capitalized
        cell.textLabel?.textColor = .lightGray
        cell.backgroundColor = UIColor(white: 0.2, alpha: 1)
        cell.selectedBackgroundView = UIView(frame: cell.bounds)
        cell.selectedBackgroundView!.backgroundColor = .darkGray
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        searchBar?.text = suggestions[indexPath.row].capitalized + " "
        searchBar?.becomeFirstResponder()
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let defaults = UserDefaults.standard;
            if var previous = defaults.object(forKey: "previousSearches") as? [String] {
                if let index = previous.index(of: suggestions[indexPath.row]) {
                    previous.remove(at: index)
                    defaults.set(previous, forKey: "previousSearches")
                }
            }
            suggestions.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            if suggestions.isEmpty {
                tableView.reloadData()
            }
        }
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
}
 
