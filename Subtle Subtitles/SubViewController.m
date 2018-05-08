//
//  SubViewController.m
//  Subtle Subtitles
//
//  Created by Thomas Naudet on 26/03/2016.
//  Copyright © 2016 Thomas Naudet. All rights reserved.
//  This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/
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
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([UIFont respondsToSelector:@selector(monospacedDigitSystemFontOfSize:weight:)])
    {
        _stepperValue.font = [UIFont fontWithDescriptor:[_stepperValue.font.fontDescriptor fontDescriptorByAddingAttributes:
                                                         @{ UIFontDescriptorFeatureSettingsAttribute :
                                                                @[ @{ UIFontFeatureTypeIdentifierKey:     @(kNumberSpacingType),
                                                                      UIFontFeatureSelectorIdentifierKey: @(kMonospacedNumbersSelector)}]
                                                            }] size:0];
        _timeLabel.font = [UIFont fontWithDescriptor:[_timeLabel.font.fontDescriptor fontDescriptorByAddingAttributes:
                                                         @{ UIFontDescriptorFeatureSettingsAttribute :
                                                                @[ @{ UIFontFeatureTypeIdentifierKey:     @(kNumberSpacingType),
                                                                      UIFontFeatureSelectorIdentifierKey: @(kMonospacedNumbersSelector)}]
                                                            }] size:0];
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
    
    // Imported SRTs have no link
    if ([subFile.subtitlePage isEqualToString:@""] && [subFile.subtitleDownloadAddress isEqualToString:@""]) {
        docAct = nil;
        NSMutableArray *items = [self.navigationItem.rightBarButtonItems mutableCopy];
        if (items.count > 2)
            [items removeObjectAtIndex:1];
        self.navigationItem.rightBarButtonItems = items;
    }
    else
        docAct = [[UIActivityViewController alloc] initWithActivityItems:@[[[ActivityLinkProvider alloc] initWithPlaceholderItem:subFile.subtitlePage],
                                                                           [[ActivityTextProvider alloc] initWithPlaceholderItem:subFile.subtitleDownloadAddress]]
                                                   applicationActivities:@[[SafariActivity new], [DownActivity new]]];
    doc = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:path]];
    doc.delegate = self;
    
    [self loadWithEncoding];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timer) userInfo:nil repeats:YES];
    playing = YES;
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
    pinch.delegate = self;
    [self.view addGestureRecognizer:pinch];
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    doubleTap.delegate = self;
    [self.view addGestureRecognizer:doubleTap];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showControls)];
    tap.delegate = self;
    [tap requireGestureRecognizerToFail:pinch];
    [tap requireGestureRecognizerToFail:doubleTap];
    [self.view addGestureRecognizer:tap];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stop) name:@"stopTimerSub" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showControls) name:@"showControls" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openIn:) name:@"openIn" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadWithEncoding) name:@"updateEncoding" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadText) name:@"updateDisplaySettings" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startAutoHideControlsTimer) name:@"fontSettingsDismissed" object:nil]; // from OK button
    
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
        
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:@","
                                                modifierFlags:UIKeyModifierCommand
                                                       action:@selector(settings)
                                         discoverabilityTitle:NSLocalizedString(@"Display Settings", @"")]];
        
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:@"l"
                                                modifierFlags:UIKeyModifierCommand
                                                       action:@selector(share:)
                                         discoverabilityTitle:NSLocalizedString(@"Get Link", @"")]];
        
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:@"o"
                                                modifierFlags:UIKeyModifierCommand
                                                       action:@selector(openIn:)
                                         discoverabilityTitle:NSLocalizedString(@"Export Subtitle", @"")]];
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:@"s"
                                                modifierFlags:UIKeyModifierCommand
                                                       action:@selector(openIn:)]];
        [self addKeyCommand:[UIKeyCommand keyCommandWithInput:@"e"
                                                modifierFlags:UIKeyModifierCommand
                                                       action:@selector(openIn:)]];
        
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
    
    [self startAutoHideControlsTimer];
    [_playButton setImage:[UIImage imageNamed:(!playing) ? @"play" : @"pause"] forState:UIControlStateNormal];
    forceShowControls = YES;
    [self showControls];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self stop];
}

- (void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    if ([UIView userInterfaceLayoutDirectionForSemanticContentAttribute:self.view.semanticContentAttribute] == UIUserInterfaceLayoutDirectionRightToLeft)
    {
        _stepperValue.textAlignment = NSTextAlignmentLeft;
        _timeLabel.textAlignment    = NSTextAlignmentRight;
    }
}

