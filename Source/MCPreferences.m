//
//  MCPreferences.m
//  Media Converter
//
//  Created by Maarten Foukhar on 25-01-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import "MCPreferences.h"
#import "MCConverter.h"
#import "MCPopupButton.h"
#import "MCOptionsDelegate.h";
#import "NSArray_Extensions.h"
#import "MCCheckBoxCell.h"
#import "NSNumber_Extensions.h"

@implementation MCPreferences

- (id)init
{
	if (self = [super init])
	{
		preferenceMappings = [[NSArray alloc] initWithObjects:	@"MCUseSoundEffects",			//1
																@"MCSaveMethod",				//2
																@"MCInstallMode",				//3
																@"MCDebug",						//4
																@"MCUseCustomFFMPEG",			//5
																@"MCCustomFFMPEG",				//6
		nil];
		
		viewMappings = [[NSArray alloc] initWithObjects:		@"-f",		//1
																@"-vcodec",	//2
																@"-b",		//3
																@"-s",		//4
																@"-r",		//5
																@"-acodec",	//6
																@"-ab",		//7
																@"-ar",		//8
		nil];
		
		itemsList = [[NSMutableDictionary alloc] init];
		presetsData = [[NSMutableArray alloc] init];
		
		[NSBundle loadNibNamed:@"MCPreferences" owner:self];
	}

	return self;
}

- (void)dealloc
{
	//Release our stuff
	[presetsData release];
	presetsData = nil;

	[preferenceMappings release];
	preferenceMappings = nil;
	
	[itemsList release];
	itemsList = nil;

	[toolbar release];
	toolbar = nil;

	[super dealloc];
}

- (void)awakeFromNib
{
	NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
	NSFileManager *defaultManager = [NSFileManager defaultManager];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tableViewSelectionDidChange:) name:@"MCListSelected" object:presetsTableView];
	
	//General
	NSString *temporaryFolder = [standardDefaults objectForKey:@"MCSaveLocation"];
	[saveFolderPopUp insertItemWithTitle:[defaultManager displayNameAtPath:temporaryFolder] atIndex:0];
	NSImage *folderImage = [[NSWorkspace sharedWorkspace] iconForFile:temporaryFolder];
	[folderImage setSize:NSMakeSize(16,16)];
	[[saveFolderPopUp itemAtIndex:0] setImage:folderImage];
	[[saveFolderPopUp itemAtIndex:0] setToolTip:[standardDefaults objectForKey:@"MCSaveLocation"]];
	
	[self setupPopups];
	[self reloadPresets];
	
	[presetsTableView registerForDraggedTypes:[NSArray arrayWithObject:@"NSGeneralPboardType"]];
	
	[presetsTableView setTarget:self];
	[presetsTableView setDoubleAction:@selector(editPreset)];
	
	[addTableView setTarget:self];
	[addTableView setDoubleAction:@selector(endAddSheet:)];
	
	//Load the options for our views
	[self setViewOptions:[NSArray arrayWithObjects:generalView, presetsView, advancedView, nil] infoObject:[NSUserDefaults standardUserDefaults] mappingsObject:preferenceMappings];
	
	[self setupToolbar];
	[toolbar setSelectedItemIdentifier:[standardDefaults objectForKey:@"MCSavedPrefView"]];
	[self toolbarAction:[toolbar selectedItemIdentifier]];
	
	NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
	[defaultCenter addObserver:self selector:@selector(saveFrame) name:NSWindowWillCloseNotification object:nil];

	NSWindow *myWindow = [self window];
	[myWindow setFrameUsingName:@"Preferences"];
}

