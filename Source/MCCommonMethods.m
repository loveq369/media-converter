//
//  MCCommonMethods.m
//  Media Converter
//
//  Created by Maarten Foukhar on 22-4-07.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import "MCCommonMethods.h"

@interface NSFileManager (MyUndocumentedMethodsForNSTheClass)

- (BOOL)createDirectoryAtPath:(NSString *)path withIntermediateDirectories:(BOOL)createIntermediates attributes:(NSDictionary *)attributes error:(NSError **)error;
- (BOOL)copyItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath error:(NSError **)error;
- (BOOL)removeItemAtPath:(NSString *)path error:(NSError **)error;

@end


@implementation MCCommonMethods

////////////////
// OS actions //
////////////////

#pragma mark -
#pragma mark •• OS actions

+ (NSInteger)OSVersion
{
	SInt32 MacVersion;
	
	Gestalt(gestaltSystemVersion, &MacVersion);
	
	return (NSInteger)MacVersion;
}

//////////////////
// File actions //
//////////////////

#pragma mark -
#pragma mark •• File actions

+ (NSString *)uniquePathNameFromPath:(NSString *)path
{
	if ([[NSFileManager defaultManager] fileExistsAtPath:path])
	{
		NSString *newPath = [path stringByDeletingPathExtension];
		NSString *pathExtension;

		if ([[path pathExtension] isEqualTo:@""])
			pathExtension = @"";
		else
			pathExtension = [@"." stringByAppendingString:[path pathExtension]];

		NSInteger y = 0;
		while ([[NSFileManager defaultManager] fileExistsAtPath:[newPath stringByAppendingString:pathExtension]])
		{
			newPath = [path stringByDeletingPathExtension];
			
			y = y + 1;
			newPath = [NSString stringWithFormat:@"%@ %i", newPath, y];
		}

		return [newPath stringByAppendingString:pathExtension];
	}
	else
	{
		return path;
	}
}

//Get full paths for multiple folders in an array
+ (NSArray *)getFullPathsForFolders:(NSArray *)folders
{
	NSMutableArray *paths = [NSMutableArray array];

	NSInteger x;
	for (x = 0; x < [folders count]; x ++)
	{
		NSString *folder = [folders objectAtIndex:x];
		NSArray *folderContents = [[NSFileManager defaultManager] directoryContentsAtPath:folder];
	
		NSInteger i;
		for (i = 0; i < [folderContents count]; i ++)
		{
			NSString *item = [folderContents objectAtIndex:i];
			NSString *path = [folder stringByAppendingPathComponent:item];
			[paths addObject:path];
		}
	}
	
	return paths;
}

///////////////////
// Error actions //
///////////////////

#pragma mark -
#pragma mark •• Error actions

+ (BOOL)createDirectoryAtPath:(NSString *)path errorString:(NSString **)error
{
	#if MAC_OS_X_VERSION_MAX_ALLOWED >= 1050
	NSFileManager *defaultManager = [NSFileManager defaultManager];
	NSError *myError;
	BOOL succes = [defaultManager createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:&myError];
			
	if (!succes)
		*error = [myError localizedDescription];
	#else
	
	BOOL succes = YES;
	NSString *details;
	NSFileManager *defaultManager = [NSFileManager defaultManager];
	
	if (![defaultManager fileExistsAtPath:path])
	{
		if ([MCCommonMethods OSVersion] >= 0x1050)
		{
			NSError *myError;
			succes = [defaultManager createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:&myError];
			
			if (!succes)
				details = [myError localizedDescription];
		}
		else
		{
			succes = [defaultManager createDirectoryAtPath:path attributes:nil];
			NSString *folder = [defaultManager displayNameAtPath:path];
			NSString *parent = [defaultManager displayNameAtPath:[path stringByDeletingLastPathComponent]];
			details = [NSString stringWithFormat:NSLocalizedString(@"Failed to create folder '%@' in '%@'.", nil), folder, parent];
		}
		
		if (!succes)
			*error = details;
	}
	#endif
	
	return succes;
}

