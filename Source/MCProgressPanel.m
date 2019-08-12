//
//  MCProgress.m
//  Media Converter
//
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import "MCProgressPanel.h"
#import "MCCommonMethods.h"
#import <CoreImage/CoreImage.h>

@interface MCProgressPanel()

@property (nonatomic, weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (nonatomic, strong) NSProgressIndicator *dockProgressIndicator;
@property (nonatomic, weak) IBOutlet NSImageView *progressImageView;
@property (nonatomic, weak) IBOutlet NSTextField *statusTextField;
@property (nonatomic, weak) IBOutlet NSTextField *taskTextField;
@property (nonatomic, weak) IBOutlet NSButton *cancelButton;

@property (copy) void(^completion)(BOOL didCancel);

@property (nonatomic, strong) NSWindow *parentWindow;

@end

@implementation MCProgressPanel

+ (MCProgressPanel *)progressPanel
{
    static MCProgressPanel *progressPanel = nil;
    static dispatch_once_t onceToken = 0;

    dispatch_once(&onceToken, ^
    {
        progressPanel = [[MCProgressPanel alloc] init];
    });
    
    return progressPanel;
}

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        [[NSBundle mainBundle] loadNibNamed:@"MCProgress" owner:self topLevelObjects:nil];
    }

    return self;
}

- (void)dealloc
{
    [[self progressIndicator] stopAnimation:self];
}

#pragma mark - Main Methods

- (void)beginSheetForWindow:(NSWindow *)window completionHandler:(void (^)(NSModalResponse returnCode))handler
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^
    {
        [self setParentWindow:window];
        
        NSDockTile *dockTile = [[NSApplication sharedApplication] dockTile];
        NSSize dockTileSize = [dockTile size];
        NSImageView *imageView = [[NSImageView alloc] init];
        [imageView setImage:[[NSApplication sharedApplication] applicationIconImage]];
        [imageView becomeFirstResponder];
        [dockTile setContentView:imageView];
        
        // Since the Dock tile view is always on the background, a progress indicator is always is greyed out
        // So we render the main progress indicator to the Dock, scaled so on newer macOS versions the rounded caps are a little less round
        // Wish this could be differently
        NSSize progressIndicatorSize = [[self progressIndicator] frame].size;
        NSProgressIndicator *dockProgressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0.0, 10.0, dockTileSize.width, progressIndicatorSize.height)];
        [dockProgressIndicator setStyle:NSProgressIndicatorBarStyle];
        [imageView addSubview:dockProgressIndicator];
        [self setDockProgressIndicator:dockProgressIndicator];

        [window beginSheet:[self window] completionHandler:^(NSModalResponse returnCode)
        {
            if (handler != nil)
            {
                handler(returnCode);
            }
            
            if (returnCode == NSModalResponseCancel && [self cancelHandler])
            {
                [self cancelHandler]();
            }
        }];
    }];
}

- (void)beginSheetForWindow:(nonnull NSWindow *)window
{
    [self beginSheetForWindow:window completionHandler:nil];
}

- (void)endSheet
{
    [self endSheetWithCompletion:nil];
}

- (void)endSheetWithCompletion:(void (^)(void))completion
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^
    {
        NSDockTile *dockTile = [[NSApplication sharedApplication] dockTile];
        [dockTile setContentView:nil];
        [dockTile display];
        
        NSWindow *window = [self window];
        NSWindow *sheetParent = [window sheetParent];
        [window orderOut:nil];
        [sheetParent endSheet:window];

        if (completion != nil)
        {
            completion();
        }
    }];
}

#pragma mark - Interface Methods

- (IBAction)cancelProgress:(id)sender
{
    NSDockTile *dockTile = [[NSApplication sharedApplication] dockTile];
    [dockTile setContentView:nil];
    [dockTile display];

    NSWindow *window = [self window];
    NSWindow *sheetParent = [window sheetParent];
    [window orderOut:nil];
    [sheetParent endSheet:window returnCode:NSCancelButton];
}

#pragma mark - Property Methods

- (void)setTask:(NSString *)task
{
    _task = [task copy];

    [[self taskTextField] performSelectorOnMainThread:@selector(setStringValue:) withObject:_task waitUntilDone:YES];
}

