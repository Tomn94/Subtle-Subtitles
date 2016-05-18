//
//  LanguageTable.m
//  Subtle Subtitles
//
//  Created by Tomn on 27/03/2016.
//  Copyright © 2016 Tomn. All rights reserved.
//

#import "LanguageTable.h"

@implementation LanguageTable

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    langNames = [Data sharedData].langNames;
    langIDs   = [Data sharedData].langIDs;
    NSUInteger index = [langIDs indexOfObject:[[NSUserDefaults standardUserDefaults] stringForKey:@"langID"]];
    if (index != NSNotFound)
        lastSel = [NSIndexPath indexPathForRow:index inSection:0];
    else
        lastSel = nil;
    
    UIView *backView = [UIView new];
    [backView setBackgroundColor:[UIColor colorWithWhite:0.2 alpha:1]];
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
                                         discoverabilityTitle:@"Select Previous Language"]];
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow
                                                modifierFlags:0
                                                       action:@selector(keyArrow:)
                                         discoverabilityTitle:@"Select Next Language"]];
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:@"\r"
                                                modifierFlags:0
                                                       action:@selector(enterKey)
                                         discoverabilityTitle:@"Choose Language"]];
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:UIKeyInputEscape
                                                modifierFlags:0
                                                       action:@selector(close)
                                         discoverabilityTitle:@"Dismiss Languages"]];
    }
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    NSUInteger pos = [langIDs indexOfObject:[[NSUserDefaults standardUserDefaults] stringForKey:@"langID"]];
    if (pos != NSNotFound && [self tableView:self.tableView numberOfRowsInSection:0] > pos)
    {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:pos inSection:0]
                              atScrollPosition:UITableViewScrollPositionMiddle
                                      animated:YES];
        KBTableView *tableView = (KBTableView *)self.tableView;
        [tableView setCurrentlyFocussedIndex:[NSIndexPath indexPathForRow:pos inSection:0]];
    }
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
    return [langNames count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView
          cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"langCell" forIndexPath:indexPath];
    
    cell.textLabel.text = langNames[indexPath.row];
    
    cell.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1]; // iPad fix
    cell.selectedBackgroundView = [[UIView alloc] initWithFrame:cell.bounds];
    cell.selectedBackgroundView.backgroundColor = [UIColor darkGrayColor];
    
    if ([langIDs[indexPath.row] isEqualToString:[[NSUserDefaults standardUserDefaults] stringForKey:@"langID"]])
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
        cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}

- (void)      tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (lastSel)
        [tableView cellForRowAtIndexPath:lastSel].accessoryType = UITableViewCellAccessoryNone;
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
    lastSel = indexPath;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:langIDs[indexPath.row]   forKey:@"langID"];
    [defaults setValue:langNames[indexPath.row] forKey:@"langName"];
    [defaults synchronize];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"updateLanguage" object:nil];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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

@end
