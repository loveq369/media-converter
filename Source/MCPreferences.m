//
//  MCPreferences.m
//  Media Converter
//
//  Created by Maarten Foukhar on 25-01-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import "MCPreferences.h"
#import "MCConverter.h"
#import "MCProgressPanel.h"
#import "MCPopupButton.h"
#import "MCAdvancedOptionsDelegate.h"
#import "NSArray_Extensions.h"
#import "MCTextCheckBoxCell.h"
#import "MCActionButton.h"
#import "MCFilterDelegate.h"
#import "MCFilter.h"
#import <QuartzCore/QuartzCore.h>
#import "MCPresetEditPanel.h"
#import "MCTableView.h"
#import "MCAddPresetCellView.h"
#import "MCCommandPanel.h"
#import "MCMainController.h"
#import "MCPresetHelper.h"
#import <Sparkle/Sparkle.h>

@interface MCPreferences() <MCTableViewDelegate>

/* Preferences views */
// General
@property (nonatomic, strong) IBOutlet NSView *generalView;
@property (nonatomic, weak) IBOutlet NSButton *generalAutomaticUpdatesButton;
@property (nonatomic, weak) IBOutlet NSPopUpButton *saveFolderPopUp;
@property (nonatomic, weak) IBOutlet MCPopupButton *subtitleLanguagePopup;
// Presets
@property (nonatomic, strong) IBOutlet NSView *presetsView;
@property (nonatomic, weak) IBOutlet MCTableView *presetsTableView;
@property (nonatomic, weak) IBOutlet MCActionButton *presetsActionButton;
// Advanced
@property (nonatomic, strong) IBOutlet NSView *advancedView;
@property (nonatomic, weak) IBOutlet NSTextField *commandTextField;

/* Preset add panel */
@property (nonatomic, strong) IBOutlet NSPanel *addPanel;
@property (nonatomic, weak) IBOutlet NSTableView *addTableView;

/* Toolbar outlets */
@property (nonatomic, weak) IBOutlet NSToolbar *toolbar;

/* Variables */
@property (nonatomic, getter = isLoaded) BOOL loaded;
@property (nonatomic, strong) NSArray *preferenceMappings;
@property (nonatomic, strong) NSMutableArray *presetsData;

@property (nonatomic, strong) MCCommandPanel *commandPanel;

@end

@implementation MCPreferences

