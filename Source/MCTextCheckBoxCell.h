//
//  MCCheckBox.h
//  Media Converter
//
//  Created by Maarten Foukhar on 15-02-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MCCommonMethods.h"

/**
 *  A checkbox cell, which is attached to a text field
 *
 *  @discussion For example [X] [5000] bit/s
 */
@interface MCTextCheckBoxCell : NSButtonCell

/**
 *  Set the state without selecting the text field
 *
 *  @param value A state value
 */
- (void)setStateWithoutSelecting:(NSInteger)value;

/**
 *  The associated text field
 *
 *  @return A text field
 */
- (NSTextField *)textField;

@end