- (void)saveFrame
{
	[[self window] saveFrameUsingName:@"Preferences"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

///////////////////
// Main actions //
///////////////////

#pragma mark -
#pragma mark •• Main actions

- (void)setDelegate:(id)del
{
	delegate = del;
}

//////////////////////
// PrefPane actions //
//////////////////////

#pragma mark -
#pragma mark •• PrefPane actions

- (void)showPreferences;
{
	[[self window] makeKeyAndOrderFront:self];
}

- (IBAction)setPreferenceOption:(id)sender
{
	NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
	NSInteger tag = [sender tag];
	id object = [sender objectValue];

	if (tag == 2 && [sender indexOfSelectedItem] == 5)
	{
		NSOpenPanel *sheet = [NSOpenPanel openPanel];
		[sheet setCanChooseFiles:NO];
		[sheet setCanChooseDirectories:YES];
		[sheet setAllowsMultipleSelection:NO];
		[sheet beginSheetForDirectory:nil file:nil types:nil modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(saveLocationOpenPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
	}
	else
	{
		[standardDefaults setObject:object forKey:[preferenceMappings objectAtIndex:tag - 1]];
	}
}

//General

#pragma mark -
#pragma mark •• - General

- (void)saveLocationOpenPanelDidEnd:(NSOpenPanel *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	[sheet orderOut:self];
	
	NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];

	if (returnCode == NSOKButton)
	{
		NSFileManager *defaultManager = [NSFileManager defaultManager];
		[saveFolderPopUp removeItemAtIndex:0];
		NSString *temporaryFolder = [sheet filename];
		[saveFolderPopUp insertItemWithTitle:[defaultManager displayNameAtPath:temporaryFolder] atIndex:0];
		NSImage *folderImage = [[NSWorkspace sharedWorkspace] iconForFile:temporaryFolder];
		[folderImage setSize:NSMakeSize(16,16)];
		NSMenuItem *item = [saveFolderPopUp itemAtIndex:0];
		[item setImage:folderImage];
		[item setToolTip:[[temporaryFolder stringByDeletingLastPathComponent] stringByAppendingPathComponent:[defaultManager displayNameAtPath:temporaryFolder]]];
		[saveFolderPopUp selectItemAtIndex:0];
	
		[standardDefaults setObject:[sheet filename] forKey:@"MCSaveLocation"];
		[standardDefaults setObject:[NSNumber numberWithInteger:0] forKey:@"MCSaveMethod"];
	}
	else
	{
		[saveFolderPopUp selectItemAtIndex:[[standardDefaults objectForKey:@"MCSaveMethod"] integerValue]];
	}
}

//Add actions

#pragma mark -
#pragma mark •• - Add actions

//Add actions
- (IBAction)endAddSheet:(id)sender
{
	NSInteger tag = [sender tag];
	
	if (tag == 1)
		[NSApp endSheet:addPanel returnCode:NSCancelButton];
	else
		[NSApp endSheet:addPanel returnCode:NSOKButton];
}

//Presets

#pragma mark -
#pragma mark •• - Presets

- (void)editPreset
{
	NSInteger selRow = [presetsTableView selectedRow];
	
	if (selRow > -1)
	{
		NSDictionary *currentData = [presetsData objectAtIndex:[presetsTableView selectedRow]];

		currentPresetPath = [[currentData objectForKey:@"Path"] retain];
		
		NSDictionary *presetDictionary = [NSDictionary dictionaryWithContentsOfFile:currentPresetPath];
	
		[nameField setStringValue:[presetDictionary objectForKey:@"Name"]];
		[extensionField setStringValue:[presetDictionary objectForKey:@"Extension"]];
	
		NSArray *options = [presetDictionary objectForKey:@"Encoder Options"];

		[self setViewOptions:[NSArray arrayWithObject:[presetsPanel contentView]] infoObject:options mappingsObject:viewMappings];
	
		extraOptions = [[NSMutableDictionary alloc] initWithDictionary:[presetDictionary objectForKey:@"Extra Options"]];
	
		[keepAspectButton setState:[[extraOptions objectForKey:@"Keep Aspect"] integerValue]];
		[autoAspectButton setState:[[extraOptions objectForKey:@"Auto Aspect"] integerValue]];
		[autoSizeButton setState:[[extraOptions objectForKey:@"Auto Size"] integerValue]];
		[twoPassButton setState:[[extraOptions objectForKey:@"Two Pass"] integerValue]];
		
		NSString *aspectString = [options objectForKey:@"-vf"];

		[aspectRatioButton setState:[[NSNumber numberWithBool:(aspectString != nil)] integerValue]];
		
		if (aspectString)
			[aspectRatioField setStringValue:[[aspectString componentsSeparatedByString:@"setdar="] objectAtIndex:1]];
	
		if ([options containsObject:[NSDictionary dictionaryWithObject:@"1" forKey:@"-ac"]])
			[modePopup selectItemAtIndex:0];
		else if ([options containsObject:[NSDictionary dictionaryWithObject:@"2" forKey:@"-ac"]])
			[modePopup selectItemAtIndex:1];
		else
			[modePopup selectItemAtIndex:3];
	
		[(MCOptionsDelegate *)[advancedTableView delegate] setOptions:options];
		[advancedTableView reloadData];
	
		[advancedCompleteButton setTitle:NSLocalizedString(@"Save", nil)];
	
		[NSApp beginSheet:presetsPanel modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:NULL];
	}
}

- (IBAction)addPreset:(id)sender
{	
	[NSApp beginSheet:addPanel modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(addPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)addPanelDidEnd:(NSWindow*)panel returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	[panel orderOut:self];
	
	if (returnCode == NSOKButton)
	{
		NSInteger selectedRow = [addTableView selectedRow];
		
		if (selectedRow == 0)
		{
			NSOpenPanel *sheet = [NSOpenPanel openPanel];
			[sheet setCanChooseFiles:YES];
			[sheet setCanChooseDirectories:NO];
			[sheet setAllowsMultipleSelection:YES];
			[sheet beginSheetForDirectory:nil file:nil types:[NSArray arrayWithObject:@"mcpreset"] modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(presetOpenPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
		}
		else
		{
			extraOptions = [[NSMutableDictionary alloc] init];

			[self clearOptionsInViews:[NSArray arrayWithObject:[presetsPanel contentView]]];
	
			[(MCOptionsDelegate *)[advancedTableView delegate] setOptions:[NSArray array]];
			[advancedTableView reloadData];
	
			[modePopup selectItemAtIndex:3];
	
			[self setOption:containerPopUp];
			[self setOption:videoFormatPopUp];
			[self setOption:audioFormatPopUp];

			[nameField setStringValue:NSLocalizedString(@"Untitled", nil)];
			[extensionField setStringValue:@""];
			[advancedCompleteButton setTitle:NSLocalizedString(@"Add", nil)];
			
			[keepAspectButton setState:NSOffState];
			[autoAspectButton setState:NSOffState];
			[autoSizeButton setState:NSOffState];
			[twoPassButton setState:NSOffState];
			
			[aspectRatioButton setState:NSOffState];
			[aspectRatioField setObjectValue:nil];
	
			[NSApp beginSheet:presetsPanel modalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:NULL];
		}
	}
}

- (NSInteger)installThemesWithNames:(NSArray *)names presetDictionaries:(NSArray *)dictionaries
{
	NSString *savePath = nil;

	BOOL editingPreset = (currentPresetPath && [[[NSDictionary dictionaryWithContentsOfFile:currentPresetPath] objectForKey:@"Name"] isEqualTo:[names objectAtIndex:0]]);

	if (editingPreset == YES)
	{
		savePath = currentPresetPath;
		
		NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
		
		NSDictionary *firstDictionary = [dictionaries objectAtIndex:0];
		NSString *newName = [firstDictionary objectForKey:@"Name"];
		NSString *oldName = [names objectAtIndex:0];
		
		if (![newName isEqualTo:oldName])
		{
			NSDictionary *preset = [NSDictionary dictionaryWithObjectsAndKeys:newName, @"Name", currentPresetPath, @"Path", nil];
			
			[presetsData replaceObjectAtIndex:[presetsTableView selectedRow] withObject:preset];
			[standardDefaults setObject:presetsData forKey:@"MCPresets"];
		}
	}

	if (!savePath)
	{
		NSString *applicationSupportFolder;
		NSInteger installMode = [[[NSUserDefaults standardUserDefaults] objectForKey:@"MCInstallMode"] integerValue];
		
		if (installMode == 0)
		{
			[NSApp runModalForWindow:installModePanel];
			[installModePanel orderOut:self];
				
			installMode = [installModePopup indexOfSelectedItem] + 1;
		}
			
		if (installMode == 1)
			applicationSupportFolder = @"/Library/Application Support";
		else if (installMode == 2)
			applicationSupportFolder = [@"~/Library/Application Support" stringByExpandingTildeInPath];
			
		NSFileManager *defaultManager = [NSFileManager defaultManager];
		NSString *folder = [applicationSupportFolder stringByAppendingPathComponent:@"Media Converter"];
			
		BOOL supportWritable = YES;
		NSString *error = NSLocalizedString(@"An unkown error occured", nil);
		
		if (![defaultManager fileExistsAtPath:folder])
			supportWritable = [MCCommonMethods createDirectoryAtPath:folder errorString:&error];
			
		if (supportWritable)
		{
			savePath = [folder stringByAppendingPathComponent:@"Presets"];
			
			if (![defaultManager fileExistsAtPath:savePath])
				supportWritable = [MCCommonMethods createDirectoryAtPath:savePath errorString:&error];
		}
		
		if (!supportWritable)
		{
			[MCCommonMethods standardAlertWithMessageText:NSLocalizedString(@"Failed to create 'Presets' folder", nil) withInformationText:error withParentWindow:nil];
				
			return NSCancelButton;
		}
	}
	
	if (!editingPreset)
	{
		NSMutableArray *duplicatePresetNames = [NSMutableArray array];
	
		NSInteger i;
		for (i = 0; i < [names count]; i ++)
		{
			NSString *name = [names objectAtIndex:i];
		
			if ([[presetsData objectsForKey:@"Name"] containsObject:name])
				[duplicatePresetNames addObject:name];
		}
	
		if ([duplicatePresetNames count] > 0)
		{
			NSAlert *alert = [[[NSAlert alloc] init] autorelease];
			[alert addButtonWithTitle:NSLocalizedString(@"Replace", nil)];
			[alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
			[[alert window] setDefaultButtonCell:[[[alert buttons] objectAtIndex:1] cell]];
		
			NSString *warningString;
			NSString *detailsString;
		
			if ([duplicatePresetNames count] > 1)
			{
				warningString = NSLocalizedString(@"Some presets allready exist. Do you want to replace them?", nil);
				detailsString = NSLocalizedString(@"There are some presets with the same names. Replacing them will remove the presets with the same name.", nil);
			}
			else
			{
				warningString = [NSString stringWithFormat:NSLocalizedString(@"'%@' already exists. Do you want to replace it?", nil), [duplicatePresetNames objectAtIndex:0]];
				detailsString = NSLocalizedString(@"A preset with the same name already exists. Replacing it will remove the preset with the same name.", nil);
			}
		
			[alert setMessageText:warningString];
			[alert setInformativeText:detailsString];
			NSInteger result = [alert runModal];

			if (result == NSAlertFirstButtonReturn)
			{
				for (i = 0; i < [duplicatePresetNames count]; i ++)
				{
					NSString *name = [duplicatePresetNames objectAtIndex:i];
					NSDictionary *presetDictionary = [presetsData objectAtIndex:[presetsData indexOfObject:name forKey:@"Name"]];
					[[NSFileManager defaultManager] removeFileAtPath:[presetDictionary objectForKey:@"Path"] handler:nil];
				}
			}
			else
			{
				return NSCancelButton;
			}
		}
	}
	
	NSInteger i;
	for (i = 0; i < [names count]; i ++)
	{
		NSString *name = [names objectAtIndex:i];
		
		// '/' in the Finder is in reality ':' took me a while to figure that out (failed to save the "iPod / iPhone" dict)
		NSMutableString *mString = [name mutableCopy];
		[mString replaceOccurrencesOfString:@"/" withString:@":" options:NSCaseInsensitiveSearch range:(NSRange){0,[mString length]}];
		name = [NSString stringWithString:[mString autorelease]];
		
		NSDictionary *dictionary = [dictionaries objectAtIndex:i];
		NSString *filePath;
		
		if (editingPreset)
			filePath = currentPresetPath;
		else
			filePath = [MCCommonMethods uniquePathNameFromPath:[[savePath stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"mcpreset"]];
		
		NSString *error = NSLocalizedString(@"An unkown error occured", nil);
		BOOL result = [MCCommonMethods writeDictionary:dictionary toFile:filePath errorString:&error];
		
		if (result == NO)
		{
			[MCCommonMethods standardAlertWithMessageText:NSLocalizedString(@"Failed install preset file", nil) withInformationText:error withParentWindow:nil];
		
			return NSCancelButton;
		}
	}
		
	[self reloadPresets];
	
	return NSOKButton;
}

- (void)presetOpenPanelDidEnd:(NSOpenPanel *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSOKButton)
		[self openPresetFiles:[sheet filenames]];
	
	[sheet orderOut:self];
}

- (void)openPresetFiles:(NSArray *)paths
{
	[toolbar setSelectedItemIdentifier:@"Presets"];
	[self toolbarAction:[toolbar selectedItemIdentifier]];

	NSInteger numberOfFiles = [paths count];
	NSMutableArray *names = [NSMutableArray array];
	NSMutableArray *dictionaries = [NSMutableArray array];

	NSInteger i;
	for (i = 0; i < numberOfFiles; i ++)
	{
		NSString *path = [paths objectAtIndex:i];
		NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:path];
			
		if (dictionary)
		{
			[names addObject:[dictionary objectForKey:@"Name"]];
			[dictionaries addObject:dictionary];
		}
	}
		
	NSInteger numberOfDicts = [dictionaries count];
	if (numberOfDicts == 0 | numberOfDicts < numberOfFiles)
	{
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
			
		if (numberOfDicts == 0)
		{
			[alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
		}
		else
		{
			[alert addButtonWithTitle:NSLocalizedString(@"Continue", nil)];
			[alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
			[[[alert buttons] objectAtIndex:1] setKeyEquivalent:@"\E"];
		}
		
		NSString *warningString;
		NSString *detailsString;
			
		if ((numberOfFiles - numberOfDicts) > 1)
		{
			warningString = NSLocalizedString(@"Failed to open preset files.", nil);
			detailsString = NSLocalizedString(@"Try re-downloading or re-copying them.", nil);
		}
		else
		{
			warningString = [NSString stringWithFormat:NSLocalizedString(@"Failed to open '%@'.", nil), [[NSFileManager defaultManager] displayNameAtPath:[paths objectAtIndex:0]]];
			detailsString = NSLocalizedString(@"Try re-downloading or re-copying it.", nil);
		}
			
		if (numberOfDicts > 0)
			detailsString = [NSString stringWithFormat:NSLocalizedString(@"%@ Would you like to continue?", nil), detailsString];
		
		[alert setMessageText:warningString];
		[alert setInformativeText:detailsString];
		NSInteger result = [alert runModal];

		if (result != NSAlertFirstButtonReturn | numberOfDicts == 0)
		{
			return;
		}

	}
			
	[self installThemesWithNames:names presetDictionaries:dictionaries];
}

- (IBAction)removePreset:(id)sender
{
	NSString *alertMessage;
	NSString *alertDetails;
	
	NSArray *selectedObjects = [MCCommonMethods allSelectedItemsInTableView:presetsTableView fromArray:presetsData];
	
	if ([selectedObjects count] > 0)
	{
		if ([selectedObjects count] > 1)
		{
			alertMessage = NSLocalizedString(@"Are you sure you want to remove the selected presets?", nil);
			alertDetails = NSLocalizedString(@"You won't be able to convert files using these presets in the future", nil);
		}
		else
		{
			alertMessage = NSLocalizedString(@"Are you sure you want to remove the selected preset?", nil);
			alertDetails = NSLocalizedString(@"You won't be able to convert files using this preset in the future", nil);
		}
	
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert addButtonWithTitle:NSLocalizedString(@"Yes", Localized)];
		[alert addButtonWithTitle:NSLocalizedString(@"No", Localized)];
		[alert setMessageText:alertMessage];
		[alert setInformativeText:alertDetails];
		[alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(removeAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
	}
}

- (void)removeAlertDidEnd:(NSWindow*)panel returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertFirstButtonReturn)
	{
		NSArray *selectedObjects = [MCCommonMethods allSelectedItemsInTableView:presetsTableView fromArray:presetsData];
		NSInteger i;
		for (i = 0; i < [selectedObjects count]; i ++)
		{
			NSDictionary *selectedObject = [selectedObjects objectAtIndex:i];
			[[NSFileManager defaultManager] removeFileAtPath:[selectedObject objectForKey:@"Path"] handler:nil];
		}
	}
	
	[self reloadPresets];
	[presetsTableView deselectAll:nil];
}

- (IBAction)endSheet:(id)sender
{
	NSInteger tag = [sender tag];
	
	if (tag != 98)
	{
		[presetsPanel endEditingFor:nil];
	
		NSMutableDictionary *presetDictionary;
		NSString *name;
		
		if (!currentPresetPath)
		{
			presetDictionary = [NSMutableDictionary dictionary];
			name = [nameField stringValue];
		}
		else
		{
			presetDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:currentPresetPath];
			name = [NSString stringWithString:[presetDictionary objectForKey:@"Name"]];
		}
	
		[presetDictionary setObject:[nameField stringValue] forKey:@"Name"];
		[presetDictionary setObject:@"1.0" forKey:@"Version"];
		[presetDictionary setObject:[extensionField stringValue] forKey:@"Extension"];
		[presetDictionary setObject:[(MCOptionsDelegate *)[advancedTableView delegate] options] forKey:@"Encoder Options"];
		[presetDictionary setObject:extraOptions forKey:@"Extra Options"];
		
		NSInteger result = [self installThemesWithNames:[NSArray arrayWithObject:name] presetDictionaries:[NSArray arrayWithObject:presetDictionary]];
		
		if (result != NSOKButton)
			return;
		
		[self reloadPresets];
	
		if (currentPresetPath)
		{
			[currentPresetPath release];
			currentPresetPath = nil;
		}
	
		[extraOptions release];
		extraOptions = nil;
	}
	
	[NSApp endSheet:presetsPanel];
	[presetsPanel orderOut:self];
}

- (IBAction)setMode:(id)sender
{
	NSString *settings = nil;

	if ([sender indexOfSelectedItem] < 2)
	{
		settings = [NSString stringWithFormat:@"%i", [sender indexOfSelectedItem] + 1];
	}

	NSMutableArray *advancedOptions = [(MCOptionsDelegate *)[advancedTableView delegate] options];
	[advancedOptions setObject:settings forKey:@"-ac"];
	[advancedTableView reloadData];
}

- (IBAction)toggleAdvancedView:(id)sender
{
	BOOL shouldExpand = ([sender state] == NSOnState);
	
	NSRect windowFrame = [presetsPanel frame];
	NSInteger newHeight = windowFrame.size.height;
	NSInteger newY = windowFrame.origin.y;

	if (shouldExpand)
	{
		newHeight = newHeight + 194;
		newY = newY - 194;
	}
	else
	{
		newHeight = newHeight - 194;
		newY = newY + 194;
	}
	
	if (shouldExpand)
		[presetsPanel setFrame:NSMakeRect(windowFrame.origin.x, newY, windowFrame.size.width, newHeight) display:YES animate:YES];
	
	[[advancedTableView enclosingScrollView] setHidden:(!shouldExpand)];
	[advancedAddButton setHidden:(!shouldExpand)];
	[advancedDeleteButton setHidden:(!shouldExpand)];
	[advancedBarButton setHidden:(!shouldExpand)];
	
	if (!shouldExpand)
		[presetsPanel setFrame:NSMakeRect(windowFrame.origin.x, newY, windowFrame.size.width, newHeight) display:YES animate:YES];
}

- (IBAction)setOption:(id)sender
{
	NSInteger index = [sender tag] - 1;
	NSString *option = [viewMappings objectAtIndex:index];
	NSString *settings = nil;
	
	NSMutableArray *advancedOptions = [(MCOptionsDelegate *)[advancedTableView delegate] options];
	
	if ([sender isKindOfClass:[MCPopupButton class]])
	{
		NSInteger selectedIndex = [(MCPopupButton *)sender indexOfSelectedItem];
		NSArray *rawTypes = [(MCPopupButton *)sender getArray];
		settings = [rawTypes objectAtIndex:selectedIndex];

		if ([settings isEqualTo:@"none"])
		{
			NSString *object = [advancedOptions objectForKey:option];

			if (object)
			{
				NSInteger index = [advancedOptions indexOfObject:[NSDictionary dictionaryWithObject:object forKey:option]];
				[advancedOptions removeObjectAtIndex:index];
			}
			
			if ([option isEqualTo:@"-acodec"])
				[advancedOptions setObject:@"" forKey:@"-an"];
			else
				[advancedOptions setObject:@"" forKey:@"-vn"];
				
			[advancedTableView reloadData];
				
			return;
		}
		else if ([option isEqualTo:@"-acodec"])
		{
			NSInteger index = [advancedOptions indexOfObject:[NSDictionary dictionaryWithObject:@"" forKey:@"-an"]];
			
			if (index != NSNotFound)
				[advancedOptions removeObjectAtIndex:index];
		}
		else if ([option isEqualTo:@"-vcodec"])
		{
			NSInteger index = [advancedOptions indexOfObject:[NSDictionary dictionaryWithObject:@"" forKey:@"-vn"]];
			
			if (index != NSNotFound)
				[advancedOptions removeObjectAtIndex:index];
		}
	}
	else
	{
		if ([sender objectValue])
			settings = [sender stringValue];
	}

	[advancedOptions setObject:settings forKey:option];
	[advancedTableView reloadData];
}

- (IBAction)setAspect:(id)sender
{
	NSMutableArray *advancedOptions = [(MCOptionsDelegate *)[advancedTableView delegate] options];

	NSString *option = @"-vf";
	NSString *option2 = @"-aspect";
	NSString *settings = nil;
	NSString *settings2 = nil;
	
	if ([sender objectValue])
	{
		if (![[sender stringValue] isEqualTo:@""])
		{
			settings = [NSString stringWithFormat:@"setdar=%@", [sender stringValue]];
			settings2 = [sender stringValue];
		}
	}
		
	[advancedOptions setObject:settings forKey:option];
	[advancedOptions setObject:settings2 forKey:option2];
	[advancedTableView reloadData];
}

- (IBAction)setKeepAspect:(id)sender
{
	[extraOptions setObject:[NSNumber numberWithInteger:[sender state]] forKey:@"Keep Aspect"];
}

- (IBAction)setAutoAspect:(id)sender
{
	[extraOptions setObject:[NSNumber numberWithInteger:[sender state]] forKey:@"Auto Aspect"];
}

- (IBAction)setAutoSize:(id)sender
{
	[extraOptions setObject:[NSNumber numberWithInteger:[sender state]] forKey:@"Auto Size"];
}

- (IBAction)setTwoPass:(id)sender
{
	[extraOptions setObject:[NSNumber numberWithInteger:[sender state]] forKey:@"Two Pass"];
}

- (IBAction)goToPresetSite:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://media-converter.sourceforge.net/presets.html"]];
}

- (IBAction)savePreset:(id)sender
{
	NSDictionary *dictionary = [presetsData objectAtIndex:[presetsTableView selectedRow]];
	NSString *name = [dictionary objectForKey:@"Name"];

	NSSavePanel *sheet = [NSSavePanel savePanel];
	[sheet setRequiredFileType:@"mcpreset"];
	[sheet setCanSelectHiddenExtension:YES];
	[sheet setMessage:NSLocalizedString(@"Choose a location to save the preset file", nil)];
	[sheet beginSheetForDirectory:nil file:[name stringByAppendingPathExtension:@"mcpreset"] modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(saveDocumentPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)saveDocumentPanelDidEnd:(NSSavePanel *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	[sheet orderOut:self];

	if (returnCode == NSOKButton) 
	{
		NSDictionary *dictionary = [presetsData objectAtIndex:[presetsTableView selectedRow]];
		NSDictionary *presetDictionary = [NSDictionary dictionaryWithContentsOfFile:[dictionary objectForKey:@"Path"]];
		
		NSString *error = NSLocalizedString(@"An unkown error occured", nil);
		BOOL result = [MCCommonMethods writeDictionary:presetDictionary toFile:[sheet filename] errorString:&error];
		
		if (result == NO)
		{
			[MCCommonMethods standardAlertWithMessageText:NSLocalizedString(@"Failed save preset file", nil) withInformationText:error withParentWindow:nil];
		}
	}
}

//Advanced

#pragma mark -
#pragma mark •• - Advanced

- (IBAction)chooseFFMPEG:(id)sender
{
	[NSApp runModalForWindow:commandPanel];
	[commandPanel orderOut:self];
	[self setupPopups];
}

//////////////////////////
// Install Mode actions //
//////////////////////////

#pragma mark -
#pragma mark •• Install Mode actions

- (IBAction)endSettingMode:(id)sender
{
	if ([suppressButton state] == NSOnState)
	{
		NSInteger mode = [installModePopup indexOfSelectedItem] + 1;
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:mode] forKey:@"MCInstallMode"];
		[(NSPopUpButton *)[generalView viewWithTag:3] selectItemAtIndex:mode];
		[suppressButton setState:NSOffState];
	}

	[NSApp abortModal];
}

/////////////////////
// Toolbar actions //
/////////////////////

#pragma mark -
#pragma mark •• Toolbar actions

- (NSToolbarItem *)createToolbarItemWithName:(NSString *)name
{
	NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:name];
	[toolbarItem autorelease];
	[toolbarItem setLabel:NSLocalizedString(name, Localized)];
	[toolbarItem setPaletteLabel:[toolbarItem label]];
	[toolbarItem setImage:[NSImage imageNamed:name]];
	[toolbarItem setTarget:self];
	[toolbarItem setAction:@selector(toolbarAction:)];
	[itemsList setObject:name forKey:name];

	return toolbarItem;
}

- (void)setupToolbar
{
	toolbar = [[NSToolbar alloc] initWithIdentifier:@"mainToolbar"];
	[toolbar autorelease];
	[toolbar setDelegate:self];
	[toolbar setAllowsUserCustomization:NO];
	[toolbar setAutosavesConfiguration:NO];
	[[self window] setToolbar:toolbar];
}

- (void)toolbarAction:(id)object
{
	id itemIdentifier;

	if ([object isKindOfClass:[NSToolbarItem class]])
		itemIdentifier = [object itemIdentifier];
	else
		itemIdentifier = object;
	
	id view = [self myViewWithIdentifier:itemIdentifier];

	[[self window] setContentView:[[[NSView alloc] initWithFrame:[view frame]] autorelease]];
	[self resizeWindowOnSpotWithRect:[view frame]];
	[[self window] setContentView:view];
	[[self window] setTitle:NSLocalizedString(itemIdentifier, Localized)];

	[[NSUserDefaults standardUserDefaults] setObject:itemIdentifier forKey:@"MCSavedPrefView"];
}

- (id)myViewWithIdentifier:(NSString *)identifier
{
	if ([identifier isEqualTo:@"General"])
		return generalView;
	else if ([identifier isEqualTo:@"Presets"])
		return presetsView;
	else if ([identifier isEqualTo:@"Advanced"])
		return advancedView;
	
	return nil;
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	return [self createToolbarItemWithName:itemIdentifier];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
	return [NSArray arrayWithObjects:NSToolbarSeparatorItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, @"General", @"Presets", @"Advanced", nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
	return [NSArray arrayWithObjects:@"General", @"Presets", @"Advanced", nil];
}

//////////////////////
// Tableview actions //
///////////////////////

#pragma mark -
#pragma mark •• Tableview actions

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	[saveButton setEnabled:([presetsTableView selectedRow] != -1 && [presetsTableView numberOfSelectedRows] == 1)];
}

//Count the number of rows, not really needed anywhere
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [presetsData count];
}

//return selected row
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSDictionary *presetData = [presetsData objectAtIndex:row];

	return [presetData objectForKey:[tableColumn identifier]];
}

//We don't want to make people change our row values
- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return NO;
}

//Needed to be able to drag rows
- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op
{
	NSInteger result = NSDragOperationNone;
	
	NSPasteboard *pboard = [info draggingPasteboard];
	NSData *data = [pboard dataForType:@"NSGeneralPboardType"];
	NSArray *rows = [NSUnarchiver unarchiveObjectWithData:data];
	NSInteger firstIndex = [[rows objectAtIndex:0] integerValue];
	
	if (row > firstIndex - 1 && row < firstIndex + [rows count] + 1)
		return result;

    if (op == NSTableViewDropAbove) {
        result = NSDragOperationMove;
    }

    return (result);
}

- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)op
{
	NSPasteboard *pboard = [info draggingPasteboard];

	if ([[pboard types] containsObject:@"NSGeneralPboardType"])
	{
		NSData *data = [pboard dataForType:@"NSGeneralPboardType"];
		NSArray *rows = [NSUnarchiver unarchiveObjectWithData:data];
		NSInteger firstIndex = [[rows objectAtIndex:0] integerValue];
	
		NSMutableArray *presets = [NSMutableArray array];
		
		NSInteger x;
		for (x = 0;x < [rows count];x++)
		{
			[presets addObject:[presetsData objectAtIndex:[[rows objectAtIndex:x] integerValue]]];
		}
		
		if (firstIndex < row)
		{
			for (x = 0;x < [presets count];x++)
			{
				NSInteger index = row - 1;
				
				[self moveRowAtIndex:[presetsData indexOfObject:[presets objectAtIndex:x]] toIndex:index];
			}
		}
		else
		{
			for (x = [presets count] - 1;x < [presets count];x--)
			{
				NSInteger index = row;
				
				[self moveRowAtIndex:[presetsData indexOfObject:[presets objectAtIndex:x]] toIndex:index];
			}
		}
	}
	
    return YES;
}

