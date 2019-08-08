//
//  MCTableView.h
//  Media Converter
//
//  Created by Maarten Foukhar on 05-03-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 *  Extra delegate methods, which are used for 
 */
@protocol MCTableViewDelegate <NSTableViewDelegate>

@optional
/**
 *  Edit
 *
 *  @param sender A sender
 */
- (IBAction)edit:(nullable id)sender;
/**
 *  Save document as
 *
 *  @param sender A sender
 */
- (IBAction)saveDocumentAs:(nullable id)sender;
/**
 *  Duplicate
 *
 *  @param sender A sender
 */
- (IBAction)duplicate:(nullable id)sender;
/**
 *  Delete
 *
 *  @param sender A sender
 */
- (IBAction)delete:(nullable id)sender;

@end

/**
 *  A table view class that passes responds to methods to delegate for specific methods and allows you to add a reload handler
 */
@interface MCTableView : NSTableView

/**
 *  Send on -reloadData
 */
@property (nonatomic, strong) void(^ _Nullable reloadHandler)(void);

@end
