//
//  SearchTable.m
//  Subtle Subtitles
//
//  Created by Tomn on 26/03/2016.
//  Copyright © 2016 Tomn. All rights reserved.
//

@import StoreKit;
#import "SearchTable.h"

@implementation SearchTable

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    searchResults = [NSArray array];
    
    UIView *backView = [UIView new];
    [backView setBackgroundColor:[UIColor colorWithWhite:0.2 alpha:1]];
    [self.tableView setBackgroundView:backView];
    
    /*self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil action:nil];*/
    
    search = [[UISearchController alloc] initWithSearchResultsController:nil];
    search.dimsBackgroundDuringPresentation = NO;
    search.searchBar.delegate = self;
    search.searchBar.placeholder = NSLocalizedString(@"Search movies or series", @"");
    search.searchBar.scopeButtonTitles = @[ NSLocalizedString(@"English", @""), [[NSUserDefaults standardUserDefaults] stringForKey:@"langName"] ];
    search.searchBar.barStyle = UIBarStyleBlack;
    search.searchBar.tintColor = [UIColor lightGrayColor];
    search.searchBar.keyboardAppearance = UIKeyboardAppearanceDark;
    search.searchBar.text = [[NSUserDefaults standardUserDefaults] valueForKey:@"lastSearch"];
    [search.searchBar sizeToFit];
    self.tableView.tableHeaderView = search.searchBar;
    
    down = [[OROpenSubtitleDownloader alloc] initWithUserAgent:@"subtle subtitles"];
    down.delegate = self;
    
    KBTableView *tableView = (KBTableView *)self.tableView;
    [tableView setOnFocus:^(NSIndexPath * _Nullable current, NSIndexPath * _Nullable previous) {
        if (previous != nil)
            [self.tableView deselectRowAtIndexPath:previous animated:NO];
        if (current != nil)
            [self.tableView selectRowAtIndexPath:current animated:NO scrollPosition:UITableViewScrollPositionMiddle];
    }];
    [tableView setOnSelection:^(NSIndexPath * _Nonnull indexPath) {
        [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
    }];
    
    if ([UIKeyCommand instancesRespondToSelector:@selector(setDiscoverabilityTitle:)])
    {
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:@"f"
                                                modifierFlags:UIKeyModifierCommand
                                                       action:@selector(openSearch)
                                         discoverabilityTitle:NSLocalizedString(@"Search", @"")]];
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:@"f"
                                                modifierFlags:UIKeyModifierCommand | UIKeyModifierShift
                                                       action:@selector(selectLanguage:)
                                         discoverabilityTitle:NSLocalizedString(@"Search English Subtitles", @"")]];
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:@"f"
                                                modifierFlags:UIKeyModifierCommand | UIKeyModifierAlternate
                                                       action:@selector(selectLanguage:)
                                         discoverabilityTitle:NSLocalizedString(@"Search using Second Language", @"")]];
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:@"s"
                                                modifierFlags:UIKeyModifierCommand
                                                       action:@selector(increaseNumber:)
                                         discoverabilityTitle:NSLocalizedString(@"Increase Season number", @"")]];
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:@"e"
                                                modifierFlags:UIKeyModifierCommand
                                                       action:@selector(increaseNumber:)
                                         discoverabilityTitle:NSLocalizedString(@"Increase Episode number", @"")]];
        
        // TODO: Increase, change scope, Escape while searching
        
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow
                                                modifierFlags:0
                                                       action:@selector(keyArrow:)
                                         discoverabilityTitle:NSLocalizedString(@"Select Previous result", @"")]];
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow
                                                modifierFlags:0
                                                       action:@selector(keyArrow:)
                                         discoverabilityTitle:NSLocalizedString(@"Select Next result", @"")]];
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:@"\r"
                                                modifierFlags:0
                                                       action:@selector(enterKey)
                                         discoverabilityTitle:NSLocalizedString(@"Play Selection", @"")]];
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:UIKeyInputEscape
                                                modifierFlags:0
                                                       action:@selector(escapeKey)]];
        
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:@"l"
                                                modifierFlags:UIKeyModifierCommand
                                                       action:@selector(openLanguage)
                                         discoverabilityTitle:NSLocalizedString(@"Second Search Language Settings", @"")]];
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:@"i"
                                                modifierFlags:UIKeyModifierCommand
                                                       action:@selector(infos:)
                                         discoverabilityTitle:NSLocalizedString(@"Tips", @"")]];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLanguage) name:@"updateLanguage" object:nil];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Smooth animation when swiping back
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    
    [self updateLanguage];
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
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Unable to fetch available languages", @"")
                                                                           message:error.localizedDescription
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
        [[Data sharedData] updateNetwork:-1];
    }];
}

