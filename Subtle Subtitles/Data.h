//
//  Data.h
//  Subtle Subtitles
//
//  Created by Tomn on 27/03/2016.
//  Copyright © 2016 Tomn. All rights reserved.
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
