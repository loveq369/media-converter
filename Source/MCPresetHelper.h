//
//  MCPresetDefaults.h
//  Media Converter
//
//  Created by Maarten Foukhar on 08/08/2019.
//

#import <Foundation/Foundation.h>

/**
 *  An object that stores the preset default
 */
@interface MCPresetHelper : NSObject

/**
 *  Get the preset defaults
 *
 *  @return A preset standard defaults object
 */
+ (nonnull MCPresetHelper *)sharedHelper;

/**
 *  Get defaults
 *
 *  @return The default preset dictionary
 */
- (nonnull NSDictionary *)defaults;

/**
 * Extra options mappings
 */
@property (nonatomic, strong, nonnull) NSArray *extraOptionMappings;

/**
 *  Extra option default values
 */
@property (nonatomic, strong, nonnull) NSArray *extraOptionDefaultValues;

/**
 *  Update the preset to the current version of Media Converter (ffmpeg)
 *
 *  @param path A path
 */
- (void)updatePresetAtPath:(nonnull NSString *)path;

/**
 *  Open and add preset files
 *
 *  @param An array of file paths
 *
 *  @return Number of installed dictionaries
 */
- (NSInteger)openPresetFiles:(nonnull NSArray *)paths;

@end
