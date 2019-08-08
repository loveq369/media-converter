//
//  MCAlert.m
//  Media Converter
//
//  Created by Maarten Foukhar on 07-01-10.
//  Copyright 2010 Kiwi Fruitware. All rights reserved.
//

#import "MCAlert.h"

@interface MCAlert()

@property (nonatomic, getter = isExpanded) BOOL expanded;

@end


@implementation MCAlert

- (void)setDetails:(NSString *)details
{
    _details = [details copy];

    if (_details != nil)
    {
	    [self setExpanded:NO];
    
	    NSView *superview = [[self window] contentView];
	    NSRect frame = NSMakeRect(16, 16, 88, 24);
    
	    //Create details button
	    NSButton *button = [[NSButton alloc] initWithFrame:frame];
	    [button setBezelStyle:NSRoundedBezelStyle];
	    NSFont *detailsButtonFont = [NSFont fontWithName:@"Lucida Grande" size:13];
	    if (detailsButtonFont)
    	    [[button cell] setFont:detailsButtonFont];
	    [button setTitle:NSLocalizedString(@"Details", nil)];
	    [button setAction:@selector(showDetails)];
    
	    //Create scrollview with textview
	    frame = NSMakeRect(20, 50, 384, 0);
	    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:frame];
	    [scrollView setAutoresizingMask:NSViewHeightSizable];
	    [scrollView setBorderType:NSBezelBorder];
	    frame = NSMakeRect(0, 0, 364, 0);
	    NSTextView *textView = [[NSTextView alloc] initWithFrame:frame];
	    NSFont *consoleFont = [NSFont fontWithName:@"Andale Mono" size:12];
        
            if (consoleFont)
                [textView setFont:consoleFont];
	    [scrollView setDocumentView:textView];
	    [scrollView setHasVerticalScroller:YES];
    
	    //Set the details and scroll to end
	    [textView insertText:_details];
	    NSRange range = NSMakeRange ([[textView string] length], 0);
	    [textView scrollRangeToVisible: range];
	    [textView setEditable:NO];
    
	    //Add our button and scrollview to alert
	    [superview addSubview:button];
	    [superview addSubview:scrollView];
    }
}

- (void)showDetails
{
    NSWindow *window = [self window];
    NSRect windowFrame = [window frame];
    NSInteger newHeight = windowFrame.size.height;
    NSInteger newY = windowFrame.origin.y;
    
    BOOL isExpanded = [self isExpanded];
    if (isExpanded)
    {
	    newHeight = newHeight - 100;
	    newY = newY + 100;
    }
    else
    {
	    newHeight = newHeight + 100;
	    newY = newY - 100;
    }
    
    [self setExpanded:!isExpanded];
    
    [window setFrame:NSMakeRect(windowFrame.origin.x, newY, windowFrame.size.width, newHeight) display:YES animate:YES];
}

@end