- (instancetype)init
{
    self = [super init];

    if (self != nil)
    {
	    _preferenceMappings = [[NSArray alloc] initWithObjects:     @"MCUseSoundEffects",    	    //1
                                                                    @"MCSaveMethod",	    	    //2
                                                                    @"MCInstallMode",	    	    //3
                                                                    @"MCDebug",	    	    	    //4
                                                                    @"MCUseCustomFFMPEG",    	    //5
                                                                    @"MCCustomFFMPEG",	    	    //6
                                                                    @"MCSubtitleLanguage",    	    //7
                                                                    @"MCQuitAfterConvertion",       //8
	    nil];
	    
	    _presetsData = [[NSMutableArray alloc] init];
	    _loaded = NO;
	    
        [[NSBundle mainBundle] loadNibNamed:@"MCPreferences" owner:self topLevelObjects:nil];
    }

    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
    NSFileManager *defaultManager =     [NSFileManager defaultManager];
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    
    [defaultCenter addObserver:self selector:@selector(tableViewSelectionDidChange:) name:@"MCListSelected" object:[self presetsTableView]];
    [defaultCenter addObserver:self selector:@selector(installModeChanged:) name:@"MCInstallModeChanged" object:nil];
    
    //General
    NSPopUpButton *saveFolderPopUp = [self saveFolderPopUp];
    NSString *temporaryFolder = [standardDefaults objectForKey:@"MCSaveLocation"];
    [saveFolderPopUp insertItemWithTitle:[defaultManager displayNameAtPath:temporaryFolder] atIndex:0];
    NSImage *folderImage = [[NSWorkspace sharedWorkspace] iconForFile:temporaryFolder];
    [folderImage setSize:NSMakeSize(16,16)];
    [[saveFolderPopUp itemAtIndex:0] setImage:folderImage];
    [[saveFolderPopUp itemAtIndex:0] setToolTip:[standardDefaults objectForKey:@"MCSaveLocation"]];
    
    NSMutableArray *subtitleLanguages = [NSMutableArray array];
    NSDictionary *languageDict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Languages" ofType:@"plist"]];
    NSArray *allKeys = [languageDict allKeys];
    
    NSInteger x;
    for (x = 0; x < [allKeys count]; x ++)
    {
	    NSString *currentKey = [allKeys objectAtIndex:x];
	    NSString *currentObject = [languageDict objectForKey:currentKey];
	    NSDictionary *newDict = [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(currentKey, nil), @"Name", currentObject, @"Format", nil];
	    [subtitleLanguages addObject:newDict];
    }
    
    [[self subtitleLanguagePopup] setArray:subtitleLanguages];
    
    [[self generalAutomaticUpdatesButton] setState:[[SUUpdater sharedUpdater] automaticallyChecksForUpdates]];
    
    [self reloadPresets];
    
    NSTableView *presetsTableView = [self presetsTableView];
    [presetsTableView registerForDraggedTypes:[NSArray arrayWithObject:@"NSGeneralPboardType"]];
    
    [presetsTableView setTarget:self];
    [presetsTableView setDoubleAction:@selector(edit:)];
    
    NSTableView *addTableView = [self addTableView];
    [addTableView setTarget:self];
    [addTableView setDoubleAction:@selector(endAddSheet:)];
    
    MCActionButton *presetsActionButton = [self presetsActionButton];
    [presetsActionButton setMenuTarget:self];
    [presetsActionButton addMenuItemWithTitle:NSLocalizedString(@"Edit Preset…", nil) withSelector:@selector(edit:)];
    [presetsActionButton addMenuItemWithTitle:NSLocalizedString(@"Duplicate Preset", nil) withSelector:@selector(duplicate:)];
    [presetsActionButton addMenuItemWithTitle:NSLocalizedString(@"Export Preset…", nil) withSelector:@selector(saveDocumentAs:)];
    
    //Load the options for our views
    [MCCommonMethods setViewOptions:[NSArray arrayWithObjects:[self generalView], [self presetsView], [self advancedView], nil] infoObject:[NSUserDefaults standardUserDefaults] fallbackInfo:nil mappingsObject:[self preferenceMappings] startCount:0];
    
    // Store the saved frame for later use
    NSString *savedFrameString = [[self window] stringWithSavedFrame];
    
    NSToolbar *toolbar = [self toolbar];
    [toolbar setSelectedItemIdentifier:[standardDefaults objectForKey:@"MCSavedPrefView"]];
    [self toolbarAction:[self selectedToolbarItem]];

    [defaultCenter addObserver:self selector:@selector(saveFrame) name:NSWindowWillCloseNotification object:nil];
    
    [[self window] setFrameFromString:savedFrameString];
    
    // TODO: why?
    [self setLoaded:YES];
}

- (void)saveFrame
{
    [[self window] saveFrameUsingName:@"Preferences"];
    [[NSUserDefaults standardUserDefaults] synchronize];
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

    if (tag == 2 && [sender indexOfSelectedItem] == 4)
    {
	    NSOpenPanel *sheet = [NSOpenPanel openPanel];
	    [sheet setCanChooseFiles:NO];
	    [sheet setCanChooseDirectories:YES];
	    [sheet setAllowsMultipleSelection:NO];
	    [sheet beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result)
        {
            NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];

            if (result == NSModalResponseOK)
            {
                NSString *fileName = [[sheet URL] path];
            
                NSFileManager *defaultManager =     [NSFileManager defaultManager];
                NSPopUpButton *saveFolderPopUp = [self saveFolderPopUp];
                [saveFolderPopUp removeItemAtIndex:0];
                NSString *temporaryFolder = fileName;
                [saveFolderPopUp insertItemWithTitle:[defaultManager displayNameAtPath:temporaryFolder] atIndex:0];
                NSImage *folderImage = [[NSWorkspace sharedWorkspace] iconForFile:temporaryFolder];
                [folderImage setSize:NSMakeSize(16.0, 16.0)];
                NSMenuItem *item = [saveFolderPopUp itemAtIndex:0];
                [item setImage:folderImage];
                [item setToolTip:[[temporaryFolder stringByDeletingLastPathComponent] stringByAppendingPathComponent:[defaultManager displayNameAtPath:temporaryFolder]]];
                [saveFolderPopUp selectItemAtIndex:0];
            
                [standardDefaults setObject:fileName forKey:@"MCSaveLocation"];
                [standardDefaults setObject:[NSNumber numberWithInteger:0] forKey:@"MCSaveMethod"];
            }
            else
            {
                [[self saveFolderPopUp] selectItemAtIndex:[[standardDefaults objectForKey:@"MCSaveMethod"] integerValue]];
            }
        }];
    }
    else
    {
	    [standardDefaults setObject:object forKey:[[self preferenceMappings] objectAtIndex:tag - 1]];
    }
}

