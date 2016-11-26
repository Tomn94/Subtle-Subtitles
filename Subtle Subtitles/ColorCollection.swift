//
//  ColorCollection.swift
//  Subtle Subtitles
//
//  Created by Tomn on 26/11/2016.
//  Copyright © 2016 Tomn. All rights reserved.
//

import UIKit

private let reuseIdentifier = "colorItem"

class ColorCollection: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    var colors = [UIColor]()    // 132 max colors in UI
    let itemsPerRow: CGFloat = 12
    var itemWidth: CGFloat = 32
    var itemHeight: CGFloat = 32
    var parentWidth: CGFloat = UIScreen.main.bounds.size.width
    var selectedIndexPath = IndexPath(item: -1, section: -1)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadColorsFile()
        
        itemWidth = (self.view.frame.size.width / itemsPerRow) - 1
        
        // Register cell classes
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: Notification.Name(rawValue: "colorChangedToCollection"), object: nil)
    }
    
    func loadColorsFile() {
        let path = Bundle.main.path(forResource: "Colors", ofType: "plist")
        let colorStringArray = NSArray(contentsOfFile: path!) ?? NSArray()
        
        let settingsColor = UserDefaults.standard.color(forKey: FontSettings.settingsFontColorKey)
        var rS: CGFloat = 0, gS: CGFloat = 0, bS: CGFloat = 0, aS: CGFloat = 1
        settingsColor.getRed(&rS, green: &gS, blue: &bS, alpha: &aS)
        
        colors.removeAll()
        var nbrColors = 0
        for colorString in colorStringArray {
            var hex: UInt32 = 0
            Scanner(string: colorString as! String).scanHexInt32(&hex)
            let r = CGFloat((hex & 0xFF0000) >> 16) / 255.0
            let g = CGFloat((hex & 0x00FF00) >> 8) / 255.0
            let b = CGFloat(hex & 0x0000FF) / 255.0
            
            let newColor = UIColor(red: r, green: g, blue: b, alpha: 1)
            colors.append(newColor)
            
            nbrColors += 1
            if abs(r - rS) < 0.0001 && abs(g - gS) < 0.0001 && abs(b - bS) < 0.0001 {
                selectedIndexPath = IndexPath(item: nbrColors - 1, section: 0)
            }
        }
    }
    
    func reload() {
        selectedIndexPath = IndexPath(item: -1, section: -1)
        self.collectionView?.reloadData()
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return colors.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: itemWidth, height: itemHeight)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
    
        let color = colors[indexPath.row]
        cell.backgroundColor = color
        
        if indexPath == selectedIndexPath {
            cell.layer.borderColor = color.isTooBright ? UIColor.lightGray.cgColor : UIColor.white.cgColor
            cell.layer.cornerRadius = 7
            cell.layer.borderWidth = 4
        } else {
            cell.layer.borderColor = UIColor.white.cgColor
            cell.layer.cornerRadius = 0
            cell.layer.borderWidth = 0.5
        }
    
        return cell
    }

    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        /* Update view */
        selectedIndexPath = indexPath
        self.collectionView?.reloadData()
        
        /* Save data */
        UserDefaults.standard.set(colors[selectedIndexPath.row], forKey: FontSettings.settingsFontColorKey)
        
        /* Notify player, menu and top menu */
        NotificationCenter.default.post(name: Notification.Name(rawValue: "updateDisplaySettings"), object: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "colorChanged"), object: nil)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "colorChangedToList"), object: nil)
    }
    
}
