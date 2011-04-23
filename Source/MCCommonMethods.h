//
//  MCCommonMethods.h
//  Media Converter
//
//  Created by Maarten Foukhar on 22-4-07.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <DiscRecording/DiscRecording.h>

#if MAC_OS_X_VERSION_MAX_ALLOWED < 1050
typedef int NSInteger;
typedef unsigned int NSUInteger;
typedef float CGFloat;
#endif

@interface MCCommonMethods : NSObject 
{

}

//OS actions
//Check for Snow Leopard (used to show new sizes divided by 1000 instead of 1024)
+ (NSInteger)OSVersion;

//File actions
//Get a non existing file name (example Folder 1, Folder 2 etc.)
+ (NSString *)uniquePathNameFromPath:(NSString *)path withSeperator:(NSString *)seperator;
//Get full paths for multiple folders in an array
+ (NSArray *)getFullPathsForFolders:(NSArray *)folders withType:(NSString *)type;

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
+ (NSFileManager *)defaultManager;

//Other actions
//Get used ffmpeg
+ (NSString *)ffmpegPath;
//Log command with arguments for easier debugging
+ (NSString *)logCommandIfNeeded:(NSTask *)command;
//Conveniant method to load a NSTask
+ (BOOL)launchNSTaskAtPath:(NSString *)path withArguments:(NSArray *)arguments outputError:(BOOL)error outputString:(BOOL)string output:(id *)data;
//Standard informative alert
+ (void)standardAlertWithMessageText:(NSString *)message withInformationText:(NSString *)information withParentWindow:(NSWindow *)parent;
//Get the selected items in the tableview
+ (NSArray *)allSelectedItemsInTableView:(NSTableView *)tableView fromArray:(NSArray *)array;

@end