// General

#pragma mark - General

- (IBAction)toggleAutomaticUpdates:(NSButton *)sender
{
    [[SUUpdater sharedUpdater] setAutomaticallyChecksForUpdates:[sender state]];
}


// PrefPane - Presets

#pragma mark -
#pragma mark •• - Presets

- (IBAction)delete:(id)sender
{
    NSString *alertMessage;
    NSString *alertDetails;
    
    NSTableView *presetsTableView = [self presetsTableView];
    NSArray *presetsData = [self presetsData];
    
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
    
	    NSAlert *alert = [[NSAlert alloc] init];
	    [alert addButtonWithTitle:NSLocalizedString(@"Yes", Localized)];
	    [alert addButtonWithTitle:NSLocalizedString(@"No", Localized)];
	    [alert setMessageText:alertMessage];
	    [alert setInformativeText:alertDetails];
	    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse returnCode)
        {
            if (returnCode == NSAlertFirstButtonReturn)
            {
                NSArray *selectedObjects = [MCCommonMethods allSelectedItemsInTableView:presetsTableView fromArray:presetsData];
                NSInteger i;
                for (i = 0; i < [selectedObjects count]; i ++)
                {
                    NSString *presetPath = [selectedObjects objectAtIndex:i];
                    [[NSFileManager defaultManager] removeItemAtPath:presetPath error:nil];
                }
                NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
                NSMutableArray *presets = [[standardDefaults objectForKey:@"MCPresets"] mutableCopy];
                [presets removeObjectsInArray:selectedObjects];
                [standardDefaults setObject:presets forKey:@"MCPresets"];
            
                [self reloadPresets];
                [[self delegate] preferencesDidUpdatePresets:self];
                [presetsTableView deselectAll:nil];
            }
        }];
    }
}

- (IBAction)addPreset:(id)sender
{    
    [[self window] beginSheet:[self addPanel] completionHandler:^(NSModalResponse returnCode)
    {
        if (returnCode == NSModalResponseOK)
        {
            NSInteger selectedRow = [[self addTableView] selectedRow];
            
            if (selectedRow == 0)
            {
                NSOpenPanel *sheet = [NSOpenPanel openPanel];
                [sheet setCanChooseFiles:YES];
                [sheet setCanChooseDirectories:NO];
                [sheet setAllowsMultipleSelection:YES];
                [sheet setAllowedFileTypes:@[@"mcpreset"]];
                [sheet beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result)
                {
                    if (result == NSModalResponseOK)
                    {
                        NSMutableArray *fileNames = [[NSMutableArray alloc] init];
                        for (NSURL *url in [sheet URLs])
                        {
                            [fileNames addObject:[url path]];
                        }
                    
                        [[MCPresetHelper sharedHelper] openPresetFiles:fileNames];
                        [self reloadPresets];
                        [[self delegate] preferencesDidUpdatePresets:self];
                    }
                }];
            }
            else
            {
                [[MCPresetEditPanel editPanel] beginModalForWindow:[self window] withPresetPath:nil completionHandler:^(NSModalResponse returnCode)
                {
                    if (returnCode == NSModalResponseOK)
                    {
                        [self reloadPresets];
                        [[self delegate] preferencesDidUpdatePresets:self];
                    }
                }];
            }
        }
    }];
}

