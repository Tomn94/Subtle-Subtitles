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
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
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
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