- (BOOL)tableView:(NSTableView *)view writeRows:(NSArray *)rows toPasteboard:(NSPasteboard *)pboard
{
	NSData *data = [NSArchiver archivedDataWithRootObject:rows];
	[pboard declareTypes: [NSArray arrayWithObjects:@"NSGeneralPboardType", nil] owner:nil];
	[pboard setData:data forType:@"NSGeneralPboardType"];
   
	return YES;
}

- (NSArray*)allSelectedItemsInTableView:(NSTableView *)tableView fromArray:(NSArray *)array
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

- (void)moveRowAtIndex:(NSInteger)index toIndex:(NSInteger)destIndex
{
	NSArray *allSelectedItems = [self allSelectedItemsInTableView:presetsTableView fromArray:presetsData];
	NSData *data = [NSArchiver archivedDataWithRootObject:[presetsData objectAtIndex:index]];
	BOOL isSelected = [allSelectedItems containsObject:[presetsData objectAtIndex:index]];
		
	if (isSelected)
		[presetsTableView deselectRow:index];
	
	if (destIndex < index)
	{
		NSInteger x;
		for (x = index; x > destIndex; x --)
		{
			id object = [presetsData objectAtIndex:x - 1];
	
			[presetsData replaceObjectAtIndex:x withObject:object];
		
			if ([allSelectedItems containsObject:object])
			{
				[presetsTableView deselectRow:x - 1];
				[presetsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:x] byExtendingSelection:YES];
			}
		}
	}
	else
	{
		NSInteger x;
		for (x = index;x<destIndex;x++)
		{
			id object = [presetsData objectAtIndex:x + 1];
	
			[presetsData replaceObjectAtIndex:x withObject:object];
		
			if ([allSelectedItems containsObject:object])
			{
				[presetsTableView deselectRow:x + 1];
				[presetsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:x] byExtendingSelection:YES];
			
			}
		}
	}
	
	[presetsData replaceObjectAtIndex:destIndex withObject:[NSUnarchiver unarchiveObjectWithData:data]];
				
	[presetsTableView reloadData];
	
	if (isSelected)
		[presetsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:destIndex] byExtendingSelection:YES];
	
	[[NSUserDefaults standardUserDefaults] setObject:presetsData forKey:@"MCPresets"];
	[delegate performSelector:@selector(update)];
}

