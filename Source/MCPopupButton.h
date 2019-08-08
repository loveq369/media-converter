//
//  MCPopupButton.h
//  Media Converter
//
//  Created by Maarten Foukhar on 15-02-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MCCommonMethods.h"

/**
 *  A pop up button that makes it easier to load from an array
 */
 // TODO: find out what the delayed is all about
@interface MCPopupButton : NSPopUpButton

/**
 *  Set an array of items
 *
 *  @param array An array
 */
- (void)setArray:(NSArray *)array;

/**
 *  Get object value
 *
 *  @return An object
 */
- (id)objectValue;

/**
 *  Set object value
 *
 *  @param objectValue An object
 */
- (void)setObjectValue:(id)objectValue;

/**
 *  Index of object value
 *
 *  @param objectValue An object
 *
 *  @return An index
 */
- (NSInteger)indexOfObjectValue:(id)objectValue;

/**
 *  Set delayed
 *
 *  @param delayed Delayed or not
 */
- (void)setDelayed:(BOOL)delayed;

@end
