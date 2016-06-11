//
//  LanguagesTable.swift
//  Subtle Subtitles
//
//  Created by Tomn on 11/06/2016.
//  Copyright © 2016 Tomn. All rights reserved.
//

import UIKit

class LanguagesTable: UITableViewController {
    
    var languages: [(id: String, name: String)] = []
    var lastSel = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Second Search Language".localized
        
        let backView = UIView()
        backView.backgroundColor = UIColor(white: 0.2, alpha: 1)
        tableView.backgroundView = backView
        tableView.separatorColor = .darkGrayColor()
        tableView.tintColor      = .lightGrayColor()
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "langageSettingsCell")
        
        let defaults = NSUserDefaults.standardUserDefaults()
        languages = [(id: defaults.stringForKey("langID")!, name: defaults.stringForKey("langName")!)]
        loadLanguages()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: lastSel, inSection: 0),
                                         atScrollPosition: .Middle, animated: true)
    }
    
    func loadLanguages() {
        if let languagesNames = Data.sharedData().langNames,
            let languagesIDs  = Data.sharedData().langIDs {
            let langs: [(id: String, name: String)] = Array(Zip2Sequence(languagesIDs as! [String], languagesNames as! [String]))
            
            languages = langs.sort({ (first, second) -> Bool in
                return first.name.localizedCaseInsensitiveCompare(second.name) == .OrderedAscending
            })
            
            let selectedLanguage = NSUserDefaults.standardUserDefaults().stringForKey("langID")
            lastSel = languages.indexOf({ (element) -> Bool in
                element.id == selectedLanguage
            }) ?? 0
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

}
