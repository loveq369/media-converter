//
//  MCFilter.h
//  Media Converter
//
//  Created by Maarten Foukhar on 04-07-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 *  A filter prototype class, handling some of the basics
 */
@interface MCFilter : NSObject

/**
 *  Set options
 *
 *  @param options The options to set
 */
- (void)setOptions:(NSDictionary * _Nonnull)options;

/**
 *  Setup the view
 */
- (void)setupView;

/**
 *  Reset the view
 */
- (void)resetView;

/**
 *  The filter name
 *
 *  @return A string
 */
- (NSString * _Nonnull)name;

/**
 *  The localised name
 *
 *  @return A string
 */
+ (NSString * _Nonnull)localizedName;

/**
 *  The filters identifier
 *
 *  @return A string
 */
- (NSString * _Nonnull)filterIdentifier;

/**
 *  The filters view
 *
 *  @return A view
 */
- (NSView * _Nullable)filterView;

/**
 *  The filters mappings, keys, based on the tags of views
 *
 *  @return A list of keys
 */
- (NSArray * _Nonnull)filterMappings;

/**
 *  The filters values
 *
 *  @return A list of value
 */
- (NSArray * _Nonnull)filterDefaultValues;

/**
 *  The keys and values combined
 */
- (NSMutableDictionary * _Nonnull)filterOptions;

/**
 *  Get a previes image
 *
 *  @param size The preview image size
 *
 *  @return An image
 */
- (CGImageRef _Nonnull)imageWithSize:(NSSize)size;

/**
 *  A default outlet to set a filter option
 */
- (IBAction)setFilterOption:(id _Nullable)sender;

@end
