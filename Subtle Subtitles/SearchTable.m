//
//  SearchTable.m
//  Subtle Subtitles
//
//  Created by Thomas Naudet on 26/03/2016.
//  Copyright © 2016 Thomas Naudet. All rights reserved.
//  This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/
//

@import StoreKit;
#import "SearchTable.h"
#import "Subtle_Subtitles-Swift.h"
#import <AFNetworking/UIKit+AFNetworking.h>

@implementation SearchTable

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    searchResults = [NSArray array];
    suggestionsTable = [[SuggestionsTable alloc] initWithStyle:UITableViewStyleGrouped];
    
    UIView *backView = [UIView new];
    [backView setBackgroundColor:[UIColor colorWithWhite:0.2 alpha:1]];
    [self.tableView setBackgroundView:backView];
    self.tableView.rowHeight = 44; // iOS 8
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    search = [[UISearchController alloc] initWithSearchResultsController:suggestionsTable];
    search.delegate = self;
    search.searchBar.delegate = self;
    search.searchResultsUpdater = self;
    search.searchBar.placeholder = NSLocalizedString(@"Search movies or series", @"");
    search.searchBar.scopeButtonTitles = @[ NSLocalizedString(@"English", @""), [LanguageTable localize:[defaults stringForKey:@"langName"]], @"S+1", @"E+1" ];
    search.searchBar.barStyle = UIBarStyleBlack;
    search.searchBar.tintColor = [UIColor lightGrayColor];
    search.searchBar.barTintColor = [UIColor colorWithWhite:0.25 alpha:1];
    search.searchBar.keyboardAppearance = UIKeyboardAppearanceDark;
    search.dimsBackgroundDuringPresentation = YES;
    search.searchBar.enablesReturnKeyAutomatically = NO;
    [search.searchBar sizeToFit];
    self.tableView.tableHeaderView = search.searchBar;
    suggestionsTable.searchBar = search.searchBar;
    
    down = [[OROpenSubtitleDownloader alloc] initWithUserAgent:@"subtle subtitles"];
    down.delegate = self;
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    self.tableView.tableFooterView = [UIView new];
    
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
        
        UIBarButtonItem *seasonKey = [[UIBarButtonItem alloc] initWithTitle:@"S+1" style:UIBarButtonItemStylePlain
                                                                     target:self action:@selector(increaseNumberWithButton:)];
        UIBarButtonItem *episodeKey = [[UIBarButtonItem alloc] initWithTitle:@"E+1" style:UIBarButtonItemStylePlain
                                                                      target:self action:@selector(increaseNumberWithButton:)];
        UIBarButtonItem *plus1Buttons = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                      target:self action:nil];
        UIBarButtonItemGroup *plus1Group = [[UIBarButtonItemGroup alloc] initWithBarButtonItems:@[seasonKey, episodeKey]
                                                                             representativeItem:plus1Buttons];
        search.searchBar.inputAssistantItem.trailingBarButtonGroups = @[plus1Group];
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

#pragma mark - Search delegates

- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    tapped = NO;
    
    NSString *query = searchBar.text;
    NSString *simplerQuery = [SuggestionsTable simplerQuery:search.searchBar.text];
    if ([simplerQuery isEqualToString:@""])
    {
        search.active = NO;
        return;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"rememberLastSearch"])
    {
        NSArray *t_previous = [defaults arrayForKey:@"previousSearches"];
        NSMutableArray *previous = (t_previous != nil) ? [NSMutableArray arrayWithArray:t_previous] : [NSMutableArray array];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] %@", simplerQuery];
        NSArray *filteredArray = [previous filteredArrayUsingPredicate:predicate];
        for (NSString *string in filteredArray)
            [previous removeObject:string];
        [previous insertObject:simplerQuery atIndex:0];
        
        [defaults setObject:previous forKey:@"previousSearches"];
    }
    
    [[Data sharedData] updateNetwork:+1];
    down.languageString = search.searchBar.selectedScopeButtonIndex ? [defaults stringForKey:@"langID"] : @"eng";
    [down searchForSubtitlesWithQuery:query :^(NSArray *subtitles, NSError *error) {
        NSString *str = searchBar.text;
        search.active = NO;
        searchBar.text = str;
        if (error == nil)
        {
            nothingFound = [subtitles count] == 0;
            self.tableView.tableFooterView = nothingFound ? [UIView new] : nil;
            if (nothingFound)
                searchResults = [NSArray array];
            else
            {
                NSMutableArray *results = [NSMutableArray array];
                for (OpenSubtitleSearchResult *result in subtitles)
                {
                    if ([result.subtitleFormat.lowercaseString isEqualToString:@"srt"])
                        [results addObject:result];
                }
                NSMutableArray *sortDescriptors = [NSMutableArray array];
                NSArray *settingsKeys = @[@"down", @"ratings", @"cc", @"hd"];
                if ([[NSUserDefaults standardUserDefaults] boolForKey:settingsKeys[0]])
                    [sortDescriptors addObject:[[NSSortDescriptor alloc] initWithKey:@"downloadCount"
                                                                           ascending:NO]];
                if ([[NSUserDefaults standardUserDefaults] boolForKey:settingsKeys[1]])
                    [sortDescriptors addObject:[[NSSortDescriptor alloc] initWithKey:@"subtitleRating"
                                                                           ascending:NO]];
                if ([[NSUserDefaults standardUserDefaults] boolForKey:settingsKeys[2]])
                    [sortDescriptors addObject:[[NSSortDescriptor alloc] initWithKey:@"hearingImpaired"
                                                                           ascending:NO]];
                if ([[NSUserDefaults standardUserDefaults] boolForKey:settingsKeys[3]])
                    [sortDescriptors addObject:[[NSSortDescriptor alloc] initWithKey:@"hd"
                                                                           ascending:NO]];
                searchResults = [results sortedArrayUsingDescriptors:sortDescriptors];
            }
            [self.tableView reloadData];
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
    tapped = NO;
    
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

- (void) searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    nothingFound = NO;
    [self.tableView reloadEmptyDataSet];
}

- (void) updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSArray *previous = [[NSUserDefaults standardUserDefaults] arrayForKey:@"previousSearches"];
    if (previous == nil)
        previous = [NSArray array];
    
    NSString *currentText = [SuggestionsTable simplerQuery:search.searchBar.text];
    
    NSArray *res;
    if ([currentText isEqualToString:@""])
        res = previous;
    else
    {
        NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"SELF CONTAINS[cd] %@", currentText];
        res = [previous filteredArrayUsingPredicate:resultPredicate];
    }
    
    // Suggestions when empty
    searchController.searchResultsController.view.hidden = ![[NSUserDefaults standardUserDefaults] boolForKey:@"rememberLastSearch"];
    suggestionsTable.suggestions = res;
    [suggestionsTable.tableView reloadData];
}

- (void) willPresentSearchController:(UISearchController *)searchController
{
    dispatch_async(dispatch_get_main_queue(), ^{
        searchController.searchResultsController.view.hidden = ![[NSUserDefaults standardUserDefaults] boolForKey:@"rememberLastSearch"];
    });
}

