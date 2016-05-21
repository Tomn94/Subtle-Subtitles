//
//  SubViewController.m
//  Subtle Subtitles
//
//  Created by Tomn on 26/03/2016.
//  Copyright © 2016 Tomn. All rights reserved.
//

#import "SubViewController.h"

@implementation SubViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    time = .0f;
    delay = .0f;
    curIndex = -1;
    playing = NO;
    srt = nil;
    
    maxTimeLabel = @"00:00";
    if ([UIFont instancesRespondToSelector:@selector(monospacedDigitSystemFontOfSize:weight:)])
    {
        _stepperValue.font = [UIFont monospacedDigitSystemFontOfSize:_stepperValue.font.pointSize
                                                              weight:UIFontWeightRegular];
        _timeLabel.font = [UIFont monospacedDigitSystemFontOfSize:_timeLabel.font.pointSize
                                                           weight:UIFontWeightRegular];
    }
    [self.slider setThumbImage:[UIImage imageNamed:@"thumb"] forState:UIControlStateNormal];
    
    OpenSubtitleSearchResult *subFile = [[Data sharedData] currentFile];
    if (subFile.movieName == nil || [subFile.movieName isEqualToString:@""])
        [self setTitle:subFile.subtitleName];
    else
        [self setTitle:subFile.movieName];
    fileName = [NSString stringWithFormat:@"/%@", subFile.subtitleName];
    if (fileName == nil || [fileName isEqualToString:@""] || [fileName isEqualToString:@"/"])
        fileName = @"/sub.srt";
    
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingString:fileName];
    
    
    docAct = [[UIActivityViewController alloc] initWithActivityItems:@[[[ActivityLinkProvider alloc] initWithPlaceholderItem:@""],
                                                                       [[ActivityTextProvider alloc] initWithPlaceholderItem:@""]]
                                               applicationActivities:@[[OpenInActivity new], [DownActivity new], [SafariActivity new]]];
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
        CGFloat txtSize = [[NSUserDefaults standardUserDefaults] floatForKey:@"defaultPointSize"];
        _subLabel.font = [UIFont systemFontOfSize:txtSize * self.view.frame.size.width / 667];
        
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
    
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
    [self.view addGestureRecognizer:pinch];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showControls)];
    [tap requireGestureRecognizerToFail:pinch];
    [self.view addGestureRecognizer:tap];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stop) name:@"stopTimerSub" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showControls) name:@"showControls" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openIn) name:@"openIn" object:nil];
    
    if ([UIKeyCommand instancesRespondToSelector:@selector(setDiscoverabilityTitle:)])
    {
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:@" "
                                                modifierFlags:0
                                                       action:@selector(playTapped:)
                                         discoverabilityTitle:NSLocalizedString(@"Play/Pause", @"")]];
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:@"p"
                                                modifierFlags:0
                                                       action:@selector(playTapped:)]];
        
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow
                                                modifierFlags:0
                                                       action:@selector(keyArrow:)
                                         discoverabilityTitle:NSLocalizedString(@"Add Delay: 0.1s", @"")]];
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow
                                                modifierFlags:0
                                                       action:@selector(keyArrow:)
                                         discoverabilityTitle:NSLocalizedString(@"Reduce Delay: 0.1s", @"")]];
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow
                                                modifierFlags:UIKeyModifierAlternate
                                                       action:@selector(keyArrowCmd:)
                                         discoverabilityTitle:NSLocalizedString(@"Add Delay: 1s", @"")]];
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow
                                                modifierFlags:UIKeyModifierAlternate
                                                       action:@selector(keyArrowCmd:)
                                         discoverabilityTitle:NSLocalizedString(@"Reduce Delay: 1s", @"")]];
        
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:UIKeyInputLeftArrow
                                                modifierFlags:0
                                                       action:@selector(keyArrow:)
                                         discoverabilityTitle:NSLocalizedString(@"Rewind: 1s", @"")]];
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:UIKeyInputRightArrow
                                                modifierFlags:0
                                                       action:@selector(keyArrow:)
                                         discoverabilityTitle:NSLocalizedString(@"Fast-Forward: 1s", @"")]];
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:UIKeyInputLeftArrow
                                                modifierFlags:UIKeyModifierAlternate
                                                       action:@selector(keyArrowCmd:)
                                         discoverabilityTitle:NSLocalizedString(@"Rewind: 5s", @"")]];
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:UIKeyInputRightArrow
                                                modifierFlags:UIKeyModifierAlternate
                                                       action:@selector(keyArrowCmd:)
                                         discoverabilityTitle:NSLocalizedString(@"Fast-Forward: 5s", @"")]];
        
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:@"+"
                                                modifierFlags:UIKeyModifierCommand
                                                       action:@selector(zoomText:)
                                         discoverabilityTitle:NSLocalizedString(@"Enlarge Text Size", @"")]];
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:@"-"
                                                modifierFlags:UIKeyModifierCommand
                                                       action:@selector(zoomText:)
                                         discoverabilityTitle:NSLocalizedString(@"Reduce Text Size", @"")]];
        
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:@"i"
                                                modifierFlags:0
                                                       action:@selector(showControls)
                                         discoverabilityTitle:NSLocalizedString(@"Show/Hide Controls", @"")]];
        
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:@"e"
                                                modifierFlags:UIKeyModifierCommand
                                                       action:@selector(share:)
                                         discoverabilityTitle:NSLocalizedString(@"Export Subtitle", @"")]];
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:@"s"
                                                modifierFlags:UIKeyModifierCommand
                                                       action:@selector(share:)]];
        
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:@"f"
                                                modifierFlags:UIKeyModifierCommand
                                                       action:@selector(back)
                                         discoverabilityTitle:NSLocalizedString(@"Go back to Search", @"")]];
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:UIKeyInputLeftArrow
                                                modifierFlags:UIKeyModifierCommand
                                                       action:@selector(back)]];
    }
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

