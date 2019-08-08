//
//  MCColorView.m
//  Media Converter (Intel 64-bit)
//
//  Created by Maarten Foukhar on 05/08/2019.
//

#import "MCColorView.h"

@implementation MCColorView

- (void)setBackgroundColor:(NSColor *)backgroundColor
{
    _backgroundColor = backgroundColor;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSColor *backgroundColor = [self backgroundColor];
    if (backgroundColor != nil)
    {
        NSBezierPath *path = [NSBezierPath bezierPathWithRect:dirtyRect];
        [backgroundColor set];
        [path fill];
    }
    
    [super drawRect:dirtyRect];
}

@end
