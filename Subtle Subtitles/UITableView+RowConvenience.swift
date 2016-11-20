//
//  UITableView+RowConvenience.swift
//  KBKit
//
//  Created by Evan Dekhayser on 12/27/15.
//  Copyright © 2015 Evan Dekhayser. All rights reserved.
//

import UIKit

public extension UITableView{
	
	public func indexPathForAbsoluteRow(_ absoluteRow: Int) -> IndexPath?{
		var currentRow = 0
		for section in 0..<numberOfSections{
			for row in 0..<numberOfRows(inSection: section){
				if currentRow == absoluteRow{
					return IndexPath(row: row, section: section)
				}
				currentRow += 1
			}
		}
		return nil
	}
	
	public func absoluteRowForIndexPath(_ indexPath: IndexPath) -> Int?{
		guard indexPath.section < self.numberOfSections else { return nil }
		var rowNumber = 0
		for section in 0..<indexPath.section{
			rowNumber += numberOfRows(inSection: section)
		}
		guard indexPath.row < numberOfRows(inSection: indexPath.section) else { return nil }
		rowNumber += indexPath.row
		return rowNumber
	}
	
	public func numberOfTotalRows() -> Int{
		var total = 0
		for section in 0..<numberOfSections{
			total += numberOfRows(inSection: section)
		}
		return total
	}
	
}
