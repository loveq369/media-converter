//
//  MCProgress.h
//  Media Converter
//
//  Window controller for handling progress. (Original: KWProgress - Burn)
//
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 *  The progress manager is used for showing progress, you can start / end a sheet and change several properties
 */
@interface MCProgressPanel : NSWindowController

/**
 *  Shared progress panel
 *
 *  @return A shared progress panel instance
 */
+ (nonnull MCProgressPanel *)progressPanel;

/**
 *  Show a progress sheet
 *
 *  @param window   The window to attach the sheet to
 *  @param handler  Performed when the sheet closes
 */
- (void)beginSheetForWindow:(nonnull NSWindow *)window completionHandler:(nullable void (^)(NSModalResponse returnCode))handler;

/**
 *  Show a progress sheet
 *
 *  @param window   The window to attach the sheet to
 */
- (void)beginSheetForWindow:(nonnull NSWindow *)window;

/**
 *  Close the current progress sheet
 */
- (void)endSheet;

/**
 *  Close the current progress sheet
 *
 *  @param completion Called when done (on the main thread)
 */
- (void)endSheetWithCompletion:(void (^_Nullable)(void))completion;

/**
 *  The task shown to the user, for example: Copying files…
 */
@property (nonatomic, copy, nullable) NSString *task;

/**
 *  The status shown to the user, for example: Copying file 3 out of 12
 */
@property (nonatomic, copy, nullable) NSString *status;

/**
 *  The maximum value of the progress indicator
 */
@property (nonatomic) CGFloat maximumValue;

/**
 *  The value of the progress indicator
 */
@property (nonatomic) CGFloat value;

@property (nonatomic, strong, nonnull) NSString *cancelButtonTitle;

/**
 *  Enable or disable the cancel button on the progress sheet
 */
@property (nonatomic) BOOL allowCanceling;

/**
 *  Set the status by adding percent
 *
 *  A percentage
 */
- (void)setStatusByAddingPercent:(nonnull NSString *)percent;

/**
 *  Cancel handler
 */
@property (nonatomic, strong) void(^ _Nullable cancelHandler)(void);

@end
