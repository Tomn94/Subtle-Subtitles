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
#import "SubViewController.h"

@interface SearchTable : UITableViewController <UISearchBarDelegate, OROpenSubtitleDownloaderDelegate>
{
    UISearchController *search;
    NSArray *searchResults;
    OROpenSubtitleDownloader *down;
}

@end
