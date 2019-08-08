//
//  MCInstallPanel.h
//  Media Converter
//
//  Install panel where the user can choose between '/Library/Application Support' or '~/Library/Application Support'
//
//  Created by Maarten Foukhar on 08-05-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 *  A panel that offers the chose to install at a user or all users application support path
 */
@interface MCInstallPanel : NSObject

/**
 *  Shared install panel
 *
 *  @return A shared install panel instance
 */
+ (nonnull MCInstallPanel *)installPanel;

/**
 *  Run modal for install location
 *
 *  @discussion Runs a modal if needed, the user can choose to suppress it
 *
 *  @return A folder path
 */
- (nonnull NSString *)runModalForInstallLocation;

/**
 *  The task text
 */
@property (nonatomic, copy, nonnull) NSString *taskText;

@end
