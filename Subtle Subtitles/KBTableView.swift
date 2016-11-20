//
//  KBTableView.swift
//  KBKit
//
//  Created by Evan Dekhayser on 12/13/15.
//  Copyright © 2015 Evan Dekhayser. All rights reserved.
//

import UIKit

@objc open class KBTableView : UITableView {
	
	var onSelection: ((IndexPath) -> Void)?
	var onFocus: ((_ current: IndexPath?, _ previous: IndexPath?) -> Void)?
	open var currentlyFocussedIndex: IndexPath?
	
	override open var keyCommands: [UIKeyCommand]?{
        if #available(iOS 9.0, *) {/*
            let upCommand = UIKeyCommand(input: UIKeyInputUpArrow, modifierFlags: [], action: #selector(KBTableView.upCommand), discoverabilityTitle: "Move Up")
            let downCommand = UIKeyCommand(input: UIKeyInputDownArrow, modifierFlags: [], action: #selector(KBTableView.downCommand), discoverabilityTitle: "Move Down")
            let returnCommand = UIKeyCommand(input: "\r", modifierFlags: [], action: #selector(KBTableView.returnCommand), discoverabilityTitle: "Enter")*/
//            let escCommand = UIKeyCommand(input: UIKeyInputEscape, modifierFlags: [], action: #selector(KBTableView.escapeCommand)/*, discoverabilityTitle: "Deselect"*/)
            let otherEscCommand = UIKeyCommand(input: "d", modifierFlags: [.command], action: #selector(KBTableView.escapeCommand)/*, discoverabilityTitle: "Deselect"*/)
            
            var commands: [UIKeyCommand] = []// = [upCommand, downCommand]
            if let _ = currentlyFocussedIndex{
                commands += [/*returnCommand, escCommand,*/ otherEscCommand]
            }
            return commands
        }
        return nil
	}
	
	open func stopHighlighting(){
		onFocus?(nil, currentlyFocussedIndex)
		currentlyFocussedIndex = nil
	}
	
	@objc open func escapeCommand(){
		stopHighlighting()
	}
	
	@objc open func upCommand(){
		guard let previouslyFocussedIndex = currentlyFocussedIndex else {
			currentlyFocussedIndex = indexPathForAbsoluteRow(numberOfTotalRows() - 1)
			onFocus?(currentlyFocussedIndex, nil)
			return
		}
		
		if previouslyFocussedIndex.row > 0{
			currentlyFocussedIndex = IndexPath(row: previouslyFocussedIndex.row - 1, section: previouslyFocussedIndex.section)
		} else if previouslyFocussedIndex.section > 0{
			var section = previouslyFocussedIndex.section - 1
			while section >= 0{
				if numberOfRows(inSection: section) > 0{
					break
				} else {
					section -= 1
				}
			}
			if section >= 0{
				currentlyFocussedIndex = IndexPath(row: numberOfRows(inSection: section) - 1, section: section)
			} else {
				currentlyFocussedIndex = indexPathForAbsoluteRow(numberOfTotalRows() - 1)
			}
		} else {
			currentlyFocussedIndex = indexPathForAbsoluteRow(numberOfTotalRows() - 1)
		}
		onFocus?(currentlyFocussedIndex, previouslyFocussedIndex)
	}
	
	@objc open func downCommand(){
		guard let previouslyFocussedIndex = currentlyFocussedIndex else {
			currentlyFocussedIndex = indexPathForAbsoluteRow(0)
			onFocus?(currentlyFocussedIndex, nil)
			return
		}
		
		if previouslyFocussedIndex.row < numberOfRows(inSection: previouslyFocussedIndex.section) - 1{
			currentlyFocussedIndex = IndexPath(row: previouslyFocussedIndex.row + 1, section: previouslyFocussedIndex.section)
		} else if previouslyFocussedIndex.section < numberOfSections - 1{
			var section = previouslyFocussedIndex.section + 1
			while section < numberOfSections{
				if numberOfRows(inSection: section) > 0{
					break
				} else {
					section += 1
				}
			}
			if section < numberOfSections{
				currentlyFocussedIndex = IndexPath(row: 0, section: section)
			} else {
				currentlyFocussedIndex = indexPathForAbsoluteRow(0)
			}
		} else {
			currentlyFocussedIndex = indexPathForAbsoluteRow(0)
		}
		onFocus?(currentlyFocussedIndex, previouslyFocussedIndex)
	}
	
	@objc open func returnCommand(){
		guard let currentlyFocussedIndex = currentlyFocussedIndex else { return }
		onSelection?(currentlyFocussedIndex)
	}
	
	open override func reloadData() {
		onFocus?(currentlyFocussedIndex, nil)
		currentlyFocussedIndex = nil
		super.reloadData()
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		NotificationCenter.default.addObserver(self, selector: #selector(KBTableView.escapeCommand), name: NSNotification.Name.UITableViewSelectionDidChange, object: self)
	}
	
	override public init(frame: CGRect, style: UITableViewStyle) {
		super.init(frame: frame, style: style)
		NotificationCenter.default.addObserver(self, selector: #selector(KBTableView.escapeCommand), name: NSNotification.Name.UITableViewSelectionDidChange, object: self)
	}
	
	deinit{
		NotificationCenter.default.removeObserver(self)
	}
	
	open override var canBecomeFirstResponder : Bool {
		return true
	}
	
}

