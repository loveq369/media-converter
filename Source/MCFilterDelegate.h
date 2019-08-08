//
//  MCFilterDelegate.h
//  Media Converter
//
//  Created by Maarten Foukhar on 25-06-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MCFilter.h"

/**
 *  Manages filters in table view
 */
@interface MCFilterDelegate : NSObject

/**
 *  Get a preview image
 *
 *  @param size The size to make the image
 *
 *  @return An image
 */
- (CGImageRef _Nonnull)previewImageWithSize:(NSSize)size;

/**
 *  The current filter options
 */
@property (nonatomic, copy, nonnull) NSMutableArray *filterOptions;

@end
