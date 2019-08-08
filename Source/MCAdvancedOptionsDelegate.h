//
//  MCOptionsDelegate.h
//
//  Created by Maarten Foukhar on 27-01-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 *  Option delegate for advanced FFmpeg options tableview
 */
@interface MCAdvancedOptionsDelegate : NSObject

/**
 *  Add options
 *
 *  @param options An array of options to add in the form of @[@{@"Option Name", @"Option"}]
 */
- (void)addOptions:(NSArray * _Nonnull)options;

/**
 *  The current options
 */
@property (nonatomic, readonly, nonnull) NSMutableArray *options;

@end