///////////////////
// Other actions //
///////////////////

#pragma mark -
#pragma mark •• Other actions

- (void)resizeWindowOnSpotWithRect:(NSRect)aRect
{
    NSRect r = NSMakeRect([[self window] frame].origin.x - 
        (aRect.size.width - [[self window] frame].size.width), [[self window] frame].origin.y - 
        (aRect.size.height+78 - [[self window] frame].size.height), aRect.size.width, aRect.size.height+78);
    [[self window] setFrame:r display:YES animate:YES];
}

/* -----------------------------------------------------------------------------
	toolbarSelectableItemIdentifiers:
		Make sure all our custom items can be selected. NSToolbar will
		automagically select the appropriate item when it is clicked.
   -------------------------------------------------------------------------- */

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_3
-(NSArray*) toolbarSelectableItemIdentifiers: (NSToolbar*)toolbar
{
	return [itemsList allKeys];
}
#endif

- (void)setViewOptions:(NSArray *)views infoObject:(id)info mappingsObject:(NSArray *)mappings
{
	NSEnumerator *iter = [[[NSEnumerator alloc] init] autorelease];
	NSControl *cntl;

	NSInteger x;
	for (x = 0; x < [views count]; x ++)
	{
		NSView *currentView;
	
		if ([[views objectAtIndex:x] isKindOfClass:[NSView class]])
			currentView = [views objectAtIndex:x];
		else
			currentView = [[views objectAtIndex:x] view];
		
		iter = [[currentView subviews] objectEnumerator];
		while ((cntl = [iter nextObject]) != NULL)
		{
			if ([cntl isKindOfClass:[NSTabView class]])
			{
				[self setViewOptions:[(NSTabView *)cntl tabViewItems] infoObject:info mappingsObject:mappings];
			}
			else if ([cntl tag] > 0)
			{
				NSInteger index = [cntl tag] - 1;
				
				if (index < [mappings count])
				{
					id property = [info objectForKey:[mappings objectAtIndex:index]];
					
					[self setProperty:property forControl:cntl];

					property = nil;
				}
			}
		}
	}
}