- (void) viewWillTransitionToSize:(CGSize)size
        withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    CGFloat txtSize = [defaults floatForKey:[FontSettings settingsFontSizeKey]];
    NSString *fontName = [defaults stringForKey:[FontSettings settingsFontNameKey]];
    if (fontName != nil)
        _subLabel.font = [UIFont fontWithName:fontName size:txtSize * size.width / 667];
    else
        _subLabel.font = [UIFont systemFontOfSize:txtSize * size.width / 667];
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - Pop over delegates

/// Dismiss Link Sharing or Display Settings (except its OK button)
- (void) popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    [self startAutoHideControlsTimer];
}

/// Dismiss [Open In]/Options
- (void) documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
    [self startAutoHideControlsTimer];
}

/// Dismiss Open In/[Options]
- (void) documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller
{
    [self startAutoHideControlsTimer];
}

#pragma mark - Actions

- (void) loadWithEncoding
{
    // Get file data
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingString:fileName];
    NSData *fileData = [NSData dataWithContentsOfFile:path];
    
    // Get user encoding settings (0 = automatic, otherwise NSStringEncoding raw value)
    NSUInteger encodingSetting = [[NSUserDefaults standardUserDefaults] integerForKey:@"preferredEncoding"];
    
    if (encodingSetting == 0)
    {
        // If automatic, then compute the encoding from file data.
        // Falls backs on UTF8 if encoding couldn't be determined.
        NSStringEncoding autoEncoding = [NSString stringEncodingForData:fileData
                                                        encodingOptions:nil
                                                        convertedString:nil
                                                    usedLossyConversion:nil];
        encoding = (autoEncoding == 0) ? NSUTF8StringEncoding : autoEncoding;
    }
    else
    {
        encoding = encodingSetting;  // by default, use user-provided string encoding
    }
    
    // Try reading the file data as text, and use fallbacks
    NSString *htmlString = [[NSString alloc] initWithData:fileData encoding:encoding];
    if (htmlString == nil && encoding != NSUTF8StringEncoding)
    {
        encoding = NSUTF8StringEncoding;
        htmlString = [[NSString alloc] initWithData:fileData encoding:encoding];
    }
    if (htmlString == nil)
    {
        encoding = NSISOLatin1StringEncoding;
        htmlString = [[NSString alloc] initWithData:fileData encoding:encoding];
    }
    if (htmlString == nil)
    {
        encoding = NSWindowsCP1251StringEncoding;
        htmlString = [[NSString alloc] initWithData:fileData encoding:encoding];
    }
    if (htmlString == nil)
    {
        encoding = NSASCIIStringEncoding;
        htmlString = [[NSString alloc] initWithData:fileData encoding:encoding];
    }
    
    // If read successfully
    if (htmlString != nil)
    {
        self.subLabel.text = @"";
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        CGFloat txtSize = [defaults floatForKey:[FontSettings settingsFontSizeKey]] * self.view.frame.size.width / 667;
        NSString *fontName = [defaults stringForKey:[FontSettings settingsFontNameKey]];
        if (fontName != nil)
            _subLabel.font = [UIFont fontWithName:fontName size:txtSize];
        else
            _subLabel.font = [UIFont systemFontOfSize:txtSize];
        
        srt = [self parse:htmlString];
        unsigned long maxTime = [[srt lastObject][@"to"] integerValue];
        self.slider.maximumValue = maxTime;
        
        if (maxTime >= 3600)
            _timeLabel.text = [NSString stringWithFormat:@"00:00/%lu:%02lu:%02lu",
                               maxTime / 3600, maxTime % 3600 / 60, maxTime % 3600 % 60];
        else
            _timeLabel.text = [NSString stringWithFormat:@"00:00/%02lu:%02lu", maxTime / 60, maxTime % 60];
        maxTimeLabel = [_timeLabel.text componentsSeparatedByString:@"/"][1];
        
        [self updateText];
        [self updateTime];
    }
    else
        self.navigationItem.rightBarButtonItems = nil;
    
    forceTextRedraw = YES;
}

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
    if (sender != nil)
    {
        forceShowControls = YES;
        [self showControls];
    }
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
    if (sender != nil)
    {
        forceShowControls = YES;
        [self showControls];
    }
}