- (IBAction)endAddSheet:(id)sender
{
    NSWindow *addPanel = [self addPanel];
    [[addPanel sheetParent] endSheet:addPanel returnCode:[sender tag]];
    [addPanel orderOut:nil];
}

- (IBAction)edit:(id)sender
{
    NSInteger selectedRow = [[self presetsTableView] selectedRow];
    
    if (selectedRow > - 1)
    {
	    NSString *presetPath = [[self presetsData] objectAtIndex:selectedRow];
        
	    [[MCPresetEditPanel editPanel] beginModalForWindow:[self window] withPresetPath:presetPath completionHandler:^(NSModalResponse returnCode)
        {
            if (returnCode == NSModalResponseOK)
            {
                [self reloadPresets];
                [[self delegate] preferencesDidUpdatePresets:self];
            }
        }];
    }
}

- (IBAction)duplicate:(id)sender
{
    NSTableView *presetsTableView = [self presetsTableView];
    NSArray *presetsData = [self presetsData];
    
    NSInteger selRow = [presetsTableView selectedRow];
    
    if (selRow > -1)
    {
	    NSArray *selectedObjects = [MCCommonMethods allSelectedItemsInTableView:presetsTableView fromArray:presetsData];
	    [presetsTableView deselectAll:nil];
	    
	    NSInteger i;
	    for (i = 0; i < [selectedObjects count]; i ++)
	    {
    	    NSString *path = [selectedObjects objectAtIndex:i];

    	    NSMutableDictionary *presetDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    	    NSString *newPath = [MCCommonMethods uniquePathNameFromPath:path withSeperator:@" "];
    	    NSString *newName = [[newPath lastPathComponent] stringByDeletingPathExtension];
    	    [presetDictionary setObject:newName forKey:@"Name"];
         
            NSMutableArray *presetSaveData = [presetsData mutableCopy];
            [presetSaveData addObject:newPath];
            [[NSUserDefaults standardUserDefaults] setObject:presetSaveData forKey:@"MCPresets"];
	    
    	    NSString *error = nil;
    	    BOOL result = [MCCommonMethods writeDictionary:presetDictionary toFile:newPath errorString:&error];
	    
    	    if (result == NO)
    	    {
	    	    [MCCommonMethods standardAlertWithMessageText:NSLocalizedString(@"Failed duplicate to preset file", nil) withInformationText:error withParentWindow:nil withDetails:nil];
    	    }
    	    else
    	    {
	    	    [self reloadPresets];
                [[self delegate] preferencesDidUpdatePresets:self];
	    	    NSInteger lastRow = [presetsData count] - 1;
	    	    [presetsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:lastRow] byExtendingSelection:YES];
    	    }
	    }
    }
}

- (IBAction)saveDocumentAs:(id)sender
{
    NSInteger selectedRow = [[self presetsTableView] selectedRow];
    
    if (selectedRow > - 1)
    {
	    NSString *presetPath = [[self presetsData] objectAtIndex:selectedRow];
	    
	    [[MCPresetEditPanel editPanel] savePresetForWindow:[self window] withPresetPath:presetPath];
    }
}

- (void)savePreset
{
    NSInteger selectedRow = [[self presetsTableView] selectedRow];
    
    if (selectedRow > - 1)
    {
	    NSString *presetPath = [[self presetsData] objectAtIndex:selectedRow];
	    
	    [[MCPresetEditPanel editPanel] savePresetForWindow:[self window] withPresetPath:presetPath];
    }
}

- (IBAction)goToPresetSite:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://media-converter.sourceforge.io/presets.html"]];
}

// PrefPane - Advanced

#pragma mark -
#pragma mark •• - Advanced

