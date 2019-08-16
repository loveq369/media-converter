//
//  MCActionButton.h
//  Media Converter
//
//  Created by Maarten Foukhar on 27-07-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 *  An action menu button, show a menu when clicking it
 */
@interface MCActionButton : NSButton

/**
 *  Menu target
 */
 @property (nonatomic, assign, nullable) id menuTarget;

/**
 *  Add menu item
 *
 *  @param title Title of menu item
 *  @param selector A selector
 */
- (void)addMenuItemWithTitle:(nonnull NSString *)title withSelector:(nonnull SEL)selector;

/**
 *  Add separator item
 */
- (void)addSeparatorItem;

/**
 *  Set the title of a menu item
 *
 *  @param title A title
 *  @param index Index of menu item
 */
- (void)setTitle:(nonnull NSString *)title atIndex:(NSInteger)index;

@end