- (void) startAutoHideControlsTimer
{
    autohideTimer = [NSTimer scheduledTimerWithTimeInterval:6 target:self selector:@selector(hideControls) userInfo:nil repeats:NO];
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
        if (curIndex != found || forceTextRedraw)
        {
            curIndex = found;
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            
            /* Get Size */
            CGFloat textSize = _subLabel.font.pointSize;
            if (forceTextRedraw)
            {
                textSize = [defaults floatForKey:[FontSettings settingsFontSizeKey]] * self.view.frame.size.width / 667;
                forceTextRedraw = NO;
            }
            
            /* Get Font */
            NSString *eventualCustomFontName = [defaults stringForKey:[FontSettings settingsFontNameKey]];
            if (eventualCustomFontName != nil)
                eventualCustomFontName = [NSString stringWithFormat:@"'%@',", eventualCustomFontName];
            else
                eventualCustomFontName = @"";
            
            /* Get Color */
            NSString *color = @"white";
            if ([defaults colorForKey:[FontSettings settingsFontColorKey]]) {
                UIColor *customColor = [defaults colorForKey:[FontSettings settingsFontColorKey]];
                CGFloat red = 0, green = 0, blue = 0, alpha = 0;
                [customColor getRed:&red green:&green blue:&blue alpha:&alpha];
                color = [NSString stringWithFormat:@"rgb(%d,%d,%d)", (int)(red * 255), (int)(green * 255), (int)(blue * 255)];
            }
            
            /* Create HTML for text */
            NSString *htmlForSub = [NSString stringWithFormat:@"<p style=\"color: %@; text-align: center; font-family: %@'-apple-system', HelveticaNeue, Arial; font-size: %fpx\">", color, eventualCustomFontName, textSize];
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
                    NSArray *times = [curTime componentsSeparatedByString:@"-->"];
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
                        
                        /* Decode hard coded entities */
                        curText = [curText decodeEntities];
                        
                        /* Convert text like 'A©' (but not the tags) to HTML entities */
                        NSMutableString *htmlString = [NSMutableString string];
                        NSString *dontReplace = @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789<>/' =#-_;%!\"";
                        for (int i = 0 ; i < curText.length ; i++)
                        {
                            unichar character = [curText characterAtIndex:i];
                            if ([dontReplace containsString:[NSString stringWithCharacters:&character length:1]]) {
                                [htmlString appendFormat:@"%c", character];
                            } else {
                                [htmlString appendFormat:@"&#x%x;", character];
                            }
                        }
                        
                        NSDictionary *previous = parts.lastObject;
                        if ([previous[@"to"] doubleValue] < fin)
                            [parts addObject:@{ @"from": @(debut),
                                                @"to"  : @(fin),
                                                @"text": htmlString }];
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
    if (sender != nil)
    {
        forceShowControls = YES;
        [self showControls];
    }
}

- (void) settings
{
    /* Disallow multiple popovers */
    if (self.presentedViewController != nil)
        return;
    
    forceShowControls = YES;
    [self showControls];
    [self performSegueWithIdentifier:@"fontSegue" sender:self];
}

- (IBAction) share:(UIBarButtonItem *)sender
{
    if (docAct == nil)
        return;
    /* Disallow multiple popovers */
    if (self.presentedViewController != nil)
        return;
    
    forceShowControls = YES;
    [self showControls];
    UIBarButtonItem *item = self.navigationItem.rightBarButtonItems[1];
    if (item == nil)
        item = self.navigationItem.leftBarButtonItem;
    if (item == nil)
        return;
    
    if ([docAct respondsToSelector:@selector(popoverPresentationController)]) {
        docAct.popoverPresentationController.barButtonItem = item;
        docAct.popoverPresentationController.delegate = self;
    }
    [self presentViewController:docAct animated:YES completion:nil];
}

- (IBAction) openIn:(UIBarButtonItem *)sender
{
    /* Disallow multiple popovers */
    if (self.presentedViewController != nil)
        return;
    
    forceShowControls = YES;
    [self showControls];
    UIBarButtonItem *item = self.navigationItem.rightBarButtonItems[0];
    if (item == nil)
        item = self.navigationItem.leftBarButtonItem;
    if (item == nil)
        return;
    
    if (![doc presentOpenInMenuFromBarButtonItem:item animated:YES])
        [doc presentOptionsMenuFromBarButtonItem:item animated:YES];
}

- (void) hideControls
{
    /* Don't hide if there's a popover */
    if (self.presentedViewController != nil) {
        return;
    }
    
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
    if (_stepper.alpha == 1 && !forceShowControls)
    {
        forceShowControls = NO;
        [self hideControls];
        return;
    }
    forceShowControls = NO;
    autohideTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self
                                                   selector:@selector(hideControls) userInfo:nil repeats:NO];
    
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
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    CGFloat newSize = _subLabel.font.pointSize * g.scale;
    CGFloat newSettingsSize = newSize / self.view.frame.size.width * 667;
    
    if (newSettingsSize >= [FontSettings settingsFontSizeMin] && newSettingsSize <= [FontSettings settingsFontSizeMax])
    {
        NSString *fontName = [defaults stringForKey:[FontSettings settingsFontNameKey]];
        if (fontName != nil)
            _subLabel.font = [UIFont fontWithName:fontName size:newSize];
        else
            _subLabel.font = [UIFont systemFontOfSize:newSize];
    }
    g.scale = 1;
    dispatch_async(dispatch_get_main_queue(), ^{
        [defaults setFloat:newSettingsSize
                    forKey:[FontSettings settingsFontSizeKey]];
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
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *fontName = [defaults stringForKey:[FontSettings settingsFontNameKey]];
    
    CGFloat size = _subLabel.font.pointSize;
    CGFloat settingsSize = size / self.view.frame.size.width * 667;
    
    if ([sender.input isEqualToString:@"+"]) {
        if (fontName != nil)
            _subLabel.font = [UIFont fontWithName:fontName size:MIN(size + 10, [FontSettings settingsFontSizeMax])];
        else
            _subLabel.font = [UIFont systemFontOfSize:MIN(size + 10, [FontSettings settingsFontSizeMax])];
    }
    else if ([sender.input isEqualToString:@"-"]) {
        if (fontName != nil)
            _subLabel.font = [UIFont fontWithName:fontName size:MAX(size - 10, [FontSettings settingsFontSizeMin])];
        else
            _subLabel.font = [UIFont systemFontOfSize:MAX(size - 10, [FontSettings settingsFontSizeMin])];
    }
    
    [defaults setFloat:settingsSize
                forKey:[FontSettings settingsFontSizeKey]];
}

- (void) reloadText
{
    forceTextRedraw = YES;
    [self updateText];
}

/**
 Called when double tap on view occurs

 @param recognizer Double tap touch recognizer responsible
 */
- (void) handleDoubleTap:(UITapGestureRecognizer *)recognizer
{
    CGPoint location  = [recognizer locationInView:self.view];
    CGFloat viewWidth = self.view.bounds.size.width;
    
    // Detect position of the tap.
    // Scrub on sides, play/pause in center.
    if (location.x < viewWidth * 0.3 ||
        location.x > viewWidth * 0.7)
    {
        self.slider.value += (location.x > viewWidth * 0.7) ? 3 : -3;  // scrub 3s back or forward
        [self scrub:nil];
        
        [UIView animateWithDuration:0.2
                         animations:^{
                             _timeLabel.alpha = 1;
                         }];
    }
    else
    {
        [self playTapped:nil];  // play/pause
        
        [UIView animateWithDuration:0.2
                         animations:^{
                             if (playing)
                             {
                                 _timeLabel.alpha = 1;
                             }
                             _playButton.alpha = 1;
                         }];
    }
    
    autohideTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self
                                                   selector:@selector(hideControls) userInfo:nil repeats:NO];
}

#pragma mark - Gesture Recognizer Delegate

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
        shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isKindOfClass:[UIControl class]])
    {
        return NO;
    }
    
    return YES;
}

#pragma mark - Segue config for Font Menu

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"fontSegue"])
    {
        UINavigationController *dest = segue.destinationViewController;
        dest.popoverPresentationController.delegate = self;
    }
}

- (BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    /* Disallow multiple popovers */
    if ([identifier isEqualToString:@"fontSegue"])
        return self.presentedViewController == nil;
    return YES;
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
        return self.placeholderItem;
    return nil;
}

@end

@implementation ActivityLinkProvider

- (id) activityViewController:(UIActivityViewController *)activityViewController
          itemForActivityType:(NSString *)activityType
{
    return [NSURL URLWithString:self.placeholderItem];
}

@end

