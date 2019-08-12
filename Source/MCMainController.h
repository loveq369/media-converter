//
//  MCMainController.h
//  Media Converter
//
//  Controller for main window / menus
//
//  Created by Maarten Foukhar on 22-01-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 *  Main application controller
 */
@interface MCMainController : NSObject

/**
 *  Update font list
 *
 *  @param window The modal window
 *  @param completion Called when done
 */
+ (void)updateFontListForWindow:(NSWindow *)window withCompletion:(void (^)(void))completion;

@end
