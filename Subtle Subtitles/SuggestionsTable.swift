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
    func increaseNumber(season: Bool) -> NSString {
        do {
            let regexS = try NSRegularExpression(pattern: "S[0-9]{1,2}", options: [.CaseInsensitive])
            let regexE = try NSRegularExpression(pattern: "E[0-9]{1,2}", options: [.CaseInsensitive])
            
            let regex = season ? regexS : regexE;
            let cc = self.length
            
            var range = regex.rangeOfFirstMatchInString(self as String, options: [], range: NSRange(location: 0, length: cc))
            if range.location == NSNotFound || range.location + 1 >= cc { // Pas trouvé
                if season {     // Si bouton S+1
                    // Si on a au moins l'épisode
                    range = regexE.rangeOfFirstMatchInString(self as String, options: [], range: NSRange(location: 0, length: cc))
                    if range.location != NSNotFound && range.location + 1 < cc {
                        // On rajoute la saison 1
                        let result = (self as NSString).substringWithRange(range)
                        return regexE.stringByReplacingMatchesInString(self as String, options: [],
                                                                       range: NSRange(location: 0, length: cc),
                                                                       withTemplate: "S01" + result)
                    }
                } else {        // Si bouton E+1
                    // Si on a au moins la saison
                    range = regexS.rangeOfFirstMatchInString(self as String, options: [], range:NSRange(location: 0, length: cc))
                    if range.location != NSNotFound && range.location + 1 < cc {
                        // On rajoute l'épisode 1
                        let result = (self as NSString).substringWithRange(range)
                        return regexS.stringByReplacingMatchesInString(self as String, options: [],
                                                                       range:NSRange(location: 0, length: cc),
                                                                       withTemplate: result + "E01")
                    }
                }
                
                var res = self
                // S'il n'y a ni Sxx ni Exx
                if !hasSuffix(" ") {
                    res = res.stringByAppendingString(" ")
                }
                res = res.stringByAppendingString("S01E01")
                return res
            } else {
                let result = (self as NSString).substringWithRange(NSRange(location: range.location + 1, length: range.length - 1))
                var intVal = Int(result) ?? 0
                if intVal < 99 {
                    intVal += 1
                }
                
                return regex.stringByReplacingMatchesInString(self as String, options: [], range:NSRange(location: 0, length: cc),
                                                              withTemplate: String(format: "%@%02d", season ? "S" : "E", intVal))
            }
        } catch {}
        return self
    }
}


class SuggestionsTable: UITableViewController {
    
    var suggestions: [String] = []
    var searchController: UISearchController?
    var searchBar: UISearchBar?
    
    override var keyCommands: [UIKeyCommand]? {
        if #available(iOS 9.0, *) {
            return [
                UIKeyCommand(input: "\r", modifierFlags: [], action: #selector(search(_:)),
                    discoverabilityTitle: "Search".localized),
                UIKeyCommand(input: "\r", modifierFlags: [.Shift], action: #selector(search(_:)),
                    discoverabilityTitle: "Search English Subtitles".localized),
                UIKeyCommand(input: "\r", modifierFlags: [.Alternate], action: #selector(search(_:)),
                    discoverabilityTitle: "Search using Second Language".localized),
                
                UIKeyCommand(input: "f", modifierFlags: [.Command, .Shift], action: #selector(switchLang(_:)),
                    discoverabilityTitle: "Switch to English".localized),
                UIKeyCommand(input: "f", modifierFlags: [.Command, .Alternate], action: #selector(switchLang(_:)),
                    discoverabilityTitle: "Switch to Second Language".localized),
                
                UIKeyCommand(input: "s", modifierFlags: [.Command], action: #selector(increase(_:)),
                discoverabilityTitle: "Increase Season number".localized),
                UIKeyCommand(input: "e", modifierFlags: [.Command], action: #selector(increase(_:)),
                    discoverabilityTitle: "Increase Episode number".localized),
                
                UIKeyCommand(input: UIKeyInputUpArrow, modifierFlags: [], action: #selector(keyArrow(_:)),
                    discoverabilityTitle: "Select Previous Suggestion".localized),
                
                UIKeyCommand(input: UIKeyInputDownArrow, modifierFlags: [], action: #selector(keyArrow(_:)),
                    discoverabilityTitle: "Select Next Suggestion".localized),
                
                UIKeyCommand(input: "\r", modifierFlags: [.Command], action: #selector(enterKey),
                    discoverabilityTitle: "Choose Suggestion".localized),
                
                UIKeyCommand(input: "f", modifierFlags: [.Command], action: #selector(exit)),
                UIKeyCommand(input: UIKeyInputEscape, modifierFlags: [], action: #selector(exit),
                    discoverabilityTitle: "Exit Search".localized)
            ]
        } else {
            return []
        }
    }
    
