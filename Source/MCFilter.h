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
 *  Initialise the filter without loading the interface
 *
 *  @return A newly created filter object
 */
- (nullable instancetype)initForPreview;

/**
 *  Set options
 *
 *  @param options The options to set
 */
- (void)setOptions:(nonnull NSDictionary *)options;

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
- (nonnull NSString *)name;

/**
 *  The localised name
 *
 *  @return A string
 */
+ (nonnull NSString *)localizedName;

/**
 *  Get the dictionary
 *
 *  @return A filter dictionary;
 */
- (nonnull NSDictionary *)filterDictionary;

/**
 *  The filters identifier
 *
 *  @return A string
 */
- (nonnull NSString *)filterIdentifier;

/**
 *  The filters view
 *
 *  @return A view
 */
- (nonnull NSView *)filterView;

/**
 *  The filters mappings, keys, based on the tags of views
 *
 *  @return A list of keys
 */
- (nonnull NSArray *)filterMappings;

/**
 *  The filters values
 *
 *  @return A list of value
 */
- (nonnull NSArray *)filterDefaultValues;

/**
 *  The keys and values combined
 */
- (nonnull NSMutableDictionary *)filterOptions;

/**
 *  Get a previes image
 *
 *  @param size The preview image size
 *
 *  @return An image
 */
- (nullable CGImageRef)newImageWithSize:(NSSize)size;

/**
 *  A default outlet to set a filter option
 */
- (IBAction)setFilterOption:(nullable id)sender;

@end
