//
//  SearchTable.h
//  Subtle Subtitles
//
//  Created by Tomn on 26/03/2016.
//  Copyright © 2016 Tomn. All rights reserved.
//

@import UIKit;
#import <OROpenSubtitleDownloader/OROpenSubtitleDownloader.h>

@interface SearchTable : UITableViewController <OROpenSubtitleDownloaderDelegate, UISearchBarDelegate>
{
    UISearchController *search;
    OROpenSubtitleDownloader *down;
    NSArray *languageResults;
    NSArray *searchResults;
}

@end
