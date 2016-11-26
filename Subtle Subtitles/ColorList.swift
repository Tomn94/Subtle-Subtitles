//
//  ColorList.swift
//  Subtle Subtitles
//
//  Created by Thomas Naudet on 26/11/2016.
//  Copyright © 2016 Thomas Naudet. All rights reserved.
//  This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/
//

import UIKit

class ColorList: UITableViewController {
    
    /// Set iPad keyboard shortcuts
    override var keyCommands: [UIKeyCommand]? {
        if #available(iOS 9, *) {
            return [
                UIKeyCommand(input: UIKeyInputLeftArrow, modifierFlags: [], action: #selector(keyArrow(_:)),
                             discoverabilityTitle: "Back to Display Settings".localized),
                
                UIKeyCommand(input: UIKeyInputEscape, modifierFlags: [], action: #selector(close),
                             discoverabilityTitle: "Dismiss".localized)
            ]
        } else {
            return []
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Init view */
        let backView = UIView()
        backView.backgroundColor = UIColor(white: 0.23, alpha: 1)
        tableView.backgroundView = backView
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: Notification.Name(rawValue: "colorChangedToList"), object: nil)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        /* Set Collection View width */
        if let collectionVC = self.childViewControllers.first as? ColorCollection {
            collectionVC.itemWidth = (self.tableView.frame.size.width / collectionVC.itemsPerRow) - 1
            collectionVC.collectionViewLayout.invalidateLayout()
        }
    }
    
    func reload() {
        tableView.cellForRow(at: IndexPath(row: 0, section: 0))?.accessoryType = UserDefaults.standard.color(forKey: FontSettings.settingsFontColorKey) == .white ? .checkmark : .none
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return "Custom color header".localized
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return "Alert using custom color".localized
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        if indexPath.section == 0 {
            cell.backgroundColor = UIColor(white:0.2, alpha:1)
            cell.selectedBackgroundView = UIView(frame: cell.bounds)
            cell.selectedBackgroundView!.backgroundColor = UIColor.darkGray
            cell.textLabel!.textColor = UIColor.white
            
            cell.accessoryType = UserDefaults.standard.color(forKey: FontSettings.settingsFontColorKey) == .white ? .checkmark : .none
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            /* Save data */
            UserDefaults.standard.removeObject(forKey: FontSettings.settingsFontColorKey)
            
            self.reload()
            
            /* Notify player, top menu and color collection */
            NotificationCenter.default.post(name: Notification.Name(rawValue: "updateDisplaySettings"), object: nil)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "colorChanged"), object: nil)
            NotificationCenter.default.post(name: Notification.Name(rawValue: "colorChangedToCollection"), object: nil)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Keyboard
    
    func keyArrow(_ sender: UIKeyCommand) {
        if sender.input == UIKeyInputLeftArrow {
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func close() {
        dismiss(animated: true, completion: nil)
    }
    
}
