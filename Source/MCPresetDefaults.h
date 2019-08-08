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
@interface MCPresetDefaults : NSObject

/**
 *  Get the preset defaults
 *
 *  @return A preset standard defaults object
 */
+ (MCPresetDefaults * _Nonnull)standardDefaults;

/**
 *  Get defaults
 *
 *  @return The default preset dictionary
 */
- (NSDictionary * _Nonnull)defaults;

/**
 * Extra options mappings
 */
@property (nonatomic, strong, nonnull) NSArray *extraOptionMappings;

/**
 *  Extra option default values
 */
@property (nonatomic, strong, nonnull) NSArray *extraOptionDefaultValues;

@end
