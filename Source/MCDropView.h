//
//  MCDropView.h
//  Media Converter
//
//  NSView subclass handling dropping files in the main window
//
//  Created by Maarten Foukhar on 22-01-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MCDropView;

/**
 *  A drop view delegate gets notified about items dropped on it
 */
@protocol MCDropViewDelegate <NSObject>

/**
 *  Dropped files
 *
 *  @param dropView The drop view
 *  @param file An array of file paths
 */
- (void)dropView:(MCDropView *)dropView didDropFiles:(NSArray *)files;

/**
 *  Dropped a URL
 *
 *  @param dropView The drop view
 *  @param url The url (based on a dropped string)
 */
- (void)dropView:(MCDropView *)dropView didDropURL:(NSURL *)url;

@end

/**
 *  A drop view handle items that are dropped on it from other applications (like the Finder)
 */
@interface MCDropView : NSView

/**
 *  A drop view delegate
 */
@property (nonatomic, weak) IBOutlet id <MCDropViewDelegate> delegate;

@end
