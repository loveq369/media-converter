//
//  MCCheckBox.m
//  Media Converter
//
//  Created by Maarten Foukhar on 15-02-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import "MCTextCheckBoxCell.h"

@interface MCTextCheckBoxCell()

@property (nonatomic, weak) IBOutlet NSTextField *textField;

@end

@implementation MCTextCheckBoxCell

- (void)setStateWithoutSelecting:(NSInteger)value
{
    [super setState:value];
}

- (void)setState:(NSInteger)value
{
    [super setState:value];
    
    BOOL enabled = ([self state] == NSOnState);
    
    NSTextField *textField = [self textField];
    if (textField)
    {
	    if (!enabled)
	    {
    	    [[textField cell] setObjectValue:nil];
    	    [textField performClick:self];
	    }
    
	    [textField setEnabled:enabled];
	    
	    if (enabled)
	    {
    	    [textField performClick:self];
    	    [[textField window] makeFirstResponder:textField];
	    }
    }
}

@end
