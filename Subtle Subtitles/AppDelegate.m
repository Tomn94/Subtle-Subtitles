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
    [[Data sharedData] updateNetwork:0];
    
    [CJPAdController sharedInstance].adNetworks = @[@(CJPAdNetworkAdMob)];
    [CJPAdController sharedInstance].adPosition = CJPAdPositionBottom;
    [CJPAdController sharedInstance].initialDelay = 2.0;
    [CJPAdController sharedInstance].adMobUnitID = @"ca-app-pub-5043679231014485/5228181857";
    [[CJPAdController sharedInstance] setTestDeviceIDs:@[@"7bf93d1f07cb039c3a523bc37ba84bdd"]]; // TEST_EMULATOR pour avoir l'ID
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *navController = (UINavigationController*)[storyboard instantiateInitialViewController];
    [[CJPAdController sharedInstance] startWithViewController:navController];
    self.window.rootViewController = [CJPAdController sharedInstance];
    
    return YES;
}

- (void) applicationWillResignActive:(UIApplication *)application
{
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

@end