- (void)setStatus:(NSString *)status
{
    _status = [status copy];

    [[self statusTextField] performSelectorOnMainThread:@selector(setStringValue:) withObject:_status waitUntilDone:YES];
}

- (void)setMaximumValue:(CGFloat)maximumValue
{
    _maximumValue = maximumValue;

    [[NSOperationQueue mainQueue] addOperationWithBlock:^
    {
        NSProgressIndicator *progressIndicator = [self progressIndicator];
        NSProgressIndicator *dockProgressIndicator = [self dockProgressIndicator];
    
        if (maximumValue > 0)
        {
            [progressIndicator setIndeterminate:NO];
            [progressIndicator setDoubleValue:0.0];
            [progressIndicator setMaxValue:self->_maximumValue];
            
            [dockProgressIndicator setIndeterminate:NO];
            [dockProgressIndicator setDoubleValue:0.0];
            [dockProgressIndicator setMaxValue:self->_maximumValue];
        }
        else
        {
            [progressIndicator setIndeterminate:YES];
            [progressIndicator startAnimation:nil];
            
            [dockProgressIndicator setIndeterminate:YES];
            [dockProgressIndicator startAnimation:nil];
        }
    }];
}

- (void)setValue:(CGFloat)value
{
    _value = value;

    [[NSOperationQueue mainQueue] addOperationWithBlock:^
    {
        NSProgressIndicator *progressIndicator = [self progressIndicator];
        NSProgressIndicator *dockProgressIndicator = [self dockProgressIndicator];

        if (self->_value == -1)
        {
            [progressIndicator setIndeterminate:YES];
            [progressIndicator startAnimation:nil];
            
            [dockProgressIndicator setIndeterminate:YES];
            [dockProgressIndicator startAnimation:nil];
        }
        else
        {
            [progressIndicator setIndeterminate:NO];
            [dockProgressIndicator setIndeterminate:NO];
        }

        if (self->_value > [progressIndicator doubleValue])
        {
            [progressIndicator setDoubleValue:self->_value];
            [dockProgressIndicator setDoubleValue:self->_value];
        }
        
        [[[NSApplication sharedApplication] dockTile] display];
    }];
}

- (void)setAllowCanceling:(BOOL)allowCanceling
{
    _allowCanceling = allowCanceling;
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^
    {
        // TODO: use auto layout if possible
        NSWindow *window = [self window];
        NSRect frame = [window frame];
    
        if (self->_allowCanceling == NO)
        {
            NSRect newFrame = NSMakeRect(frame.origin.x, frame.origin.y, frame.size.width, 124.0);
            [window setFrame:newFrame display:YES];
            [[self cancelButton] setHidden:YES];
        }
        else
        {
            NSRect newFrame = NSMakeRect(frame.origin.x, frame.origin.y, frame.size.width, 163.0);
            [window setFrame:newFrame display:YES];
            [[self cancelButton] setHidden:NO];
        }
    }];
}

// TODO: think of a way to make this method more understandable, even I after seven years got completely confused :P
- (void)setStatusByAddingPercent:(NSString *)percent
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^
    {
        NSTextField *statusTextField = [self statusTextField];

        NSString *currentText = [statusTextField stringValue];
        NSString *newStatusText;

        if ([currentText length] > 60)
        {
            newStatusText = [[currentText substringToIndex:48] stringByAppendingString:@"..."];
        }
        else
        {
            newStatusText = currentText;
        }
        
        [statusTextField setStringValue:[[[newStatusText componentsSeparatedByString:@" ("] objectAtIndex:0] stringByAppendingString:percent]];
    }];
}

- (NSImage *)progressImage
{
    NSProgressIndicator *progressIndicator = [self progressIndicator];
    NSRect bounds = [progressIndicator bounds];
    NSSize progressIndicatorSize = bounds.size;
    NSSize imageSize = NSMakeSize(progressIndicatorSize.width, progressIndicatorSize.height);

    NSBitmapImageRep *bitmapImageRep = [progressIndicator bitmapImageRepForCachingDisplayInRect:bounds];
    [bitmapImageRep setSize:imageSize];
    [progressIndicator cacheDisplayInRect:bounds toBitmapImageRep:bitmapImageRep];

    NSImage *image = [[NSImage alloc] initWithSize:imageSize];
    [image addRepresentation:bitmapImageRep];
    return image;
}

@end