+ (BOOL)copyItemAtPath:(NSString *)inPath toPath:(NSString *)newPath errorString:(NSString **)error
{
	#if MAC_OS_X_VERSION_MAX_ALLOWED >= 1050
	NSFileManager *defaultManager = [NSFileManager defaultManager];
	BOOL succes;
	NSError *myError;
	succes = [defaultManager copyItemAtPath:inPath toPath:newPath error:&myError];
			
	if (!succes)
		*error = [myError localizedDescription];
	
	return succes;
	#else

	BOOL succes = YES;
	NSString *details = @"";
	NSFileManager *defaultManager = [NSFileManager defaultManager];

	if ([MCCommonMethods OSVersion] >= 0x1050)
	{
		NSError *myError;
		succes = [defaultManager copyItemAtPath:inPath toPath:newPath error:&myError];
			
		if (!succes)
			details = [myError localizedDescription];
	}
	else
	{
		succes = [defaultManager copyPath:inPath toPath:newPath handler:nil];
	}
		
	if (!succes)
	{
		NSString *inFile = [defaultManager displayNameAtPath:inPath];
		NSString *outFile = [defaultManager displayNameAtPath:[newPath stringByDeletingLastPathComponent]];
		details = [NSString stringWithFormat:NSLocalizedString(@"Failed to copy '%@' to '%@'. %@", nil), inFile, outFile, details];
		*error = details;
	}
	#endif

	return succes;
}

+ (BOOL)removeItemAtPath:(NSString *)path
{
	#if MAC_OS_X_VERSION_MAX_ALLOWED >= 1050
	NSFileManager *defaultManager = [NSFileManager defaultManager];
	BOOL succes = YES;
	NSString *details;
	
	if ([defaultManager fileExistsAtPath:path])
	{
		NSError *myError;
		succes = [defaultManager removeItemAtPath:path error:&myError];
			
		if (!succes)
			details = [myError localizedDescription];
		
		if (!succes)
		{
			NSString *file = [defaultManager displayNameAtPath:path];
			[MCCommonMethods standardAlertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"Failed to delete '%@'.", nil), file ] withInformationText:details withParentWindow:nil];
		}
	}
	#else
	
	BOOL succes = YES;
	NSString *details;
	NSFileManager *defaultManager = [NSFileManager defaultManager];
	
	if ([defaultManager fileExistsAtPath:path])
	{
		if ([MCCommonMethods OSVersion] >= 0x1050)
		{
			NSError *myError;
			succes = [defaultManager removeItemAtPath:path error:&myError];
			
			if (!succes)
				details = [myError localizedDescription];
		}
		else
		{
			succes = [defaultManager removeFileAtPath:path handler:nil];
			details = [NSString stringWithFormat:NSLocalizedString(@"File path: %@", nil), path];
		}
		
		if (!succes)
		{
			NSString *file = [defaultManager displayNameAtPath:path];
			[MCCommonMethods standardAlertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"Failed to delete '%@'.", nil), file ] withInformationText:details withParentWindow:nil];
		}
	}
	#endif

	return succes;
}

+ (BOOL)writeDictionary:(NSDictionary *)dictionary toFile:(NSString *)path errorString:(NSString **)error
{
	if (![dictionary writeToFile:path atomically:YES])
	{
		NSFileManager *defaultManager = [NSFileManager defaultManager];
		NSString *file = [defaultManager displayNameAtPath:path];
		NSString *parent = [defaultManager displayNameAtPath:[path stringByDeletingLastPathComponent]];
		*error = [NSString stringWithFormat:NSLocalizedString(@"Failed to write '%@' to '%@'", nil), file, parent];
	
		return NO;
	}

	return YES;
}

////////////////////////
// Compatible actions //
////////////////////////

#pragma mark -
#pragma mark •• Compatible actions

+ (id)stringWithContentsOfFile:(NSString *)path
{
	#if MAC_OS_X_VERSION_MAX_ALLOWED < 1050
	if ([MCCommonMethods OSVersion] < 0x1040)
		return [NSString stringWithContentsOfFile:path];
	else
	#endif
		return [NSString stringWithContentsOfFile:path usedEncoding:nil error:nil];
}

