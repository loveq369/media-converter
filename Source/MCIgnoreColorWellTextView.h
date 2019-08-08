//
//  MCTextView.h
//  Media Converter
//
//  Created by Maarten Foukhar on 02-08-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 * A text view that can ignore two colour wells, needed because the colour wells are used for other purposes
 */
@interface MCIgnoreColorWellTextView : NSTextView

/**
 *  First ignore colour well
 */
@property (nonatomic, weak) IBOutlet NSColorWell *ignoreColorWell;

/**
 *  Second ignore colour well
 */
@property (nonatomic, weak) IBOutlet NSColorWell *secondIgnoreColorWell;

@end
