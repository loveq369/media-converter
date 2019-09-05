//
//  MCPreferences.h
//  Media Converter
//
//  Created by Maarten Foukhar on 25-01-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MCCommonMethods.h"

@class MCPreferences;

/**
 *  Preferences delegate, it notifies when the presets are updates
 */
@protocol MCPreferencesDelegate <NSObject>

/**
 *  Send when the presets are updated
 *
 *  @param preferences The preferences
 */
- (void)preferencesDidUpdatePresets:(MCPreferences * _Nonnull)preferences;

@end

/**
 *  Window controller that handles the preferences
 */
@interface MCPreferences : NSWindowController <NSToolbarDelegate>

/**
 *  A delegate that gets notified when the preferences are updated
 */
@property (nonatomic, assign, nullable) id <MCPreferencesDelegate> delegate;

/**
 *  Show the preferences
 */
- (void)showPreferences;

/**
 *  Reload the presets
 */
 - (void)reloadPresets;

@end
