//
//  LanguageTable.m
//  Subtle Subtitles
//
//  Created by Thomas Naudet on 27/03/2016.
//  Copyright © 2016 Thomas Naudet. All rights reserved.
//  This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/
//

#import "LanguageTable.h"

@implementation LanguageTable

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    settings  = @[NSLocalizedString(@"Remember Last Search", @"")];
    settingsKeys = @[@"rememberLastSearch"];
    sortSettings = @[NSLocalizedString(@"Download Number", @""),
                     NSLocalizedString(@"Ratings", @""),
                     NSLocalizedString(@"CC (Hearing Impaired)", @""),
                     NSLocalizedString(@"HD", @"")];
    sortSettingsKeys = @[@"ratings", @"down", @"cc", @"hd"];
    
    NSArray *languagesNames = [Data sharedData].langNames;
    NSArray *languagesIDs   = [Data sharedData].langIDs;
    NSMutableArray *langs   = [NSMutableArray array];
    NSInteger count = MIN(languagesNames.count, languagesIDs.count);
    for (NSInteger i = 0 ; i < count ; ++i)
        [langs addObject:@{ @"name": [LanguageTable localize:languagesNames[i]],
                            @"id":   languagesIDs[i] }];
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES
                                                            selector:@selector(caseInsensitiveCompare:)];
    languages = [langs sortedArrayUsingDescriptors:@[sort]];
    
    lastSel = nil;
    NSInteger i = 0;
    NSString *selectedLanguage = [[NSUserDefaults standardUserDefaults] stringForKey:@"langID"];
    for (NSDictionary *language in languages)
    {
        if ([language[@"id"] isEqualToString:selectedLanguage])
            lastSel = [NSIndexPath indexPathForRow:i inSection:2];
        i++;
    }
    
    UIView *backView = [UIView new];
    [backView setBackgroundColor:[UIColor colorWithWhite:0.23 alpha:1]];
    [self.tableView setBackgroundView:backView];
    
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
    
    if ([[UIKeyCommand class] instancesRespondToSelector:@selector(setDiscoverabilityTitle:)])
    {
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow
                                                modifierFlags:0
                                                       action:@selector(keyArrow:)
                                         discoverabilityTitle:NSLocalizedString(@"Select Previous Language", @"")]];
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow
                                                modifierFlags:0
                                                       action:@selector(keyArrow:)
                                         discoverabilityTitle:NSLocalizedString(@"Select Next Language", @"")]];
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:@"\r"
                                                modifierFlags:0
                                                       action:@selector(enterKey)
                                         discoverabilityTitle:NSLocalizedString(@"Choose Language", @"")]];
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:UIKeyInputEscape
                                                modifierFlags:0
                                                       action:@selector(close)
                                         discoverabilityTitle:NSLocalizedString(@"Dismiss Languages", @"")]];
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    settings = @[NSLocalizedString(self.view.frame.size.width > 330 ? @"Remember Last Search" : @"Remember Last Search small", @"")];
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger) tableView:(UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
        return [settings count] + 1;
    if (section == 1)
        return [sortSettings count];
    return [languages count];
}

- (NSString *) tableView:(UITableView *)tableView
 titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return nil;
    if (section == 1)
        return NSLocalizedString(@"Sort Search Results by", @"");
    return [languages count] ? NSLocalizedString(@"Second Search Language", @"")
                             : NSLocalizedString(@"Second Search Language Empty", @"");
}

- (UITableViewCell *) tableView:(UITableView *)tableView
          cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"langCell" forIndexPath:indexPath];
    
    cell.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1]; // iPad fix
    cell.selectedBackgroundView = [[UIView alloc] initWithFrame:cell.bounds];
    cell.selectedBackgroundView.backgroundColor = [UIColor darkGrayColor];
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.textColor = [UIColor whiteColor];
    
    if (indexPath.section == 0 && indexPath.row == settings.count)
    {
        cell.textLabel.text = NSLocalizedString(@"Clear Search History", @"");
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.textLabel.textColor = [UIColor lightGrayColor];
        cell.accessoryType = UITableViewCellAccessoryNone;
        return cell;
    }
    
    if (indexPath.section == 0)
        cell.textLabel.text = settings[indexPath.row];
    else if (indexPath.section == 1)
        cell.textLabel.text = sortSettings[indexPath.row];
    else if (indexPath.section == 2)
        cell.textLabel.text = languages[indexPath.row][@"name"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ((indexPath.section == 0 && [defaults boolForKey:settingsKeys[indexPath.row]]) ||
        (indexPath.section == 1 && [defaults boolForKey:sortSettingsKeys[indexPath.row]]) ||
        (indexPath.section == 2 && [languages[indexPath.row][@"id"] isEqualToString:[defaults stringForKey:@"langID"]]))
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}

- (void)      tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (indexPath.section == 2)
    {
        if (lastSel)
            [tableView cellForRowAtIndexPath:lastSel].accessoryType = UITableViewCellAccessoryNone;
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
        lastSel = indexPath;
        
        NSDictionary *language = languages[indexPath.row];
        [defaults setValue:language[@"name"] forKey:@"langName"];
        [defaults setValue:language[@"id"]   forKey:@"langID"];
        [defaults synchronize];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"updateLanguage" object:nil];
    }
    else
    {
        BOOL value;
        if (indexPath.section == 0)
        {
            if (indexPath.row == settings.count)
            {
                [self clearHistory];
                return;
            }
            
            value = ![defaults boolForKey:settingsKeys[indexPath.row]];
            [defaults setBool:value forKey:settingsKeys[indexPath.row]];
        }
        else if (indexPath.section == 1)
        {
            value = ![defaults boolForKey:sortSettingsKeys[indexPath.row]];
            [defaults setBool:value forKey:sortSettingsKeys[indexPath.row]];
        }
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = (value) ? UITableViewCellAccessoryCheckmark
                                                                            : UITableViewCellAccessoryNone;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Actions

+ (NSString *) localize:(NSString *)lang
{
    return NSLocalizedString(lang, @"");
}

- (IBAction) close
{
    [self dismissViewControllerAnimated:YES completion:nil];
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

- (void) clearHistory
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Clear searches title", @"")
                                                                   message:NSLocalizedString(@"Clear searches message", @"")
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Clear Searches", @"") style:UIAlertActionStyleDestructive
                                            handler:^(UIAlertAction * _Nonnull action) {
        [[NSUserDefaults standardUserDefaults] setObject:@[] forKey:@"previousSearches"];
        [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
