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
 *  A editor for the Media Converter presets
 */
@interface MCPresetEditPanel : NSWindowController

/**
 *  Get the edit panel
 *
 *  @return An edit panel object
 */
+ (nonnull MCPresetEditPanel *)editPanel;

/**
 *  Start a preset edit sheet
 *
 *  @param window Modal window
 *  @param path Path of the preset file
 *  @param handler A completion handler which returns a return code
 */
- (void)beginModalForWindow:(nonnull NSWindow *)window withPresetPath:(nullable NSString *)path completionHandler:(nullable void (^)(NSModalResponse returnCode))handler;

/**
 *  Start a preset save sheet
 *
 *  @param window Modal window
 *  @param path Path to save the preset file
 */
- (void)savePresetForWindow:(nonnull NSWindow *)window withPresetPath:(nullable NSString *)path;
/**
 *  Update object in the current preset dictionary
 *
 *  @param key A key
 *  @param property An object
 *
 *  @return If succeeded or not
 */
- (BOOL)updateForKey:(nonnull NSString *)key withProperty:(nullable id)property;

/**
 *  Update preview
 */
- (void)updatePreview;

/**
 *  Get the presets panel
 *
 *  @return A panel
 */
 - (nullable NSPanel *)presetsPanel;

@end
