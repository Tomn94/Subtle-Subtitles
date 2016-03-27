//
//  Data.m
//  Subtle Subtitles
//
//  Created by Tomn on 27/03/2016.
//  Copyright © 2016 Tomn. All rights reserved.
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
                                      @"langIndex": @0 }];
        [defaults synchronize];
        
        instance.networkCount = 0;
    }
    return instance;
}

- (void) updateNetwork:(int)diff
{
    _networkCount += diff;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:_networkCount];
}

@end
