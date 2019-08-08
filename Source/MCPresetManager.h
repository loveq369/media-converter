//
//  MCPresetManager.h
//  Media Converter
//
//  Preset manager (edit, save, install etc.)
//
//  Created by Maarten Foukhar on 18-09-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 *  A manager for the Media Converter presets
 */
@interface MCPresetManager : NSWindowController

/**
 *  Get the default manager
 *
 *  @return A default manager object
 */
+ (MCPresetManager * _Nonnull)defaultManager;

/**
 *  Start a preset edit sheet
 *
 *  @param window Modal window
 *  @param path Path of the preset file
 *  @param handler A completion handler which returns a return code
 */
- (void)editPresetForWindow:(NSWindow * _Nonnull)window withPresetPath:(NSString * _Nullable)path completionHandler:(nullable void (^)(NSModalResponse returnCode))handler;

/**
 *  Start a preset save sheeet
 *
 *  @param window Modal window
 *  @param path Path to save the preset file
 */
- (void)savePresetForWindow:(NSWindow * _Nonnull)window withPresetPath:(NSString * _Nullable)path;

/**
 *  Open and add preset files
 *
 *  @param An array of file paths
 *
 *  @return Number of installed dictionaries
 */
- (NSInteger)openPresetFiles:(NSArray * _Nonnull)paths;

/**
 *  Update object in the current preset dictionary
 *
 *  @param key A key
 *  @param property An object
 *
 *  @return If succeeded or not
 */
- (BOOL)updateForKey:(NSString * _Nonnull)key withProperty:(id _Nullable)property;

/**
 *  Update preview
 */
- (void)updatePreview;

@end
