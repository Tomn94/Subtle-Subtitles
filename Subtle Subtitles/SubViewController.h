//
//  SubViewController.h
//  Subtle Subtitles
//
//  Created by Tomn on 26/03/2016.
//  Copyright © 2016 Tomn. All rights reserved.
//

@import UIKit;

typedef enum : NSUInteger {
    kNUMBER,
    kTIME,
    kTEXT
} kSRTState;

@interface SubViewController : UIViewController
{
    NSTimeInterval time;
    BOOL playing;
    NSTimer *timer;
    NSArray *srt;
    NSInteger curIndex;
}

@property (weak, nonatomic) IBOutlet UILabel *subLabel;
@property (weak, nonatomic) IBOutlet UISlider *slider;

- (IBAction) playTapped:(id)sender;
- (IBAction) scrub:(id)sender;
- (void) timer;
- (void) updateText;
- (NSArray *) parse:(NSString *)srtData;

@end
