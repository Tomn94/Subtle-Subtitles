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
    
    langNames = [Data sharedData].langNames;
    langIDs   = [Data sharedData].langIDs;
    settings = @[NSLocalizedString(@"Remember Last Search", @"")];
    settingsKeys = @[@"rememberLastSearch"];
    sortSettings = @[NSLocalizedString(@"Download Number", @""),
                     NSLocalizedString(@"Ratings", @""),
                     NSLocalizedString(@"CC (Hearing Impaired)", @""),
                     NSLocalizedString(@"HD", @"")];
    sortSettingsKeys = @[@"ratings", @"down", @"cc", @"hd"];
    NSUInteger index = [langIDs indexOfObject:[[NSUserDefaults standardUserDefaults] stringForKey:@"langID"]];
    if (index != NSNotFound)
        lastSel = [NSIndexPath indexPathForRow:index inSection:0];
    else
        lastSel = nil;
    
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
    if (section == 2)
        return [settings count];
    if (section == 0)
        return [sortSettings count];
    return [langNames count];
}

- (NSString *) tableView:(UITableView *)tableView
 titleForHeaderInSection:(NSInteger)section
{
    if (section == 2)
        return nil;
    if (section == 0)
        return NSLocalizedString(@"Sort Search Results by", @"");
    return NSLocalizedString(@"Second Search Language", @"");
}

- (UITableViewCell *) tableView:(UITableView *)tableView
          cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"langCell" forIndexPath:indexPath];
    
    if (indexPath.section == 0)
        cell.textLabel.text = settings[indexPath.row];
    else if (indexPath.section == 1)
        cell.textLabel.text = sortSettings[indexPath.row];
    else if (indexPath.section == 2)
        cell.textLabel.text = langNames[indexPath.row];
    
    cell.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1]; // iPad fix
    cell.selectedBackgroundView = [[UIView alloc] initWithFrame:cell.bounds];
    cell.selectedBackgroundView.backgroundColor = [UIColor darkGrayColor];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ((indexPath.section == 2 && [defaults boolForKey:settingsKeys[indexPath.row]]) ||
        (indexPath.section == 0 && [defaults boolForKey:sortSettingsKeys[indexPath.row]]) ||
        (indexPath.section == 1 && [langIDs[indexPath.row] isEqualToString:[defaults stringForKey:@"langID"]]))
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}

- (void)      tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (indexPath.section == 1)
    {
        if (lastSel)
            [tableView cellForRowAtIndexPath:lastSel].accessoryType = UITableViewCellAccessoryNone;
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
        lastSel = indexPath;
        
        [defaults setValue:langIDs[indexPath.row]   forKey:@"langID"];
        [defaults setValue:langNames[indexPath.row] forKey:@"langName"];
        [defaults synchronize];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"updateLanguage" object:nil];
    }
    else
    {
        BOOL value;
        if (indexPath.section == 2)
        {
            value = ![defaults boolForKey:settingsKeys[indexPath.row]];
            [defaults setBool:value forKey:settingsKeys[indexPath.row]];
        }
        else if (indexPath.section == 0)
        {
            value = ![defaults boolForKey:sortSettingsKeys[indexPath.row]];
            [defaults setBool:value forKey:sortSettingsKeys[indexPath.row]];
        }
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = (value) ? UITableViewCellAccessoryCheckmark
                                                                            : UITableViewCellAccessoryNone;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (IBAction) close
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:@"rememberLastSearch"])
        [defaults removeObjectForKey:@"lastSearch"];
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

@end
