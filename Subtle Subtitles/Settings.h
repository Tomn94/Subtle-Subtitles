//
//  LanguageTable.h
//  Subtle Subtitles
//
//  Created by Thomas Naudet on 27/03/2016.
//  Copyright © 2016 Thomas Naudet. All rights reserved.
//  This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/
//

@import UIKit;
#import "Data.h"
#import "Subtle_Subtitles-Swift.h"

@interface Settings : UITableViewController
{
    NSArray *settings;
    NSArray *settingsKeys;
    NSArray *sortSettings;
    NSArray *sortSettingsKeys;
}

+ (NSString *) localize:(NSString *)lang;

- (IBAction) close;
- (void) keyArrow:(UIKeyCommand *)sender;
- (void) enterKey;
- (void) clearHistory;

@end
