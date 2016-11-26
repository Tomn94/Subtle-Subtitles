//
//  SubViewController.h
//  Subtle Subtitles
//
//  Created by Thomas Naudet on 26/03/2016.
//  Copyright © 2016 Thomas Naudet. All rights reserved.
//  This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/
//

@import UIKit;
#import <TUSafariActivity.h>
#import "Data.h"
#import "Subtle_Subtitles-Swift.h"

typedef enum : NSUInteger {
    kNUMBER,
    kTIME,
    kTEXT
} kSRTState;

@interface SubViewController : UIViewController <UIDocumentInteractionControllerDelegate, UIPopoverPresentationControllerDelegate>
{
    NSTimeInterval time;
    BOOL playing;
    NSTimer *timer;
    NSArray *srt;
    NSInteger curIndex;
    NSTimeInterval delay;
    NSString *fileName;
    UIActivityViewController *docAct;
    UIDocumentInteractionController *doc;
    NSTimer *autohideTimer;
    NSString *maxTimeLabel;
    NSStringEncoding encoding;
    BOOL forceShowControls;
    BOOL forceTextRedraw;
}

@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UILabel *subLabel;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIStepper *stepper;
@property (weak, nonatomic) IBOutlet UILabel *stepperValue;

- (void) loadWithEncoding;
- (IBAction) playTapped:(id)sender;
- (void) stop;
- (IBAction) scrub:(id)sender;
- (void) timer;
- (void) updateTime;
- (void) updateText;
- (NSArray *) parse:(NSString *)srtData;
- (IBAction) delay:(id)sender;
- (IBAction) share:(UIBarButtonItem *)sender;
- (IBAction) openIn:(UIBarButtonItem *)sender;
- (void) showControls;

- (void) pinch:(UIPinchGestureRecognizer *)g;

- (void) back;
- (void) keyArrow:(UIKeyCommand *)sender;
- (void) keyArrowCmd:(UIKeyCommand *)sender;
- (void) zoomText:(UIKeyCommand *)sender;

@end


@interface SafariActivity : TUSafariActivity
@end

@interface DownActivity : UIActivity
@end

@interface ActivityTextProvider : UIActivityItemProvider
@end

@interface ActivityLinkProvider : UIActivityItemProvider
@end