- (IBAction)chooseFFMPEG:(id)sender
{
    MCCommandPanel *commandPanel = [[MCCommandPanel alloc] init];
    [commandPanel beginSheetForWindow:[self window] completionHandler:^(NSModalResponse returnCode, NSString * _Nonnull commandPath)
    {
        if (returnCode == NSModalResponseOK)
        {
            NSString *path = [[commandPanel path] copy];
            [[self commandTextField] setStringValue:path];
            [[NSUserDefaults standardUserDefaults] setObject:path forKey:@"MCCustomFFMPEG"];
        }
        
        [self setCommandPanel:nil];
    }];
    [self setCommandPanel:commandPanel];

//    [[self window] beginSheet:[self commandPanel] completionHandler:nil];

//    NSPanel *commandPanel = [self commandPanel];
//    [NSApp runModalForWindow:commandPanel];
//    [commandPanel orderOut:self];
    //[self setupPopups];
    //[NSThread detachNewThreadSelector:@selector(setupPopups) toTarget:self withObject:nil];
}

- (IBAction)rebuildFonts:(id)sender
{
    [MCMainController updateFontListForWindow:[self window] withCompletion:nil];
}

/////////////////////
// Toolbar actions //
/////////////////////

#pragma mark -
#pragma mark •• Toolbar actions

- (IBAction)toolbarAction:(NSToolbarItem *)object
{
    NSToolbarItemIdentifier itemIdentifier = [object itemIdentifier];
    [[self toolbar] setSelectedItemIdentifier:itemIdentifier];
    
    id view = [self myViewWithIdentifier:itemIdentifier];
    NSRect frame = [view frame];
    NSWindow *window = [self window];
    [window setContentView:[[NSView alloc] initWithFrame:frame]];
    [self resizeWindowOnSpotWithRect:frame];
    [window setContentView:view];
    [window setTitle:NSLocalizedString(itemIdentifier, Localized)];
    
    [self saveFrame];

    [[NSUserDefaults standardUserDefaults] setObject:itemIdentifier forKey:@"MCSavedPrefView"];
}

- (id)myViewWithIdentifier:(NSString *)identifier
{
    if ([identifier isEqualTo:@"General"])
    {
	    return [self generalView];
    }
    else if ([identifier isEqualTo:@"Presets"])
    {
        return [self presetsView];
    }
    else if ([identifier isEqualTo:@"Advanced"])
    {
        return [self advancedView];
    }
    
    return nil;
}

//////////////////////
// Tableview actions //
///////////////////////

#pragma mark -
#pragma mark •• Tableview actions

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSString *newTitle;
    if ([[self presetsTableView] numberOfSelectedRows] > 1)
	    newTitle = NSLocalizedString(@"Duplicate Presets", nil);
    else
	    newTitle = NSLocalizedString(@"Duplicate Preset", nil);
	    
    [[self presetsActionButton] setTitle:newTitle atIndex:1];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ([self isLoaded] == YES)
    {
        NSTableView *presetsTableView = [self presetsTableView];
    
	    if (([presetsTableView selectedRow] == -1 || [presetsTableView numberOfSelectedRows] > 1) && (aSelector == @selector(edit:) || aSelector == @selector(saveDocumentAs:)))
    	    return NO;
	    
	    if (([presetsTableView selectedRow] == -1) && (aSelector == @selector(duplicate:) || (aSelector == @selector(delete:))))
    	    return NO;
    }
	    
    return [super respondsToSelector:aSelector];
}

//Count the number of rows, not really needed anywhere
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView == [self presetsTableView])
    {
        return [[self presetsData] count];
    }
    else if (tableView == [self addTableView])
    {
        return 2;
    }
    
    return 0;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (tableView == [self addTableView])
    {
        MCAddPresetCellView *cellView = [tableView makeViewWithIdentifier:[tableColumn identifier] owner:nil];
        if (row == 0)
        {
            [[cellView imageView] setImage:[NSImage imageNamed:@"MCPresets"]];
            [[cellView textField] setStringValue:NSLocalizedString(@"Open an existing preset file", nil)];
            [[cellView subTextField] setStringValue:NSLocalizedString(@"Choose a downloaded or copied preset file", nil)];
        }
        else
        {
            [[cellView imageView] setImage:[NSImage imageNamed:@"Create Preset"]];
            [[cellView textField] setStringValue:NSLocalizedString(@"Create a new preset", nil)];
            [[cellView subTextField] setStringValue:NSLocalizedString(@"This option is only for advanced users", nil)];
        }
        return cellView;
    }
    else if (tableView == [self presetsTableView])
    {
        NSString *presetPath = [[self presetsData] objectAtIndex:row];
        NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:presetPath];
        NSString *presetName = [dictionary objectForKey:[tableColumn identifier]];
    
        NSTableCellView *cellView = [tableView makeViewWithIdentifier:[tableColumn identifier] owner:nil];
        [[cellView textField] setStringValue:presetName];
        return cellView;
    }
    
    return [tableView makeViewWithIdentifier:[tableColumn identifier] owner:nil];
}