- (void) didPresentSearchController:(UISearchController *)searchController
{
    searchController.searchResultsController.view.hidden = ![[NSUserDefaults standardUserDefaults] boolForKey:@"rememberLastSearch"];
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
    SearchTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"searchCell"
                                                            forIndexPath:indexPath];
    
    OpenSubtitleSearchResult *result = searchResults[indexPath.row];
    NSMutableArray *infos = [NSMutableArray array];
    BOOL longInfos = self.view.frame.size.width > 320;
    
    cell.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1];
    cell.selectedBackgroundView = [[UIView alloc] initWithFrame:cell.bounds];
    cell.selectedBackgroundView.backgroundColor = [UIColor darkGrayColor];
    cell.title.textColor = ([result.bad isEqualToString:@"1"]) ? [UIColor lightGrayColor] : [UIColor whiteColor];
    
    if ([result.bad isEqualToString:@"1"])
        [infos addObject:NSLocalizedString(@"Bad", "Mauvais sous-titre")];
    
    float rating = result.subtitleRating / 2;
    if (rating > 0) {
        NSString *star = @"★";
        NSString *emptyStar = @"☆";
        NSString *val = [NSString stringWithFormat:@"%@%@%@%@%@",
                         (rating >= 1) ? star : emptyStar,
                         (rating >= 2) ? star : ((rating > 1) ? emptyStar : @""),
                         (rating >= 3) ? star : ((rating > 2) ? emptyStar : @""),
                         (rating >= 4) ? star : ((rating > 3) ? emptyStar : @""),
                         (rating >= 5) ? star : ((rating > 4) ? emptyStar : @"")];
        [infos addObject:val];
    }
    
    [infos addObject:result.movieYear];
    
    NSString *hearing = NSLocalizedString(@"CC", "Descriptions sonores");
    if ([result.hearingImpaired isEqualToString:@"1"])
        [infos addObject:hearing];
    
    NSString *hd = NSLocalizedString(@"HD", "Haute définition");
    if ([result.hd isEqualToString:@"1"])
        [infos addObject:hd];
    
    NSString *key = (longInfos) ? @"%d download(s)" : @"%d down.";
    [infos addObject:[NSString localizedStringWithFormat:NSLocalizedString(key, "Téléchargements"), result.downloadCount]];
    
    [infos addObject:[NSByteCountFormatter stringFromByteCount:result.subtitleSize
                                                    countStyle:NSByteCountFormatterCountStyleFile]];
    
    NSString *lastTS = result.subtitleLength;
    NSDateComponents *dc = [NSDateComponents new];
    dc.hour = (lastTS.length >= 2) ? [lastTS substringToIndex:2].intValue : 0;
    dc.minute = (lastTS.length >= 4) ? [lastTS substringWithRange:NSMakeRange(3, 2)].intValue : 0;
    if (longInfos)
        dc.second = (lastTS.length >= 7) ? [lastTS substringWithRange:NSMakeRange(6, 2)].intValue : 0;
    [infos addObject:[NSDateComponentsFormatter localizedStringFromDateComponents:dc
                                                                       unitsStyle:NSDateComponentsFormatterUnitsStyleAbbreviated]];
    
    NSString *detail = [infos componentsJoinedByString:@" · "]; // bad+rating+date+hearing+hd+download+size+length
    NSMutableAttributedString *as = [[NSMutableAttributedString alloc] initWithString:detail];
    if ([result.hearingImpaired isEqualToString:@"1"])
        [as setAttributes:@{ NSFontAttributeName: [UIFont boldSystemFontOfSize:cell.subtitle.font.pointSize] }
                    range:[detail rangeOfString:hearing]];
    if ([result.hd isEqualToString:@"1"])
        [as setAttributes:@{ NSFontAttributeName: [UIFont italicSystemFontOfSize:cell.subtitle.font.pointSize] }
                    range:[detail rangeOfString:hd]];
    
    cell.title.text              = result.subtitleName;
    cell.subtitle.attributedText = as;
    [cell.progress setProgress:0 animated:NO];
    
    return cell;
}

- (void)      tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tapped)
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    tapped = YES;
    
    NSString *str = search.searchBar.text;
    search.active = NO;
    search.searchBar.text = str;

    OpenSubtitleSearchResult *result = searchResults[indexPath.row];
    if ([result.subtitleName hasSuffix:@".sub"] || [result.subtitleFormat.lowercaseString isEqualToString:@"sub"])
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"SUB files are not supported", @"")
                                                                       message:NSLocalizedString(@"Sorry, search for SRT files, please.", @"")
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        tapped = NO;
        return;
    }
    
    SearchTableCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [cell.progress setProgress:0.9 animated:YES];
    
    [[Data sharedData] updateNetwork:1];
    [down downloadSubtitlesForResult:result
                              toPath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingString:[NSString stringWithFormat:@"/%@", result.subtitleName]]
                          onProgress:^(float progress) {
                                      [cell.progress setProgress:progress animated:YES];
                                  }
                                    :^(NSString *path, NSError *error) {
                                        if (error == nil)
                                        {
                                            [[Data sharedData] setCurrentFile:result];
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
                                        [cell.progress setProgress:0 animated:YES];
                                        [[Data sharedData] updateNetwork:-1];
                                        tapped = NO;
                              }];
}

