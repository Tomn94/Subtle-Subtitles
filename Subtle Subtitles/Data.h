//
//  Data.h
//  Subtle Subtitles
//
//  Created by Tomn on 27/03/2016.
//  Copyright © 2016 Tomn. All rights reserved.
//

@import Foundation;
@import UIKit;

@interface Data : NSObject

+ (Data *) sharedData;

@property (strong, nonatomic) NSArray *langNames;
@property (strong, nonatomic) NSArray *langIDs;
@property (assign, nonatomic) NSInteger networkCount;

- (void) updateNetwork:(int)diff;

@end