//We don't want to make people change our row values
- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return NO;
}

//Needed to be able to drag rows
- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op
{
    if (tableView != [self presetsTableView])
    {
        return NSDragOperationNone;
    }

    NSInteger result = NSDragOperationNone;
    
    NSPasteboard *pboard = [info draggingPasteboard];
    NSData *data = [pboard dataForType:@"NSGeneralPboardType"];
    NSIndexSet *rowIndexes = [NSUnarchiver unarchiveObjectWithData:data];
    NSInteger firstIndex = [rowIndexes firstIndex];
    
    if (row > firstIndex - 1 && row < firstIndex + [rowIndexes count] + 1)
	    return result;

    if (op == NSTableViewDropAbove) {
        result = NSDragOperationMove;
    }

    return (result);
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)op
{
    if (tableView != [self presetsTableView])
    {
        return NO;
    }

    NSPasteboard *pboard = [info draggingPasteboard];
    NSArray *presetsData = [self presetsData];

    if ([[pboard types] containsObject:@"NSGeneralPboardType"])
    {
	    NSData *data = [pboard dataForType:@"NSGeneralPboardType"];
        NSIndexSet *rowIndexes = [NSUnarchiver unarchiveObjectWithData:data];
        NSInteger firstIndex = [rowIndexes firstIndex];
    
	    NSMutableArray *presets = [NSMutableArray array];
     
        [rowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop)
        {
            [presets addObject:[presetsData objectAtIndex:idx]];
        }];
	    
	    if (firstIndex < row)
	    {
    	    for (id object in presets)
    	    {
	    	    NSInteger index = row - 1;
	    	    
	    	    [self moveRowAtIndex:[presetsData indexOfObject:object] toIndex:index];
    	    }
	    }
	    else
	    {
    	    for (id object in [presets reverseObjectEnumerator])
    	    {
	    	    NSInteger index = row;
	    	    
	    	    [self moveRowAtIndex:[presetsData indexOfObject:object] toIndex:index];
    	    }
	    }
    }
    
    return YES;
}

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pasteboard
{
    if (tableView != [self presetsTableView])
    {
        return NO;
    }

    NSData *data = [NSArchiver archivedDataWithRootObject:rowIndexes];
    [pasteboard declareTypes: [NSArray arrayWithObjects:@"NSGeneralPboardType", nil] owner:nil];
    [pasteboard setData:data forType:@"NSGeneralPboardType"];
   
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
    NSTableView *presetsTableView = [self presetsTableView];
    NSMutableArray *presetsData = [self presetsData];

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
    [[self delegate] preferencesDidUpdatePresets:self];
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


- (void)reloadPresets
{
    NSMutableArray *presetsData = [self presetsData];
    [presetsData removeAllObjects];
    NSArray *savedPresets = [[NSUserDefaults standardUserDefaults] objectForKey:@"MCPresets"];
    [presetsData addObjectsFromArray:savedPresets];

    [[self presetsTableView] reloadData];
}

- (void)installModeChanged:(NSNotification *)notification
{
    NSInteger mode = [[notification object] integerValue];
    [(NSPopUpButton *)[[self generalView] viewWithTag:3] selectItemAtIndex:mode];
}

- (NSToolbarItem *)selectedToolbarItem
{
    NSToolbar *toolbar = [self toolbar];
    NSToolbarItemIdentifier itemIdentifier = [toolbar selectedItemIdentifier];
    for (NSToolbarItem *item in [toolbar items])
    {
        if ([[item itemIdentifier] isEqualToString:itemIdentifier])
        {
            return item;
        }
    }
    
    return nil;
}

@end
