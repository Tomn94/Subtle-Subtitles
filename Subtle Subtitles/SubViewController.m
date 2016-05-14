//
//  SubViewController.m
//  Subtle Subtitles
//
//  Created by Tomn on 26/03/2016.
//  Copyright © 2016 Tomn. All rights reserved.
//

#import "SubViewController.h"

@implementation ShowControlsView

- (void) touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showControls" object:nil];
}

- (void) touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"showControls" object:nil];
}

@end


@implementation SubViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    time = .0f;
    delay = .0f;
    curIndex = -1;
    playing = NO;
    srt = nil;
    fileName = [NSString stringWithFormat:@"/%@", [[Data sharedData] currentFileName]];
    if (fileName == nil || [fileName isEqualToString:@""] || [fileName isEqualToString:@"/"])
        fileName = @"/sub.srt";
    [self.slider setThumbImage:[UIImage imageNamed:@"thumb"] forState:UIControlStateNormal];
    
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingString:fileName];
    NSString *htmlString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    if (htmlString == nil)
        htmlString = [NSString stringWithContentsOfFile:path encoding:NSISOLatin1StringEncoding error:nil];
    if (htmlString == nil)
        htmlString = [NSString stringWithContentsOfFile:path encoding:NSASCIIStringEncoding error:nil];
    if (htmlString != nil)
    {
        self.subLabel.text = @"";
        
        srt = [self parse:htmlString];
        self.slider.maximumValue = [[srt lastObject][@"to"] doubleValue];
        
        playing = YES;
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timer) userInfo:nil repeats:YES];
    }
    else
        self.navigationItem.rightBarButtonItems = nil;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stop) name:@"stopTimerSub" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showControls) name:@"showControls" object:nil];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.navigationController.hidesBarsOnSwipe = YES;
    autohideTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(hideControls) userInfo:nil repeats:NO];
    [self showControls];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.hidesBarsOnSwipe = NO;
    [self stop];
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - Actions

- (void) playTapped:(id)sender
{
    playing = !playing;
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:playing];
    if (playing)
    {
        if (time >= self.slider.maximumValue)
        {
            time = 0;
            curIndex = 0;
            self.slider.value = 0;
        }
        timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timer) userInfo:nil repeats:YES];
    }
    else
        [timer invalidate];
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:(playing) ? UIBarButtonSystemItemPause
                                                                                           : UIBarButtonSystemItemPlay
                                                                          target:self
                                                                          action:@selector(playTapped:)];
    if (_shareButton != nil)
        self.navigationItem.rightBarButtonItems = @[_shareButton, item];
}

- (void) stop
{
    playing = NO;
    [timer invalidate];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                                                                          target:self
                                                                          action:@selector(playTapped:)];
    if (_shareButton != nil)
        self.navigationItem.rightBarButtonItems = @[_shareButton, item];
}

- (IBAction) scrub:(id)sender
{
    time = self.slider.value;
    curIndex = 0;
    [self updateText];
    [self showControls];
}

- (void) timer
{
    time += 0.1;
    self.slider.value = time;
    [self updateText];
}

- (void) updateText
{
    if (srt == nil || time >= self.slider.maximumValue + delay)
    {
        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                                                                              target:self
                                                                              action:@selector(playTapped:)];
        self.navigationItem.rightBarButtonItems = @[_shareButton, item];
        [timer invalidate];
        playing = NO;
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
        return;
    }
    
    NSInteger srtc = [srt count];
    NSInteger found = -1;
    for (NSInteger i = (curIndex < 0 ) ? 0 : curIndex ; i < srtc ; ++i)
    {
        NSDictionary *infos = srt[i];
        if (time >= [infos[@"from"] doubleValue] + delay && time <= [infos[@"to"] doubleValue] + delay)
            found = i;
    }
    
    if (found != -1)
    {
        curIndex = found;
        self.subLabel.text = srt[curIndex][@"text"];
    }
    else
        self.subLabel.text = @"";
}

- (NSArray *) parse:(NSString *)srtData
{
    NSMutableArray *parts = [NSMutableArray array];
    
    srtData = [srtData stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    srtData = [srtData stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
    NSArray *lines = [srtData componentsSeparatedByString:@"\n"];
    kSRTState state = kNUMBER;
    NSString *curTime = @"";
    NSString *curText = @"";
    
    for (NSString *line in lines)
    {
        NSString *tLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        switch (state)
        {
            case kNUMBER:
            {
                if (![tLine isEqualToString:@""])
                {
                    state = kTIME;
                    curText = @"";
                }
                break;
            }
                
            case kTIME:
                curTime = tLine;
                state = kTEXT;
                break;
                
            case kTEXT:
            {
                if ([tLine isEqualToString:@""])
                {
                    NSArray *times   = [curTime componentsSeparatedByString:@"-->"];
                    if (times.count > 1)
                    {
                        NSString *debutS = [times[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                        NSString *finS   = [times[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                        
                        NSArray *t = [debutS componentsSeparatedByString:@":"];
                        NSArray *s = [t[2]   componentsSeparatedByString:@","];
                        NSTimeInterval debut = ([t[0] intValue] * 3600) + ([t[1] intValue] * 60) + [s[0] intValue] + ([s[1] intValue] / 1000);
                        t = [finS componentsSeparatedByString:@":"];
                        s = [t[2] componentsSeparatedByString:@","];
                        NSTimeInterval fin = ([t[0] intValue] * 3600) + ([t[1] intValue] * 60) + [s[0] intValue] + ([s[1] intValue] / 1000);
                        
                        [parts addObject:@{ @"from": @(debut),
                                            @"to"  : @(fin),
                                            @"text": curText }];
                        state = kNUMBER;
                    }
                }
                else
                    curText = [NSString stringWithFormat:@"%@ %@", curText, tLine];
                break;
            }
        }
    }
    
    return [NSArray arrayWithArray:parts];
}

- (IBAction) delay:(id)sender
{
    delay = self.stepper.value / 10;
    self.stepperValue.text = [NSString stringWithFormat:@"%.1f s", delay];
    [self showControls];
}

- (IBAction) share:(id)sender
{
    doc = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingString:fileName]]];
    if (![doc presentOpenInMenuFromRect:self.view.frame inView:self.view animated:YES])
        [doc presentOptionsMenuFromRect:self.view.frame inView:self.view animated:YES];
}

- (void) hideControls
{
    [UIView animateWithDuration:0.7
                     animations:^{
                         _slider.alpha = 0;
                         _stepper.alpha = 0;
                         _stepperValue.alpha = 0;
                     }];
}

- (void) showControls
{
    [autohideTimer invalidate];
    autohideTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(hideControls) userInfo:nil repeats:NO];
    
    [UIView animateWithDuration:0.2
                     animations:^{
                         _slider.alpha = 1;
                         _stepper.alpha = 1;
                         _stepperValue.alpha = 1;
                     }];
}

@end
