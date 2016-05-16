//
//  SubViewController.m
//  Subtle Subtitles
//
//  Created by Tomn on 26/03/2016.
//  Copyright © 2016 Tomn. All rights reserved.
//

#import "SubViewController.h"

@implementation ShowControlsView

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
    
    htmlForSub = [NSString stringWithFormat:@"<p style=\"color: white; text-align: center; font-family: '-apple-system', HelveticaNeue; font-size: %fpx\">", _subLabel.font.pointSize];
    maxTimeLabel = @"00:00";
    _stepperValue.font = [UIFont monospacedDigitSystemFontOfSize:_stepperValue.font.pointSize
                                                          weight:UIFontWeightRegular];
    _timeLabel.font = [UIFont monospacedDigitSystemFontOfSize:_timeLabel.font.pointSize
                                                       weight:UIFontWeightRegular];
    [self.slider setThumbImage:[UIImage imageNamed:@"thumb"] forState:UIControlStateNormal];
    
    fileName = [NSString stringWithFormat:@"/%@", [[Data sharedData] currentFileName]];
    if (fileName == nil || [fileName isEqualToString:@""] || [fileName isEqualToString:@"/"])
        fileName = @"/sub.srt";
    
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingString:fileName];
    doc = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:path]];
    
    encoding = NSUTF8StringEncoding;
    NSString *htmlString = [NSString stringWithContentsOfFile:path encoding:encoding error:nil];
    if (htmlString == nil)
    {
        encoding = NSISOLatin1StringEncoding;
        htmlString = [NSString stringWithContentsOfFile:path encoding:encoding error:nil];
    }
    if (htmlString == nil)
    {
        encoding = NSASCIIStringEncoding;
        htmlString = [NSString stringWithContentsOfFile:path encoding:encoding error:nil];
    }
    if (htmlString != nil)
    {
        self.subLabel.text = @"";
        
        srt = [self parse:htmlString];
        unsigned long maxTime = [[srt lastObject][@"to"] integerValue];
        self.slider.maximumValue = maxTime;
        
        playing = YES;
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        if (maxTime >= 3600)
            _timeLabel.text = [NSString stringWithFormat:@"00:00/%lu:%02lu:%02lu",
                               maxTime / 3600, maxTime % 3600 / 60, maxTime % 3600 % 60];
        else
            _timeLabel.text = [NSString stringWithFormat:@"00:00/%02lu:%02lu", maxTime / 60, maxTime % 60];
        maxTimeLabel = [_timeLabel.text componentsSeparatedByString:@"/"][1];
        timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timer) userInfo:nil repeats:YES];
    }
    else
        self.navigationItem.rightBarButtonItem = nil;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stop) name:@"stopTimerSub" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showControls) name:@"showControls" object:nil];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    autohideTimer = [NSTimer scheduledTimerWithTimeInterval:6 target:self selector:@selector(hideControls) userInfo:nil repeats:NO];
    forceShowControls = YES;
    [self showControls];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
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
    
    [_playButton setImage:[UIImage imageNamed:(!playing) ? @"play" : @"pause"] forState:UIControlStateNormal];
}

- (void) stop
{
    playing = NO;
    [timer invalidate];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [_playButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
}

- (IBAction) scrub:(id)sender
{
    time = self.slider.value;
    curIndex = 0;
    [self updateText];
    [self updateTime];
    forceShowControls = YES;
    [self showControls];
}

- (void) timer
{
    time += 0.1;
    self.slider.value = time;
    [self updateText];
    [self updateTime];
}

- (void) updateTime
{
    unsigned long currentTime = time;
    if (currentTime >= 3600)
        _timeLabel.text = [NSString stringWithFormat:@"%lu:%02lu:%02lu/%@",
                           currentTime / 3600, currentTime % 3600 / 60, currentTime % 3600 % 60, maxTimeLabel];
    else
        _timeLabel.text = [NSString stringWithFormat:@"%02lu:%02lu/%@", currentTime / 60, currentTime % 60, maxTimeLabel];
}

- (void) updateText
{
    /* Subtitle text */
    if (srt == nil || time >= self.slider.maximumValue + delay)
    {
        [_playButton setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
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
        NSString *txt = [NSString stringWithFormat:@"%@%@</p>", htmlForSub, srt[curIndex][@"text"]];
        _subLabel.attributedText = [[NSAttributedString alloc] initWithData:[txt dataUsingEncoding:encoding]
                                                                    options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType }
                                                         documentAttributes:nil error:nil];
    }
    else
        _subLabel.text = @"";
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
    forceShowControls = YES;
    [self showControls];
}

- (IBAction) share:(UIBarButtonItem *)sender
{
    if (![doc presentOpenInMenuFromBarButtonItem:sender animated:YES])
        [doc presentOptionsMenuFromBarButtonItem:sender animated:YES];
}

- (void) hideControls
{
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [UIView animateWithDuration:0.7
                     animations:^{
                         _playButton.alpha = 0;
                         _timeLabel.alpha = 0;
                         _slider.alpha = 0;
                         _stepper.alpha = 0;
                         _stepperValue.alpha = 0;
                     }];
}

- (void) showControls
{
    [autohideTimer invalidate];
    if (_playButton.alpha == 1 && !forceShowControls)
    {
        forceShowControls = NO;
        [self hideControls];
        return;
    }
    forceShowControls = NO;
    autohideTimer = [NSTimer scheduledTimerWithTimeInterval:6 target:self selector:@selector(hideControls) userInfo:nil repeats:NO];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [UIView animateWithDuration:0.2
                     animations:^{
                         _playButton.alpha = 1;
                         _timeLabel.alpha = 1;
                         _slider.alpha = 1;
                         _stepper.alpha = 1;
                         _stepperValue.alpha = 1;
                     }];
}

@end