#pragma mark - Search bar delegate

- (void) searchBar:(UISearchBar *)searchBar
     textDidChange:(NSString *)searchText
{
    if ([searchText isEqualToString:@""])
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"lastSearch"];
}

- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    NSString *query = searchBar.text;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:searchBar.text forKey:@"lastSearch"];
    
    [[Data sharedData] updateNetwork:+1];
    down.languageString = search.searchBar.selectedScopeButtonIndex ? [defaults stringForKey:@"langID"] : @"eng";
    [down searchForSubtitlesWithQuery:query :^(NSArray *subtitles, NSError *error) {
        NSString *str = searchBar.text;
        search.active = NO;
        searchBar.text = str;
        if (error == nil)
        {
            if ([subtitles count])
            {
                searchResults = subtitles;
                [self.tableView reloadData];
            }
            else
            {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:NSLocalizedString(@"No results for “%@”", @""), str]
                                                                               message:@"¯\\_(ツ)_/¯"
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            }
        }
        else
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Search error", @"")
                                                                           message:[error localizedDescription]
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
        [[Data sharedData] updateNetwork:-1];
    }];
}

- (void)                searchBar:(UISearchBar *)searchBar
selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    if (selectedScope > 1)
    {
        searchBar.selectedScopeButtonIndex = currentScope;
        [self increaseTextNumber:selectedScope == 2];
        return;
    }
    
    currentScope = selectedScope;
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
    
    cell.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1];
    cell.selectedBackgroundView = [[UIView alloc] initWithFrame:cell.bounds];
    cell.selectedBackgroundView.backgroundColor = [UIColor darkGrayColor];
    
    return cell;
}

- (void)      tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *str = search.searchBar.text;
    search.active = NO;
    search.searchBar.text = str;
    
    OpenSubtitleSearchResult *result = searchResults[indexPath.row];
    if ([result.subtitleName hasSuffix:@".sub"])
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"SUB files are not supported", @"")
                                                                       message:NSLocalizedString(@"Sorry, search for SRT files, please.", @"")
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    
    [[Data sharedData] updateNetwork:1];
    [down downloadSubtitlesForResult:result
                              toPath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingString:[NSString stringWithFormat:@"/%@", result.subtitleName]] :^(NSString *path, NSError *error) {
                                  if (error == nil)
                                  {
                                      [[Data sharedData] setCurrentFileName:result.subtitleName];
                                      [self.navigationController performSegueWithIdentifier:@"detailSegue" sender:self];
                                  }
                                  else
                                  {
                                      UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error when downloading SRT file", @"")
                                                                                                     message:[error localizedDescription]
                                                                                              preferredStyle:UIAlertControllerStyleAlert];
                                      [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleCancel handler:nil]];
                                      [self presentViewController:alert animated:YES completion:nil];
                                  }
                                  [[Data sharedData] updateNetwork:-1];
                              }];
}

