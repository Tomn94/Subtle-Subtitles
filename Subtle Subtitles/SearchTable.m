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
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil action:nil];
    
    search = [[UISearchController alloc] initWithSearchResultsController:nil];
    search.dimsBackgroundDuringPresentation = NO;
    search.searchBar.delegate = self;
    search.searchBar.placeholder = @"Search movies or series";
    search.searchBar.scopeButtonTitles = @[ @"English", [[NSUserDefaults standardUserDefaults] stringForKey:@"langName"] ];
    search.searchBar.barStyle = UIBarStyleBlack;
    search.searchBar.tintColor = [UIColor lightGrayColor];
    search.searchBar.keyboardAppearance = UIKeyboardAppearanceDark;
    [search.searchBar sizeToFit];
    self.tableView.tableHeaderView = search.searchBar;
    
    down = [[OROpenSubtitleDownloader alloc] initWithUserAgent:@"subtle subtitles"];
    down.delegate = self;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    search.searchBar.scopeButtonTitles = @[ @"English", [defaults stringForKey:@"langName"] ];
    search.searchBar.selectedScopeButtonIndex = [defaults integerForKey:@"langIndex"];
    [search.searchBar sizeToFit];
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - OROpenSubtitleDownloader delegate

- (void) openSubtitlerDidLogIn:(OROpenSubtitleDownloader *)downloader
{
    [[Data sharedData] updateNetwork:1];
    [down supportedLanguagesList:^(NSArray *languages, NSError *error) {
        if (error == nil)
        {
            NSMutableArray *langues  = [NSMutableArray array];
            NSMutableArray *langues2 = [NSMutableArray array];
            for (OpenSubtitleLanguageResult *res in languages)
            {
                if (![res.subLanguageID isEqualToString:@"eng"])
                {
                    [langues  addObject:res.localizedLanguageName];
                    [langues2 addObject:res.subLanguageID];
                }
            }
            [Data sharedData].langNames = [NSArray arrayWithArray:langues];
            [Data sharedData].langIDs   = [NSArray arrayWithArray:langues2];
        }
        else
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Unable to fetch available languages"
                                                                           message:error.localizedDescription
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
        [[Data sharedData] updateNetwork:-1];
    }];
}

#pragma mark - Search bar delegate

- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [[Data sharedData] updateNetwork:+1];
    down.languageString = search.searchBar.selectedScopeButtonIndex ? [[NSUserDefaults standardUserDefaults] stringForKey:@"langID"] : @"eng";
    [down searchForSubtitlesWithQuery:searchBar.text :^(NSArray *subtitles, NSError *error) {
        search.active = NO;
        if (error == nil)
        {
            if ([subtitles count])
            {
                searchResults = subtitles;
                [self.tableView reloadData];
            }
            else
            {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"No results"
                                                                               message:@"¯\\_(ツ)_/¯"
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            }
        }
        else
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Search error"
                                                                           message:[error localizedDescription]
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
        [[Data sharedData] updateNetwork:-1];
    }];
}

- (void)                searchBar:(UISearchBar *)searchBar
selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:@(selectedScope) forKey:@"langIndex"];
    [defaults synchronize];
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
    
    cell.selectedBackgroundView = [[UIView alloc] initWithFrame:cell.bounds];
    cell.selectedBackgroundView.backgroundColor = [UIColor darkGrayColor];
    
    return cell;
}

- (void)      tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    search.active = NO;
    [[Data sharedData] updateNetwork:1];
    [down downloadSubtitlesForResult:searchResults[indexPath.row]
                              toPath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingString:@"/sub.srt"] :^(NSString *path, NSError *error) {
                                  if (error == nil)
                                      [self.navigationController performSegueWithIdentifier:@"detailSegue" sender:self];
                                  else
                                  {
                                      UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error when downloading SRT file"
                                                                                                     message:[error localizedDescription]
                                                                                              preferredStyle:UIAlertControllerStyleAlert];
                                      [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
                                      [self presentViewController:alert animated:YES completion:nil];
                                  }
                                  [[Data sharedData] updateNetwork:-1];
                              }];
}

- (IBAction) infos:(id)sender
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Subtle Subtitles"
                                                                   message:@"Searches through OpenSubtitles.org thanks to OROpenSubtitleDownloader framework"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}
@end