- (void) viewWillTransitionToSize:(CGSize)size
        withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    CGFloat txtSize = [[NSUserDefaults standardUserDefaults] floatForKey:@"defaultPointSize"];
    _subLabel.font = [UIFont systemFontOfSize:txtSize * size.width / 667];
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
    forceShowControls = YES;
    [self showControls];
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
        forceShowControls = YES;
        [self showControls];
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
        if (curIndex != found)
        {
            curIndex = found;
            NSString *htmlForSub = [NSString stringWithFormat:@"<p style=\"color: white; text-align: center; font-family: '-apple-system', HelveticaNeue; font-size: %fpx\">", _subLabel.font.pointSize];
            NSString *txt = [NSString stringWithFormat:@"%@%@</p>", htmlForSub, srt[curIndex][@"text"]];
            _subLabel.attributedText = [[NSAttributedString alloc] initWithData:[txt dataUsingEncoding:encoding]
                                                                        options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType }
                                                             documentAttributes:nil error:nil];
        }
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
    self.stepperValue.text = [NSString stringWithFormat:NSLocalizedString(@"%.1fs", @""), delay];
    forceShowControls = YES;
    [self showControls];
}

- (IBAction) share:(UIBarButtonItem *)sender
{
    forceShowControls = YES;
    [self showControls];
    UIBarButtonItem *item = self.navigationItem.rightBarButtonItem;
    if (item == nil)
        item = self.navigationItem.leftBarButtonItem;
    if (item == nil)
        return;
    
    if ([docAct respondsToSelector:@selector(popoverPresentationController)])
        docAct.popoverPresentationController.barButtonItem = item;
    [self presentViewController:docAct animated:YES completion:nil];
}

- (void) openIn
{
    UIBarButtonItem *item = self.navigationItem.rightBarButtonItem;
    if (item == nil)
        item = self.navigationItem.leftBarButtonItem;
    if (item == nil)
        return;
    if (![doc presentOpenInMenuFromBarButtonItem:item animated:YES])
        [doc presentOptionsMenuFromBarButtonItem:item animated:YES];
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

- (void) pinch:(UIPinchGestureRecognizer *)g
{
    CGFloat newSize = _subLabel.font.pointSize * g.scale;
    if (newSize > MIN_FONT_SIZE && newSize < MAX_FONT_SIZE)
        _subLabel.font = [UIFont systemFontOfSize:newSize];
    g.scale = 1;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSUserDefaults standardUserDefaults] setFloat:_subLabel.font.pointSize forKey:@"defaultPointSize"];
    });
}

