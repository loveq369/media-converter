//
//  MCTextView.m
//  Media Converter
//
//  Created by Maarten Foukhar on 02-08-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import "MCIgnoreColorWellTextView.h"

@implementation MCIgnoreColorWellTextView

- (void)changeColor:(id)sender
{
    if (![[self ignoreColorWell] isActive] && ![[self secondIgnoreColorWell] isActive])
    {
	    [super changeColor:sender];
    }
}

@end