- (void) increaseTextNumber:(int)type
{
    NSString *query = search.searchBar.text;
    
    NSError *error = nil;
    NSRegularExpression *regex;
    if (type)
        regex = [NSRegularExpression regularExpressionWithPattern:@"S[0-9]{1,2}"
                                                          options:NSRegularExpressionCaseInsensitive
                                                            error:&error];
    else
        regex = [NSRegularExpression regularExpressionWithPattern:@"E[0-9]{1,2}"
                                                          options:NSRegularExpressionCaseInsensitive
                                                            error:&error];
    NSRange range = [regex rangeOfFirstMatchInString:query options:0 range:NSMakeRange(0, query.length)];
    if (range.location == NSNotFound && range.location + 1 >= query.length)
        return;
    
    NSString *result = [query substringWithRange:NSMakeRange(range.location + 1, range.length - 1)];
    int intVal = [result intValue] + 1;
    
    NSString *modifiedString = [regex stringByReplacingMatchesInString:query options:0 range:NSMakeRange(0, [query length])
                                                          withTemplate:[NSString stringWithFormat:@"%@%02d", (type) ? @"S" : @"E", intVal]];
    search.searchBar.text = modifiedString;
}

- (void) updateLanguage
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    search.searchBar.scopeButtonTitles = @[ NSLocalizedString(@"English", @""), [defaults stringForKey:@"langName"], @"S+1", @"E+1" ];
    search.searchBar.selectedScopeButtonIndex = [defaults integerForKey:@"langIndex"];
    currentScope = [defaults integerForKey:@"langIndex"];
    [search.searchBar sizeToFit];
}

- (IBAction) infos:(id)sender
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Subtle Subtitles"
                                                                   message:NSLocalizedString(@"Searches through OpenSubtitles.org thanks to OROpenSubtitleDownloader framework\n\nTip 1: S+1 and E+1 buttons help you find the next episode if you type something like “Archer S03E05”\nTip 2: Pinch to resize subtitles\n\nContact: @tomn94", @"")
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    if ([SKPaymentQueue canMakePayments])
    {
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Remove Ads", @"")
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * _Nonnull action) {
            UIAlertController *alert2 = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Remove ads for a small amount", @"")
                                                                            message:NSLocalizedString(@"The developer will be so happy for your donation especially knowing that you won't have to bear ads anymore!", @"")
                                                                     preferredStyle:UIAlertControllerStyleAlert];
            [alert2 addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Please, remove them", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [[Data sharedData] startPurchase];
            }]];
            [alert2 addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Restore purchase", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [[Data sharedData] restorePurchase];
            }]];
            [alert2 addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:nil]];
            
            [self presentViewController:alert2 animated:YES completion:nil];
        }]];
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void) openSearch
{
    [search.searchBar becomeFirstResponder];
}

- (void) openLanguage
{
    [self performSegueWithIdentifier:@"languageSegue" sender:self.navigationItem.leftBarButtonItem];
}

- (void) increaseNumber:(UIKeyCommand *)sender
{
    [self increaseTextNumber:[sender.input isEqualToString:@"s"]];
    [self searchBarSearchButtonClicked:search.searchBar];
}

- (void) selectLanguage:(UIKeyCommand *)sender
{
    [search.searchBar becomeFirstResponder];
    if (sender.modifierFlags != UIKeyModifierCommand)
        search.searchBar.selectedScopeButtonIndex = 1;
    else
        search.searchBar.selectedScopeButtonIndex = 0;
}

- (void) keyArrow:(UIKeyCommand *)sender
{
    KBTableView *tableView = (KBTableView *)self.tableView;
    if ([sender.input isEqualToString:UIKeyInputUpArrow])
        [tableView upCommand];
    else
        [tableView downCommand];
}

- (void) enterKey
{
    KBTableView *tableView = (KBTableView *)self.tableView;
    [tableView returnCommand];
}

- (void) escapeKey
{
    if (!search.isActive && self.tableView.indexPathForSelectedRow == nil)
    {
        [search.searchBar setText:@""];
        return;
    }
    
    KBTableView *tableView = (KBTableView *)self.tableView;
    [tableView escapeCommand];
}

@end
