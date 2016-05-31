//
//  Data.h
//  Subtle Subtitles
//
//  Created by Thomas Naudet on 27/03/2016.
//  Copyright © 2016 Thomas Naudet. All rights reserved.
//  This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/
//

@import Foundation;
@import UIKit;
@import StoreKit;
#import "CJPAdController.h"
#import "OROpenSubtitleDownloader.h"

#define ADS_ID @"com.tomn.SubtleSubtitles.ads"

@interface Data : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>

+ (Data *) sharedData;

@property (strong, nonatomic) NSArray *langNames;
@property (strong, nonatomic) NSArray *langIDs;
@property (assign, nonatomic) NSInteger networkCount;
@property (strong, nonatomic) OpenSubtitleSearchResult *currentFile;

- (void) updateNetwork:(int)diff;
- (void) startPurchase;
- (void) restorePurchase;

@end