- (void)setProperty:(id)property forControl:(id)control
{
	if (property)
	{
		if ([control isKindOfClass:[MCPopupButton class]])
		{
			NSInteger index = [[(MCPopupButton *)control getArray] indexOfObject:property];
			[(MCPopupButton *)control selectItemAtIndex:index];
		}
		else if ([control isKindOfClass:[NSTextField class]])
		{
			[control setStringValue:property];
		}
		else if ([[control cell] isKindOfClass:[MCCheckBoxCell class]])
		{
			[(MCCheckBoxCell *)[control cell] setStateWithoutSelecting:NSOnState];
		}
		else
		{
			[control setObjectValue:property];
		}
						
		[control setEnabled:YES];
	}
	else if (![control isKindOfClass:[NSButton class]])
	{
		[control setEnabled:NO];
	}
	else if ([[control cell] isKindOfClass:[MCCheckBoxCell class]])
	{
		[(MCCheckBoxCell *)[control cell] setStateWithoutSelecting:NSOffState];
	}
	else
	{
		[control setState:NSOffState];
	}
}

- (void)clearOptionsInViews:(NSArray *)views
{
	NSEnumerator *iter = [[[NSEnumerator alloc] init] autorelease];
	NSControl *cntl;

	NSInteger x;
	for (x = 0; x < [views count]; x ++)
	{
		NSView *currentView;
	
		if ([[views objectAtIndex:x] isKindOfClass:[NSView class]])
			currentView = [views objectAtIndex:x];
		else
			currentView = [[views objectAtIndex:x] view];
		
		iter = [[currentView subviews] objectEnumerator];
		while ((cntl = [iter nextObject]) != NULL)
		{
			if ([cntl isKindOfClass:[NSTabView class]])
			{
				[self clearOptionsInViews:[(NSTabView *)cntl tabViewItems]];
			}
			else
			{
				NSInteger index = [cntl tag] - 1;
				
				if (index < [viewMappings count])
				{
					if ([cntl isKindOfClass:[MCPopupButton class]])
					{
						[(MCPopupButton *)cntl selectItemAtIndex:0];
					}
					else 
					{
						if ([cntl isKindOfClass:[NSTextField class]])
							[cntl setEnabled:NO];
							
						[cntl setObjectValue:nil];
					}
				}
			}
		}
	}
}

