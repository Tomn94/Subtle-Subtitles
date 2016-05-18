//
//  SearchTable.h
//  Subtle Subtitles
//
//  Created by Tomn on 26/03/2016.
//  Copyright © 2016 Tomn. All rights reserved.
//

@import UIKit;
#import "Data.h"
#import <OROpenSubtitleDownloader/OROpenSubtitleDownloader.h>
#import "Subtle_Subtitles-Swift.h"
#import "SubViewController.h"

@interface SearchTable : UITableViewController <UISearchBarDelegate, OROpenSubtitleDownloaderDelegate>
{
    UISearchController *search;
    NSArray *searchResults;
    OROpenSubtitleDownloader *down;
    NSInteger currentScope;
}

- (void) increaseTextNumber:(int)type;
- (void) updateLanguage;
- (IBAction) infos:(id)sender;

- (void) openSearch;
- (void) openLanguage;
- (void) increaseNumber:(UIKeyCommand *)sender;
- (void) selectLanguage:(UIKeyCommand *)sender;
- (void) keyArrow:(UIKeyCommand *)sender;
- (void) enterKey;
- (void) escapeKey;

@end
