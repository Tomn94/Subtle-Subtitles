//
//  SubViewController.h
//  Subtle Subtitles
//
//  Created by Tomn on 26/03/2016.
//  Copyright © 2016 Tomn. All rights reserved.
//

@import UIKit;
#import "Data.h"

typedef enum : NSUInteger {
    kNUMBER,
    kTIME,
    kTEXT
} kSRTState;

@interface ShowControlsView : UIView
@end

@interface SubViewController : UIViewController
{
    NSTimeInterval time;
    BOOL playing;
    NSTimer *timer;
    NSArray *srt;
    NSInteger curIndex;
    NSTimeInterval delay;
    NSString *fileName;
    UIDocumentInteractionController *doc;
    NSTimer *autohideTimer;
    NSString *maxTimeLabel;
    NSString *htmlForSub;
    NSStringEncoding encoding;
    BOOL forceShowControls;
}

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UILabel *subLabel;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIStepper *stepper;
@property (weak, nonatomic) IBOutlet UILabel *stepperValue;

- (IBAction) playTapped:(id)sender;
- (void) stop;
- (IBAction) scrub:(id)sender;
- (void) timer;
- (void) updateTime;
- (void) updateText;
- (NSArray *) parse:(NSString *)srtData;
- (IBAction) delay:(id)sender;
- (IBAction) share:(UIBarButtonItem *)sender;
- (void) showControls;

- (void) back;
- (void) keyArrow:(UIKeyCommand *)sender;
- (void) keyArrowCmd:(UIKeyCommand *)sender;

@end