///////////////////
// Other actions //
///////////////////

#pragma mark -
#pragma mark •• Other actions

+ (NSString *)ffmpegPath
{
	NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];

	if ([standardDefaults boolForKey:@"MCUseCustomFFMPEG"] == YES && [[NSFileManager defaultManager] fileExistsAtPath:[standardDefaults objectForKey:@"MCCustomFFMPEG"]])
		return [[NSUserDefaults standardUserDefaults] objectForKey:@"MCCustomFFMPEG"];
	else
		return [[NSBundle mainBundle] pathForResource:@"ffmpeg" ofType:@""];
}

+ (void)logCommandIfNeeded:(NSTask *)command
{
	//Set environment to UTF-8
	NSMutableDictionary *environment = [NSMutableDictionary dictionaryWithDictionary:[[NSProcessInfo processInfo] environment]];
	[environment setObject:@"en_US.UTF-8" forKey:@"LC_ALL"];
	[command setEnvironment:environment];

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"MCDebug"] == YES)
	{
		NSArray *showArgs = [command arguments];
		NSString *commandString = [command launchPath];

		NSInteger i;
		for (i=0;i<[showArgs count];i++)
		{
			commandString = [NSString stringWithFormat:@"%@ %@", commandString, [showArgs objectAtIndex:i]];
		}
	
		NSLog(@"%@", commandString);
	}
}

+ (BOOL)launchNSTaskAtPath:(NSString *)path withArguments:(NSArray *)arguments outputError:(BOOL)error outputString:(BOOL)string output:(id *)data
{
	id output;
	NSTask *task = [[NSTask alloc] init];
	NSPipe *pipe =[ [NSPipe alloc] init];
	NSPipe *outputPipe = [[NSPipe alloc] init];
	NSFileHandle *handle;
	NSFileHandle *outputHandle;
	NSString *errorString = @"";
	[task setLaunchPath:path];
	[task setArguments:arguments];
	[task setStandardError:pipe];
	handle = [pipe fileHandleForReading];
	
	if (!error)
	{
		[task setStandardOutput:outputPipe];
		outputHandle=[outputPipe fileHandleForReading];
	}
	
	[MCCommonMethods logCommandIfNeeded:task];
	[task launch];
	
	if (error)
		output = [handle readDataToEndOfFile];
	else
		output = [outputHandle readDataToEndOfFile];
		
	if (string)
	{
		output = [[[NSString alloc] initWithData:output encoding:NSUTF8StringEncoding] autorelease];
		
		if (!error)
			errorString = [[[NSString alloc] initWithData:[handle readDataToEndOfFile] encoding:NSUTF8StringEncoding] autorelease];

		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"MCDebug"])
			NSLog(@"%@\n%@", output, errorString);
	}
		
	[task waitUntilExit];
	
	NSInteger result = [task terminationStatus];

	if (!error && result != 0)
		output = errorString;
	
	[pipe release];
	pipe = nil;
	[outputPipe release];
	outputPipe = nil;
	[task release];
	task = nil;

	*data = output;
	
	return (result == 0);
}

+ (void)standardAlertWithMessageText:(NSString *)message withInformationText:(NSString *)information withParentWindow:(NSWindow *)parent
{
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert addButtonWithTitle:NSLocalizedString(@"OK", Localized)];
	[alert setMessageText:message];
	[alert setInformativeText:information];
	
	if (parent)
		[alert beginSheetModalForWindow:parent modalDelegate:self didEndSelector:nil contextInfo:nil];
	else
		[alert runModal];
}

+ (NSArray *)allSelectedItemsInTableView:(NSTableView *)tableView fromArray:(NSArray *)array
{
	NSMutableArray *items = [NSMutableArray array];
	NSIndexSet *indexSet = [tableView selectedRowIndexes];
	
	NSUInteger current_index = [indexSet firstIndex];
    while (current_index != NSNotFound)
    {
		if ([array objectAtIndex:current_index]) 
			[items addObject:[array objectAtIndex:current_index]];
			
        current_index = [indexSet indexGreaterThanIndex: current_index];
    }

	return items;
}

@end