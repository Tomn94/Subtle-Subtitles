//
//  FontList.swift
//  Subtle Subtitles
//
//  Created by Thomas Naudet on 26/11/2016.
//  Copyright © 2016 Thomas Naudet. All rights reserved.
//  This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/
//

import UIKit

@objc class FontList: UITableViewController {
    
    private var fonts = [String]()
    private var selectedFont: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Init available fonts */
        let familyNames = UIFont.familyNames.sorted()
        for familyName in familyNames {
            fonts += UIFont.fontNames(forFamilyName: familyName)
        }
        
        /* Init selected encoding with saved value */
        selectedFont = UserDefaults.standard.string(forKey: FontSettings.settingsFontNameKey)
        
        /* Init view */
        let backView = UIView()
        backView.backgroundColor = UIColor(white: 0.23, alpha: 1)
        tableView.backgroundView = backView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /* Scroll to selected font */
        if let selectedFont = selectedFont,
           let index = fonts.index(of: selectedFont) {
            self.tableView.scrollToRow(at: IndexPath(row: index, section: 1), at: .middle, animated: false)
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return fonts.count
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return "Alert using custom font".localized
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fontCell", for: indexPath)
        cell.selectedBackgroundView = UIView(frame: cell.bounds)
        cell.selectedBackgroundView!.backgroundColor = UIColor.darkGray

        if indexPath.section == 0 {
            cell.textLabel?.text = "Default font".localized
            cell.textLabel?.font = UIFont.systemFont(ofSize: cell.textLabel!.font.pointSize)
            cell.accessoryType = selectedFont == nil ? .checkmark : .none
        } else {
            let fontName = fonts[indexPath.row]
            cell.textLabel?.text = fontName
            cell.textLabel?.font = UIFont(name: fontName, size: cell.textLabel!.font.pointSize)
            cell.accessoryType = selectedFont == fontName ? .checkmark : .none
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        /* Uncheck previous row and check the new one */
        if let previousFont = selectedFont,
           let previousIndexPath = fonts.index(of: previousFont) {
            // Uncheck previous custom font
            tableView.cellForRow(at: IndexPath(row: previousIndexPath, section: 1))?.accessoryType = .none
        } else {
            // Uncheck default font
            tableView.cellForRow(at: IndexPath(row: 0, section: 0))?.accessoryType = .none
        }
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        
        /* Validate change */
        if indexPath.section == 0 {
            selectedFont = nil
            UserDefaults.standard.removeObject(forKey: FontSettings.settingsFontNameKey)
        } else {
            selectedFont = fonts[indexPath.row]
            UserDefaults.standard.set(selectedFont, forKey: FontSettings.settingsFontNameKey)
        }
        
        /* Apply on text */
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateDisplaySettings"), object: nil)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }

}
