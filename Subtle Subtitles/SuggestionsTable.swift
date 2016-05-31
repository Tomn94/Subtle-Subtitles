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

class SuggestionsTable: UITableViewController {
    
    var suggestions: [String] = []
    var searchBar: UISearchBar?
    
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

        let backView = UIView()
        backView.backgroundColor = UIColor(white: 0.2, alpha: 1)
        tableView.backgroundView = backView
        tableView.separatorColor = .darkGrayColor()

        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "suggestCell")
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
            return NSLocalizedString("No Previous Searches", comment: "")
        }
        // Recherches stockées
        if suggestions.count > 0 {
            if let sb = searchBar,
                let txt = sb.text {
                if SuggestionsTable.simplerQuery(txt).isEmpty {
                    return NSLocalizedString("Previous Searches", comment: "")      // Champ vide = liste complète
                }
                return NSLocalizedString("Previous Searches Matching", comment: "") // Champ plein = correspondances
            }
        }
        // Aucune correspondance
        return NSLocalizedString("No Previous Matching", comment: "")
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("suggestCell", forIndexPath: indexPath)
        
        cell.textLabel?.text = suggestions[indexPath.row]
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
}
 