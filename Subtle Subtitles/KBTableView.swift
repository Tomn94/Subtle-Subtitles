//
//  KBTableView.swift
//  KBKit
//
//  Created by Evan Dekhayser on 12/13/15.
//  Copyright © 2015 Evan Dekhayser. All rights reserved.
//

import UIKit

@objc public class KBTableView : UITableView {
	
	var onSelection: ((NSIndexPath) -> Void)?
	var onFocus: ((current: NSIndexPath?, previous: NSIndexPath?) -> Void)?
	public var currentlyFocussedIndex: NSIndexPath?
	
	override public var keyCommands: [UIKeyCommand]?{
        if #available(iOS 9.0, *) {/*
            let upCommand = UIKeyCommand(input: UIKeyInputUpArrow, modifierFlags: [], action: #selector(KBTableView.upCommand), discoverabilityTitle: "Move Up")
            let downCommand = UIKeyCommand(input: UIKeyInputDownArrow, modifierFlags: [], action: #selector(KBTableView.downCommand), discoverabilityTitle: "Move Down")
            let returnCommand = UIKeyCommand(input: "\r", modifierFlags: [], action: #selector(KBTableView.returnCommand), discoverabilityTitle: "Enter")*/
//            let escCommand = UIKeyCommand(input: UIKeyInputEscape, modifierFlags: [], action: #selector(KBTableView.escapeCommand)/*, discoverabilityTitle: "Deselect"*/)
            let otherEscCommand = UIKeyCommand(input: "d", modifierFlags: [.Command], action: #selector(KBTableView.escapeCommand)/*, discoverabilityTitle: "Deselect"*/)
            
            var commands: [UIKeyCommand] = []// = [upCommand, downCommand]
            if let _ = currentlyFocussedIndex{
                commands += [/*returnCommand, escCommand,*/ otherEscCommand]
            }
            return commands
        }
        return nil
	}
	
	public func stopHighlighting(){
		onFocus?(current: nil, previous: currentlyFocussedIndex)
		currentlyFocussedIndex = nil
	}
	
	@objc public func escapeCommand(){
		stopHighlighting()
	}
	
	@objc public func upCommand(){
		guard let previouslyFocussedIndex = currentlyFocussedIndex else {
			currentlyFocussedIndex = indexPathForAbsoluteRow(numberOfTotalRows() - 1)
			onFocus?(current: currentlyFocussedIndex, previous: nil)
			return
		}
		
		if previouslyFocussedIndex.row > 0{
			currentlyFocussedIndex = NSIndexPath(forRow: previouslyFocussedIndex.row - 1, inSection: previouslyFocussedIndex.section)
		} else if previouslyFocussedIndex.section > 0{
			var section = previouslyFocussedIndex.section - 1
			while section >= 0{
				if numberOfRowsInSection(section) > 0{
					break
				} else {
					section -= 1
				}
			}
			if section >= 0{
				currentlyFocussedIndex = NSIndexPath(forRow: numberOfRowsInSection(section) - 1, inSection: section)
			} else {
				currentlyFocussedIndex = indexPathForAbsoluteRow(numberOfTotalRows() - 1)
			}
		} else {
			currentlyFocussedIndex = indexPathForAbsoluteRow(numberOfTotalRows() - 1)
		}
		onFocus?(current: currentlyFocussedIndex, previous: previouslyFocussedIndex)
	}
	
	@objc public func downCommand(){
		guard let previouslyFocussedIndex = currentlyFocussedIndex else {
			currentlyFocussedIndex = indexPathForAbsoluteRow(0)
			onFocus?(current: currentlyFocussedIndex, previous: nil)
			return
		}
		
		if previouslyFocussedIndex.row < numberOfRowsInSection(previouslyFocussedIndex.section) - 1{
			currentlyFocussedIndex = NSIndexPath(forRow: previouslyFocussedIndex.row + 1, inSection: previouslyFocussedIndex.section)
		} else if previouslyFocussedIndex.section < numberOfSections - 1{
			var section = previouslyFocussedIndex.section + 1
			while section < numberOfSections{
				if numberOfRowsInSection(section) > 0{
					break
				} else {
					section += 1
				}
			}
			if section < numberOfSections{
				currentlyFocussedIndex = NSIndexPath(forRow: 0, inSection: section)
			} else {
				currentlyFocussedIndex = indexPathForAbsoluteRow(0)
			}
		} else {
			currentlyFocussedIndex = indexPathForAbsoluteRow(0)
		}
		onFocus?(current: currentlyFocussedIndex, previous: previouslyFocussedIndex)
	}
	
	@objc public func returnCommand(){
		guard let currentlyFocussedIndex = currentlyFocussedIndex else { return }
		onSelection?(currentlyFocussedIndex)
	}
	
	public override func reloadData() {
		onFocus?(current: currentlyFocussedIndex, previous: nil)
		currentlyFocussedIndex = nil
		super.reloadData()
	}
	
	required public init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(KBTableView.escapeCommand), name: UITableViewSelectionDidChangeNotification, object: self)
	}
	
	override public init(frame: CGRect, style: UITableViewStyle) {
		super.init(frame: frame, style: style)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(KBTableView.escapeCommand), name: UITableViewSelectionDidChangeNotification, object: self)
	}
	
	deinit{
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}
	
	public override func canBecomeFirstResponder() -> Bool {
		return true
	}
	
}

