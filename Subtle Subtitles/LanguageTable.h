//
//  LanguageTable.h
//  Subtle Subtitles
//
//  Created by Tomn on 27/03/2016.
//  Copyright © 2016 Tomn. All rights reserved.
//

@import UIKit;
#import "Data.h"
#import "Subtle_Subtitles-Swift.h"

@interface LanguageTable : UITableViewController
{
    NSArray *langNames;
    NSArray *langIDs;
    NSIndexPath *lastSel;
    NSArray *settings;
    NSArray *settingsKeys;
    NSArray *sortSettings;
    NSArray *sortSettingsKeys;
}

- (IBAction) close;
- (void) keyArrow:(UIKeyCommand *)sender;
- (void) enterKey;

@end