- (void)reloadPresets
{
	[presetsData removeAllObjects];
	
	NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];

	NSString *folder1 = [@"~/Library/Application Support/Media Converter/Presets" stringByExpandingTildeInPath];
	NSString *folder2 = @"/Library/Application Support/Media Converter/Presets";
	
	NSArray *presetPaths = [MCCommonMethods getFullPathsForFolders:[NSArray arrayWithObjects:folder1, folder2, nil]];
	
	NSMutableArray *currentPresets = [NSMutableArray array];
	
	NSInteger i;
	for (i = 0; i < [presetPaths count]; i ++)
	{
		NSString *presetPath = [presetPaths objectAtIndex:i];
		
		if ([[[presetPath pathExtension] lowercaseString] isEqualTo:@"mcpreset"])
		{
			NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:presetPath];
		
			NSDictionary *presetDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[dictionary objectForKey:@"Name"], @"Name", presetPath, @"Path", nil];
			[currentPresets addObject:presetDictionary];
		}
	}
	
	NSMutableArray *savedPresets = [NSMutableArray arrayWithArray:[standardDefaults objectForKey:@"MCPresets"]];
	NSArray *staticSavedPresets = [standardDefaults objectForKey:@"MCPresets"];
	
	for (i = 0; i < [staticSavedPresets count]; i ++)
	{
		NSDictionary *savedPreset = [staticSavedPresets objectAtIndex:i];
		
		if ([currentPresets containsObject:savedPreset])
			[currentPresets removeObjectAtIndex:[currentPresets indexOfObject:savedPreset]];
		else
			[savedPresets removeObjectAtIndex:[savedPresets indexOfObject:savedPreset]];
	}
	
	[savedPresets addObjectsFromArray:currentPresets];
	[standardDefaults setObject:savedPresets forKey:@"MCPresets"];
	
	[presetsData addObjectsFromArray:savedPresets];
	
	[presetsTableView reloadData];
	
	[delegate performSelector:@selector(update)];
}

