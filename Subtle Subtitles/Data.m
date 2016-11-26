//
//  Data.m
//  Subtle Subtitles
//
//  Created by Thomas Naudet on 27/03/2016.
//  Copyright © 2016 Thomas Naudet. All rights reserved.
//  This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/
//

#import "Data.h"

@implementation Data

+ (Data *) sharedData
{
    static Data *instance = nil;
    if (instance == nil)
    {
        static dispatch_once_t pred;        // Lock
        dispatch_once(&pred, ^{             // This code is called at most once per app
            instance = [[Data allocWithZone:NULL] init];
        });
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults registerDefaults:@{ @"langID": @"fre",
                                      @"langName": @"French",
                                      @"langIndex": @0,
                                      @"defaultPointSize": @28.0f,
                                      @"ratings" : @YES,
                                      @"down" : @YES,
                                      @"cc" : @NO,
                                      @"hd" : @NO,
                                      @"rememberLastSearch" : @YES,
                                      @"previousSearches" : @[],
                                      @"preferredEncoding" : @(NSUTF8StringEncoding) }];
        [defaults removeObjectForKey:@"lastSearch"];
        [defaults synchronize];
        
        [Data updateDynamicShortcutItems];
        
        // Nettoyage des données précédentes
        NSString *extension = @"srt";
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        
        NSArray *contents = [fileManager contentsOfDirectoryAtPath:documentsDirectory error:NULL];
        NSEnumerator *e = [contents objectEnumerator];
        NSString *filename;
        while ((filename = [e nextObject])) {
            if ([[filename pathExtension] isEqualToString:extension])
                [fileManager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:filename] error:NULL];
        }
        
        instance.networkCount = 0;
        
        [[SKPaymentQueue defaultQueue] addTransactionObserver:instance];
    }
    return instance;
}

+ (BOOL) hasCachedFile:(NSString *)name
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    
    return [fileManager fileExistsAtPath:[documentsDirectory stringByAppendingString:[NSString stringWithFormat:@"/%@", name]]];
}

- (void) updateNetwork:(int)diff
{
    _networkCount += diff;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:_networkCount];
}

#pragma mark - OROpenSubtitleDownloader delegate

- (void) openSubtitlerDidLogIn:(OROpenSubtitleDownloader *)downloader
{
    [[Data sharedData] updateNetwork:1];
    [downloader supportedLanguagesList:^(NSArray *languages, NSError *error) {
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
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"updateLangages" object:nil];
        }/*
        else
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Unable to fetch available languages", @"")
                                                                           message:error.localizedDescription
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleCancel handler:nil]];
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
        }*/
        [[Data sharedData] updateNetwork:-1];
    }];
}

#pragma mark - 3D Touch shortcuts

/** Add previous searches to 3D Touch shortcuts */
+ (void) updateDynamicShortcutItems
{
    if ([[[UIDevice currentDevice] systemVersion] compare:@"9" options:NSNumericSearch] != NSOrderedAscending) {
        NSArray *previous = [[NSUserDefaults standardUserDefaults] arrayForKey:@"previousSearches"];
        NSMutableArray *shortcutItems = [NSMutableArray array];
        
        int nbr = 0, max = 5;   // Some kind of watchdog
        for (NSString *previousSearch in previous) {
            [shortcutItems addObject:[[UIApplicationShortcutItem alloc] initWithType:QUICKACTIONS_ID
                                                                      localizedTitle:previousSearch.capitalizedString
                                                                   localizedSubtitle:nil
                                                                                icon:[UIApplicationShortcutIcon iconWithType:UIApplicationShortcutIconTypeSearch]
                                                                            userInfo:nil]];
            nbr++;
            if (nbr > max)
                break;
        }
        
        [UIApplication sharedApplication].shortcutItems = shortcutItems;
    }
}

#pragma mark - Taptic Engine

+ (void) feedbackAfterAction:(UINotificationFeedbackType)feedbackType
{
    if ([[[UIDevice currentDevice] systemVersion] compare:@"10" options:NSNumericSearch] != NSOrderedAscending) {
        if (feedbackType == UINotificationFeedbackTypeSuccess) {
            UISelectionFeedbackGenerator *generator = [UISelectionFeedbackGenerator new];
            [generator prepare];
            [generator selectionChanged];
        } else {
            UINotificationFeedbackGenerator *generator = [UINotificationFeedbackGenerator new];
            [generator prepare];
            [generator notificationOccurred:feedbackType];
        }
    }
}

#pragma mark - In-App Purchase

- (void) startPurchase
{
    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:ADS_ID]];
    request.delegate = self;
    [request start];
    [self updateNetwork:1];
}

- (void) restorePurchase
{
    [self updateNetwork:1];
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void) productsRequest:(SKProductsRequest *)request
      didReceiveResponse:(SKProductsResponse *)response
{
    SKProduct *validProduct = nil;
    NSUInteger count = [response.products count];
    
    if (count > 0)
    {
        validProduct = [response.products firstObject];
        
        SKPayment *payment = [SKPayment paymentWithProduct:validProduct];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
    else
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"This purchase can't be bought", @"")
                                                                       message:NSLocalizedString(@"No purchase are currently available for sale.", @"")
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleCancel handler:nil]];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
        [self updateNetwork:-1];
    }
}

- (void) paymentQueue:(SKPaymentQueue *)queue
  updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        if ([transaction.payment.productIdentifier isEqualToString:ADS_ID])
        {
            switch (transaction.transactionState)
            {
                case SKPaymentTransactionStatePurchased:
                {
                    [self updateNetwork:-1];
                    [[CJPAdController sharedInstance] removeAdsAndMakePermanent:YES andRemember:YES];
                    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                    
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Thanks !", @"")
                                                                                   message:NSLocalizedString(@"Ads won't appear anymore on your devices.", @"")
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Great", @"") style:UIAlertActionStyleCancel handler:nil]];
                    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
                    break;
                }
                case SKPaymentTransactionStateRestored:
                {
                    [self updateNetwork:-1];
                    [[CJPAdController sharedInstance] removeAdsAndMakePermanent:YES andRemember:YES];
                    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                    
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Ads have been removed!", @"")
                                                                                   message:NSLocalizedString(@"Your previous purchase has been restored.", @"")
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Great", @"") style:UIAlertActionStyleCancel handler:nil]];
                    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
                    break;
                }
                case SKPaymentTransactionStateFailed:
                case SKPaymentTransactionStateDeferred:
                    [self updateNetwork:-1];
                    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                    break;
                case SKPaymentTransactionStatePurchasing:
                default:
                    break;
            }
        }
    }
}

- (void) request:(SKRequest *)request
didFailWithError:(NSError *)error
{
    [self updateNetwork:-1];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Can't complete the purchase", @"")
                                                                   message:error.localizedDescription
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleCancel handler:nil]];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}

- (void) paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    for (SKPaymentTransaction *transaction in queue.transactions)
    {
        if ([transaction.payment.productIdentifier isEqualToString:ADS_ID])
            [[CJPAdController sharedInstance] removeAdsAndMakePermanent:YES andRemember:YES];
    }
}

- (void)                       paymentQueue:(SKPaymentQueue *)queue
restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    [self updateNetwork:-1];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Can't restore the purchase", @"")
                                                                   message:error.localizedDescription
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"") style:UIAlertActionStyleCancel handler:nil]];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}

@end
