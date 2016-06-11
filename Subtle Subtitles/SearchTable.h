//
//  SearchTable.h
//  Subtle Subtitles
//
//  Created by Thomas Naudet on 26/03/2016.
//  Copyright © 2016 Thomas Naudet. All rights reserved.
//  This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/
//

@import UIKit;
#import "Data.h"
#import "OROpenSubtitleDownloader.h"
#import "Subtle_Subtitles-Swift.h"
#import "SubViewController.h"
#import "Settings.h"
#import "BGTableViewRowActionWithImage.h"
#import <UIScrollView+EmptyDataSet.h>

@interface SearchTable : UITableViewController <UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating, OROpenSubtitleDownloaderDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>
{
    UISearchController *search;
    NSArray *searchResults;
    SuggestionsTable *suggestionsTable;
    OROpenSubtitleDownloader *down;
    NSInteger currentScope;
    BOOL tapped;
    BOOL nothingFound;
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
- (void) openInKey;
- (void) shareKey;

- (void) longPress:(UILongPressGestureRecognizer *)gestureRecognizer;
- (void) openIn:(NSIndexPath *)indexPath
         atRect:(CGRect)rect;
- (void) share:(NSIndexPath *)indexPath
        atRect:(CGRect)rect;

@end
