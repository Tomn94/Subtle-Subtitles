//
//  AppDelegate.m
//  Subtle Subtitles
//
//  Created by Tomn on 26/03/2016.
//  Copyright © 2016 Thomas Naudet. All rights reserved.
//  This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)          application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    UIColor *tintColor = [UIColor colorWithRed:1 green:65/255. blue:80/255. alpha:1];
    _window.tintColor = tintColor;
    [UIView appearance].tintColor = tintColor;
    [UINavigationBar appearance].tintColor = tintColor;
    [UISearchBar appearance].barTintColor = [UIColor colorWithWhite:0.25 alpha:1];
    [[Data sharedData] updateNetwork:0];
    
    [CJPAdController sharedInstance].adNetworks = @[@(CJPAdNetworkAdMob)];
    [CJPAdController sharedInstance].adPosition = CJPAdPositionBottom;
    [CJPAdController sharedInstance].initialDelay = 2.0;
    [CJPAdController sharedInstance].adMobUnitID = @"ca-app-pub-5043679231014485/5228181857";
    [[CJPAdController sharedInstance] setTestDeviceIDs:@[@"7bf93d1f07cb039c3a523bc37ba84bdd"]]; // TEST_EMULATOR pour avoir l'ID
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    navController = (UINavigationController*)[storyboard instantiateInitialViewController];
    [[CJPAdController sharedInstance] startWithViewController:navController];
    self.window.rootViewController = [CJPAdController sharedInstance];
    
    return YES;
}

- (void) applicationWillResignActive:(UIApplication *)application
{
    [Data updateDynamicShortcutItems];
    
    // ENABLE THIS IF YOU WANT TO FREEZE THE TEXT WHEN THE APP LOSES FOCUS
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"stopTimerSub" object:nil];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - 3D Touch

- (void)         application:(UIApplication *)application
performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem
           completionHandler:(void (^)(BOOL))completionHandler
{
    if ([shortcutItem.type isEqualToString:QUICKACTIONS_ID]) {
        NSArray *vcs = navController.viewControllers;
        if ([vcs.lastObject isKindOfClass:[SearchTable class]]) {
            /* Target view controller found */
            SearchTable *table = (SearchTable *)vcs.lastObject;
            
            /* Don't dismiss search (bar) if already open, otherwise dismiss any dialog or pushed VC */
            if (![table isSearchOpen]) {
                [navController.presentedViewController dismissViewControllerAnimated:YES completion:nil];
                [navController popToRootViewControllerAnimated:YES];
            }
            
            /* Search for Shortcut Title, with a delay if app launches */
            double delayInSeconds = 0.1;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^{
                [table searchFor:[NSString stringWithFormat:@"%@ ", shortcutItem.localizedTitle]];
            });
        }
    }
    
    completionHandler(YES);
}

#pragma mark - Import with…

- (BOOL) application:(UIApplication *)application
             openURL:(NSURL *)url
   sourceApplication:(NSString *)sourceApplication
          annotation:(id)annotation
{
    NSString *format = url.pathExtension.lowercaseString;
    
    /* Only support SRT files */
    BOOL fileOK = [format isEqualToString:@"srt"];
    if (fileOK) {
        /* Copy the file from Documents/Inbox to Library/Caches/ */
        NSError *error = nil;
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        NSString *fileName = url.lastPathComponent;
        NSURL  *newURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@", path, fileName]];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        // Overwrite if already exists
        if ([fileManager fileExistsAtPath:newURL.path])
            [fileManager removeItemAtURL:newURL error:&error];
        if (error == nil)
            [fileManager moveItemAtURL:url toURL:newURL error:&error];
        
        if (error == nil) {
            /* Create the subtitles object */
            NSDictionary *subInfo = @{ @"IDSubtitleFile": @"",
                                       @"IDMovieImdb": @"",
                                       @"SubLanguageID": @"",
                                       @"SubFileName": fileName,
                                       @"SubRating": @0.0,
                                       @"SubFormat": format,
                                       @"IDMovieImdb": @"",
                                       @"MovieYear": @"",
                                       @"ISO639": @"",
                                       @"SubDownloadLink": @"",
                                       @"SubtitlesLink": @"",
                                       @"SubHearingImpaired": @"0",
                                       @"SubDownloadsCnt": @0,
                                       @"SubBad": @"0",
                                       @"MovieName": @"",
                                       @"SubLastTS": @"",
                                       @"SubSize": @"",
                                       @"SubHD": @"0",
                                       @"SubAddDate": @"" };
            OpenSubtitleSearchResult *fileInfo = [OpenSubtitleSearchResult resultFromDictionary:subInfo];
            
            /* Load the subtitles */
            [[Data sharedData] setCurrentFile:fileInfo];
            [navController popToRootViewControllerWithCompletion:^{
                [navController performSegueWithIdentifier:@"detailSegue" sender:self];
            }];
        } else {
            /* I/O error */
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"ImportSRTIOErrorTitle", @"Error opening file")
                                                                           message:[NSString stringWithFormat:@"%@\n\n%@",
                                                                                    NSLocalizedString(@"ImportSRTIOErrorMessage", @"Can't be moved"),
                                                                                    error.localizedDescription]
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ImportSRTIOErrorButton", @"OK")
                                                      style:UIAlertActionStyleCancel handler:nil]];
            if (navController.presentedViewController != nil)
                [navController.presentedViewController presentViewController:alert animated:YES completion:nil];
            else
                [navController presentViewController:alert animated:YES completion:nil];
        }
    }
    
    return fileOK;
}

@end
