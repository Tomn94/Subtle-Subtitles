//
//  SearchTable.m
//  Subtle Subtitles
//
//  Created by Tomn on 26/03/2016.
//  Copyright © 2016 Tomn. All rights reserved.
//

#import "SearchTable.h"

@implementation SearchTable

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    searchResults = [NSArray array];
    
    UIView *backView = [UIView new];
    [backView setBackgroundColor:[UIColor colorWithWhite:0.2 alpha:1]];
    [self.tableView setBackgroundView:backView];
    
    search = [[UISearchController alloc] initWithSearchResultsController:nil];
    search.dimsBackgroundDuringPresentation = NO;
    search.searchBar.delegate = self;
    search.searchBar.placeholder = @"Search movies or series";
    search.searchBar.scopeButtonTitles = @[@"English"];
    search.searchBar.barStyle = UIBarStyleBlack;
    search.searchBar.tintColor = [UIColor lightGrayColor];
    [search.searchBar sizeToFit];
    self.tableView.tableHeaderView = search.searchBar;
    search.searchBar.hidden = YES;
    
    down = [[OROpenSubtitleDownloader alloc] initWithUserAgent:@"OSTestUserAgent"];
    down.delegate = self;
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - OROpenSubtitleDownloader delegate

- (void) openSubtitlerDidLogIn:(OROpenSubtitleDownloader *)downloader
{
    search.searchBar.hidden = NO;
    [downloader supportedLanguagesList:^(NSArray *languages, NSError *error) {
        if (error == nil)
        {
            NSMutableArray *langues  = [NSMutableArray array];
            NSMutableArray *langues2 = [NSMutableArray array];
            for (OpenSubtitleLanguageResult *res in languages)
            {
                if ([res.subLanguageID isEqualToString:@"eng"] ||
                    [res.subLanguageID isEqualToString:@"fre"])
                {
                    [langues  addObject:res.localizedLanguageName];
                    [langues2 addObject:res.subLanguageID];
                }
            }
            languageResults = [NSArray arrayWithArray:langues2];
            search.searchBar.scopeButtonTitles = langues;
            [search.searchBar sizeToFit];
        }
        else
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Erreur lors de la récupération des langues"
                                                                           message:[error localizedDescription]
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
}

#pragma mark - Search bar delegate

- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    down.languageString = languageResults[searchBar.selectedScopeButtonIndex];
    [down searchForSubtitlesWithQuery:searchBar.text :^(NSArray *subtitles, NSError *error) {
        if (error == nil)
            searchResults = subtitles;
        else
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Erreur lors de la recherche"
                                                                           message:[error localizedDescription]
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
        [self.tableView reloadData];
        search.active = NO;
    }];
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
    return [searchResults count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView
          cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"searchCell"
                                                            forIndexPath:indexPath];
    
    OpenSubtitleSearchResult *result = searchResults[indexPath.row];
    cell.textLabel.text       = result.subtitleName;
    cell.detailTextLabel.text = result.movieYear;
    
    return cell;
}

- (void)      tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [down downloadSubtitlesForResult:searchResults[indexPath.row]
                              toPath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingString:@"/sub"] :^(NSString *path, NSError *error) {
                                  if (error == nil)
                                  {
                                      NSLog(@"%@", path);
                                  }
                                  else
                                  {
                                      UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Erreur lors de la récupération"
                                                                                                     message:[error localizedDescription]
                                                                                              preferredStyle:UIAlertControllerStyleAlert];
                                      [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
                                      [self presentViewController:alert animated:YES completion:nil];
                                  }
                              }];
}

@end