#pragma mark - Actions

- (void) increaseTextNumber:(int)type
{
    NSString *query = search.searchBar.text;
    
    NSError *error = nil;
    NSRegularExpression *regexS = [NSRegularExpression regularExpressionWithPattern:@"S[0-9]{1,2}"
                                                                            options:NSRegularExpressionCaseInsensitive
                                                                              error:&error];
    NSRegularExpression *regexE = [NSRegularExpression regularExpressionWithPattern:@"E[0-9]{1,2}"
                                                                            options:NSRegularExpressionCaseInsensitive
                                                                              error:&error];
    NSRegularExpression *regex = type ? regexS : regexE;

    NSRange range = [regex rangeOfFirstMatchInString:query options:0 range:NSMakeRange(0, query.length)];
    if (range.location == NSNotFound && range.location + 1 >= query.length) // Pas trouvé
    {
        BOOL rienDeRien = YES;
        
        if (type)   // Si bouton S+1
        {
            // Si on a au moins l'épisode
            range = [regexE rangeOfFirstMatchInString:query options:0 range:NSMakeRange(0, query.length)];
            if (range.location != NSNotFound && range.location + 1 < query.length)
            {
                // On rajoute la saison 1
                NSString *result = [query substringWithRange:range];
                query = [regexE stringByReplacingMatchesInString:query options:0 range:NSMakeRange(0, [query length])
                                                    withTemplate:[@"S01" stringByAppendingString:result]];
                rienDeRien = NO;
            }
        }
        else        // Si bouton E+1
        {
            // Si on a au moins la saison
            range = [regexS rangeOfFirstMatchInString:query options:0 range:NSMakeRange(0, query.length)];
            if (range.location != NSNotFound && range.location + 1 < query.length)
            {
                // On rajoute l'épisode 1
                NSString *result = [query substringWithRange:range];
                query = [regexS stringByReplacingMatchesInString:query options:0 range:NSMakeRange(0, [query length])
                                                    withTemplate:[result stringByAppendingString:@"E01"]];
                rienDeRien = NO;
            }
        }
     
        if (rienDeRien) // S'il n'y a ni Sxx ni Exx
        {
            if (![query hasSuffix:@" "])
                query = [query stringByAppendingString:@" "];
            search.searchBar.text = [query stringByAppendingString:@"S01E01"];
        }
        else
            search.searchBar.text = query;
    
        return;
    }
    
    NSString *result = [query substringWithRange:NSMakeRange(range.location + 1, range.length - 1)];
    int intVal = [result intValue] + 1;
    
    NSString *modifiedString = [regex stringByReplacingMatchesInString:query options:0 range:NSMakeRange(0, [query length])
                                                          withTemplate:[NSString stringWithFormat:@"%@%02d", (type) ? @"S" : @"E", intVal]];
    search.searchBar.text = modifiedString;
}

- (void) updateLanguage
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    search.searchBar.scopeButtonTitles = @[ NSLocalizedString(@"English", @""), [LanguageTable localize:[defaults stringForKey:@"langName"]], @"S+1", @"E+1" ];
    search.searchBar.selectedScopeButtonIndex = [defaults integerForKey:@"langIndex"];
    currentScope = [defaults integerForKey:@"langIndex"];
    [search.searchBar sizeToFit];
}

- (IBAction) infos:(id)sender
{
    if (tapped)
        return;
    
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

- (void) increaseNumberWithButton:(UIBarButtonItem *)sender
{
    [self increaseTextNumber:[sender.title isEqualToString:@"S+1"]];
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

#pragma mark - Empty data set delegate

- (UIImage *) imageForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIImage imageNamed:@"empty"];
}

- (NSAttributedString *) titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = NSLocalizedString(@"Empty search", @"");
    if (nothingFound)
        text = [NSString stringWithFormat:NSLocalizedString(@"No results for “%@”", @""), search.searchBar.text];
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0],
                                 NSForegroundColorAttributeName: [UIColor darkGrayColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

@end