- (void) back
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) keyArrow:(UIKeyCommand *)sender
{
    if (sender.input == UIKeyInputUpArrow)          // + Delay
    {
        self.stepper.value += 1;
        [self delay:nil];
    }
    else if (sender.input == UIKeyInputDownArrow)   // - Delay
    {
        self.stepper.value -= 1;
        [self delay:nil];
    }
    else if (sender.input == UIKeyInputLeftArrow)   // Rewind
    {
        self.slider.value -= 1;
        [self scrub:nil];
    }
    else if (sender.input == UIKeyInputRightArrow)  // Fast-Forward
    {
        self.slider.value += 1;
        [self scrub:nil];
    }
}

- (void) keyArrowCmd:(UIKeyCommand *)sender
{
    if (sender.input == UIKeyInputUpArrow)          // + Delay
    {
        self.stepper.value += 10;
        [self delay:nil];
    }
    else if (sender.input == UIKeyInputDownArrow)   // - Delay
    {
        self.stepper.value -= 10;
        [self delay:nil];
    }
    else if (sender.input == UIKeyInputLeftArrow)   // Rewind
    {
        self.slider.value -= 5;
        [self scrub:nil];
    }
    else if (sender.input == UIKeyInputRightArrow)  // Fast-Forward
    {
        self.slider.value += 5;
        [self scrub:nil];
    }
}

- (void) zoomText:(UIKeyCommand *)sender
{
    CGFloat size = _subLabel.font.pointSize;
    if ([sender.input isEqualToString:@"+"] && size < MAX_FONT_SIZE)
        _subLabel.font = [UIFont systemFontOfSize:size + 10];
    else if ([sender.input isEqualToString:@"-"] && size > MIN_FONT_SIZE)
        _subLabel.font = [UIFont systemFontOfSize:size - 10];
    [[NSUserDefaults standardUserDefaults] setFloat:_subLabel.font.pointSize forKey:@"defaultPointSize"];
}

@end



@implementation SafariActivity

- (NSString *) activityTitle
{
    return NSLocalizedString(@"View on OpenSubtitles.org", @"");
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    return YES;
}

@end



@implementation OpenInActivity

- (NSString *) activityTitle
{
    return NSLocalizedString(@"Export to app…", @"");
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    return YES;
}

- (UIImage *)activityImage
{
    return [UIImage imageNamed:@"export"];
}

- (void)performActivity
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"openIn" object:nil];
    [self activityDidFinish:YES];
}

@end



@implementation DownActivity
{
    NSString *_URL;
}

- (NSString *)activityType
{
    return NSStringFromClass([self class]);
}

- (NSString *)activityTitle
{
    return NSLocalizedString(@"Copy Download Link", @"");
}

- (UIImage *)activityImage
{
    return [UIImage imageNamed:@"copy"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    for (id activityItem in activityItems) {
        if ([activityItem isKindOfClass:[NSString class]]) {
            return YES;
        }
    }
    return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems
{
    for (id activityItem in activityItems) {
        if ([activityItem isKindOfClass:[NSString class]]) {
            _URL = activityItem;
        }
    }
}

- (void)performActivity
{
    [[UIPasteboard generalPasteboard] setString:_URL];
    [self activityDidFinish:YES];
}

@end


@implementation ActivityTextProvider

- (id) activityViewController:(UIActivityViewController *)activityViewController
          itemForActivityType:(NSString *)activityType
{
    if ([activityType isEqualToString:@"DownActivity"])
        return [[Data sharedData] currentFile].subtitleDownloadAddress;
    return nil;
}

@end

@implementation ActivityLinkProvider

- (id) activityViewController:(UIActivityViewController *)activityViewController
          itemForActivityType:(NSString *)activityType
{
    if (![activityType isEqualToString:@"DownActivity"])
        return [NSURL URLWithString:[[Data sharedData] currentFile].subtitlePage];
    return nil;
}

@end