    class func simplerQuery(query: String) -> String {
        do {
            let regex = try NSRegularExpression(pattern: "S\\d{1,2}E\\d{1,2}", options: [.CaseInsensitive])
            let res = regex.stringByReplacingMatchesInString(query, options: [],
                                                             range: NSRange(location: 0, length: query.characters.count),
                                                             withTemplate: "")
            return res.stringByTrimmingCharactersInSet(.whitespaceCharacterSet())
            
        } catch {}
        return query;
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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

        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "suggestCell")
    }
    
    func exit() {
        if let sb = searchBar where sb.isFirstResponder() {
            sb.resignFirstResponder()
        } else if let sc = searchController {
            sc.active = false
        }
    }
    
    func switchLang(sender: UIKeyCommand) {
        if let sb = searchBar {
            sb.selectedScopeButtonIndex = (sender.modifierFlags == [.Command, .Alternate]) ? 1 : 0
        }
    }
    
    func increase(sender: UIKeyCommand) {
        if let sb = searchBar {
            let txt = sb.text! as NSString
            sb.text = txt.increaseNumber(sender.input == "s") as String
        }
    }
    
    func search(sender: UIKeyCommand) {
        if let sb = searchBar {
            if sender.modifierFlags == [.Shift] {
                sb.selectedScopeButtonIndex = 0
            } else if sender.modifierFlags == [.Alternate] {
                sb.selectedScopeButtonIndex = 1
            }
            
            if let d = sb.delegate {
                d.searchBarSearchButtonClicked!(sb)
            }
        }
    }
    
    
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            if let sb = searchBar {
                let statusBar: CGFloat = UIApplication.sharedApplication().statusBarFrame.size.height
                tableView.contentInset = UIEdgeInsets(top: sb.frame.size.height + statusBar, left: 0, bottom: 0, right: 0)
                automaticallyAdjustsScrollViewInsets = false
            }
        }
    }
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        if let sb = searchBar {
            sb.resignFirstResponder()
        }
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return suggestions.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // Aucune recherche précédemment stockée
        if let previous = NSUserDefaults.standardUserDefaults().objectForKey("previousSearches") where previous.count == 0 {
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
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("suggestCell", forIndexPath: indexPath)
        
        cell.textLabel?.text = suggestions[indexPath.row].capitalizedString
        cell.textLabel?.textColor = .lightGrayColor()
        cell.backgroundColor = UIColor(white: 0.2, alpha: 1)
        cell.selectedBackgroundView = UIView(frame: cell.bounds)
        cell.selectedBackgroundView!.backgroundColor = .darkGrayColor()
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        searchBar?.text = suggestions[indexPath.row] + " "
        searchBar?.becomeFirstResponder()
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let defaults = NSUserDefaults.standardUserDefaults();
            if var previous = defaults.objectForKey("previousSearches") as? [String] {
                if let index = previous.indexOf(suggestions[indexPath.row]) {
                    previous.removeAtIndex(index)
                    defaults.setObject(previous, forKey: "previousSearches")
                }
            }
            suggestions.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            if suggestions.isEmpty {
                tableView.reloadData()
            }
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
}
 