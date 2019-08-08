//
//  MCCommonMethods.h
//  Media Converter
//
//  Created by Maarten Foukhar on 22-4-07.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <DiscRecording/DiscRecording.h>

@interface MCCommonMethods : NSObject

//OS actions

//File actions
//Get a non existing file name (example Folder 1, Folder 2 etc.)
+ (NSString *)uniquePathNameFromPath:(NSString *)path withSeperator:(NSString *)seperator;
//Get full paths for multiple folders in an array
+ (NSArray *)getFullPathsForFolders:(NSArray *)folders withType:(NSString *)type;

//String convertion actions
+ (CGFloat)secondsFromTimeString:(NSString *)timeString;

//Error actions
+ (BOOL)createDirectoryAtPath:(NSString *)path errorString:(NSString **)error;
+ (BOOL)copyItemAtPath:(NSString *)inPath toPath:(NSString *)newPath errorString:(NSString **)error;
+ (BOOL)moveItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath error:(NSString **)error;
+ (BOOL)removeItemAtPath:(NSString *)path;
+ (BOOL)writeString:(NSString *)string toFile:(NSString *)path errorString:(NSString **)error;
+ (BOOL)writeDictionary:(NSDictionary *)dictionary toFile:(NSString *)path errorString:(NSString **)error;

//Compatible methods
+ (id)stringWithContentsOfFile:(NSString *)path;
+ (id)stringWithContentsOfFile:(NSString *)path encoding:(NSStringEncoding)enc error:(NSError **)error;

//Other actions
//Get used ffmpeg
+ (NSString *)ffmpegPath;
//Log command with arguments for easier debugging
+ (NSString *)logCommandIfNeeded:(NSTask *)command;
//Conveniant method to load a NSTask
+ (BOOL)launchNSTaskAtPath:(NSString *)path withArguments:(NSArray *)arguments outputError:(BOOL)error outputString:(BOOL)string output:(id *)data inputPipe:(NSPipe *)inPipe predefinedTask:(NSTask *)preTask;
//Standard informative alert
+ (void)standardAlertWithMessageText:(NSString *)message withInformationText:(NSString *)information withParentWindow:(NSWindow *)parent withDetails:(NSString *)details;
//Get the selected items in the tableview
+ (NSArray *)allSelectedItemsInTableView:(NSTableView *)tableView fromArray:(NSArray *)array;
//Create a image with text
+ (CGImageRef)newOverlayImageWithObject:(id)object withSettings:(NSDictionary *)settings size:(NSSize)size;
//Calculate height for a string (used by subs)
+ (NSRect)frameForStringDrawing:(NSAttributedString *)myString forWidth:(float)myWidth;
//Get the application icon (needed since using Retina images messed things up)
+ (NSImage *)applicationImage;

+ (NSMutableAttributedString *)stringOnMainThreadWithHTML:(NSString *)html;
- (NSMutableAttributedString *)stringWithHTML:(NSString *)html;

+ (void)setViewOptions:(NSArray *)views infoObject:(id)info fallbackInfo:(id)fallback mappingsObject:(NSArray *)mappings startCount:(NSInteger)start;
+ (void)setProperty:(id)property forControl:(id)control;

+ (NSArray *)defaultHorizontalPopupArray;
+ (NSArray *)defaultVerticalPopupArray;

+ (NSMutableArray *)popupArrayWithNames:(NSArray *)names forFormats:(NSArray *)formats;

@end
