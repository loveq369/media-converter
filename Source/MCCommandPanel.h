/* MCCommandController */

#import <Cocoa/Cocoa.h>

/**
 *  A window controller that handles the FFmpeg command choose dialog
 */
@interface MCCommandPanel : NSWindowController

- (void)beginSheetForWindow:(nonnull NSWindow *)window completionHandler:(nullable void (^)(NSModalResponse returnCode, NSString *_Nonnull commandPath))handler;
- (NSModalResponse)runModal;

@property (nonatomic, strong, readonly, nullable) NSString *path;

@end