- (BOOL)updateForKey:(NSString *)key withProperty:(id)property
{
	if ([viewMappings containsObject:key])
	{
		NSInteger tag = [viewMappings indexOfObject:key] + 1;
		
		id control = [[presetsPanel contentView] viewWithTag:tag];
		
		if (!control)
		{
			NSArray *subViews = [[presetsPanel contentView] subviews];
			NSInteger i;
			for (i = 0; i < [subViews count]; i ++)
			{
				id subView = [subViews objectAtIndex:i];
				
				if ([subView isKindOfClass:[NSTabView class]])
				{
					NSArray *tabViewItems = [(NSTabView *)subView tabViewItems];
					NSInteger x;
					for (x = 0; x < [tabViewItems count]; x ++)
					{
						control = [[[tabViewItems objectAtIndex:x] view] viewWithTag:tag];
				
						if (control)
							break;
					}
				}
			}
		}
		
		if (control)
		{
			[self setProperty:property forControl:control];
			
			if ([[control cell] respondsToSelector:@selector(dependChild)])
				[self setProperty:property forControl:[[control cell] dependChild]];
		}
		
		return YES;
	}
	
	return NO;
}

- (void)setupPopups
{
	MCConverter *converter = [[MCConverter alloc] init];
	[containerPopUp setArray:[converter getFormats]];
	
	NSMutableArray *videoCodecs = [NSMutableArray arrayWithArray:[converter getVideoCodecs]];
	[videoCodecs insertObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Disable", nil), @"Name", @"none", @"Format", nil] atIndex:0];
	[videoCodecs insertObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Passthrough", nil), @"Name", @"copy", @"Format", nil] atIndex:1];
	[videoCodecs insertObject:[NSDictionary dictionaryWithObjectsAndKeys:@"", @"Name", @"", @"Format", nil] atIndex:2];
	[videoFormatPopUp setArray:videoCodecs];
	
	NSMutableArray *audioCodecs = [NSMutableArray arrayWithArray:[converter getAudioCodecs]];
	[audioCodecs insertObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Disable", nil), @"Name", @"none", @"Format", nil] atIndex:0];
	[audioCodecs insertObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Passthrough", nil), @"Name", @"copy", @"Format", nil] atIndex:1];
	[audioCodecs insertObject:[NSDictionary dictionaryWithObjectsAndKeys:@"", @"Name", @"", @"Format", nil] atIndex:2];
	[audioFormatPopUp setArray:audioCodecs];
	
	[converter release];
	converter = nil;
}

@end
