//
//  MCPresetManager.m
//  Media Converter
//
//  Created by Maarten Foukhar on 18-09-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import "MCPresetManager.h"
#import "MCConverter.h"
#import "MCProgressPanel.h"
#import "MCPopupButton.h"
#import "MCAdvancedOptionsDelegate.h"
#import "NSArray_Extensions.h"
#import "MCTextCheckBoxCell.h"
#import "MCInstallPanel.h"
#import "MCActionButton.h"
#import "MCFilterDelegate.h"
#import "MCFilter.h"
#import <QuartzCore/QuartzCore.h>
#import "MCCommonMethods.h"

@interface MCPresetManager()

/* Preset panel */
@property (nonatomic, weak) IBOutlet NSPanel *presetsPanel;
@property (nonatomic, weak) IBOutlet NSButton *completeButton;
// General
@property (nonatomic, weak) IBOutlet NSTextField *nameField;
@property (nonatomic, weak) IBOutlet MCPopupButton *containerPopUp;
@property (nonatomic, weak) IBOutlet NSTextField *extensionField;
// Video
@property (nonatomic, weak) IBOutlet MCPopupButton *videoFormatPopUp;
@property (nonatomic, weak) IBOutlet NSButton *aspectRatioButton;
@property (nonatomic, weak) IBOutlet NSTextField *aspectRatioField;
// Audio
@property (nonatomic, weak) IBOutlet MCPopupButton *audioFormatPopUp;
@property (nonatomic, weak) IBOutlet NSPopUpButton *modePopup;
// Subtitles
@property (nonatomic, weak) IBOutlet MCPopupButton *subtitleFormatPopUp;
@property (nonatomic, weak) IBOutlet NSView *subtitleSettingsView;
// -> Hardcoded
@property (nonatomic, weak) IBOutlet NSView *hardcodedSettingsView;
@property (nonatomic, weak) IBOutlet MCPopupButton *hardcodedFontPopup;
@property (nonatomic, weak) IBOutlet MCPopupButton *hardcodedHAlignPopup;
@property (nonatomic, weak) IBOutlet MCPopupButton *hardcodedVAlignPopup;
@property (nonatomic, weak) IBOutlet MCPopupButton *hardcodedVisiblePopup;
@property (nonatomic, weak) IBOutlet NSTabView *hardcodedMethodTabView;
// -> DVD
@property (nonatomic, weak) IBOutlet NSView *DVDSettingsView;
@property (nonatomic, weak) IBOutlet MCPopupButton *fontPopup;
@property (nonatomic, weak) IBOutlet MCPopupButton *hAlignFormatPopUp;
@property (nonatomic, weak) IBOutlet MCPopupButton *vAlignFormatPopUp;
// -> Other
// No settings (yet)
// Filters
@property (nonatomic, weak) IBOutlet NSTableView *filterTableView;
@property (nonatomic, strong) IBOutlet MCFilterDelegate *filterDelegate;
// Advanced FFmpeg settings
@property (nonatomic, strong) IBOutlet MCAdvancedOptionsDelegate *optionDelegate;
@property (nonatomic, weak) IBOutlet NSTableView *advancedTableView;
@property (nonatomic, weak) IBOutlet NSButton *advancedAddButton;
@property (nonatomic, weak) IBOutlet NSButton *advancedDeleteButton;
@property (nonatomic, weak) IBOutlet NSButton *advancedBarButton;

/* Preview panel */
@property (nonatomic, strong) IBOutlet NSPanel *previewPanel;
@property (nonatomic, weak) IBOutlet NSImageView *previewImageView;

/* Variables */
@property (nonatomic, strong) NSArray *viewMappings;
@property (nonatomic, strong) NSArray *preferenceMappings;
@property (nonatomic, strong) NSArray *extraOptionMappings;
@property (nonatomic, strong) NSArray *extraOptionDefaultValues;
@property (nonatomic, strong) NSString *currentPresetPath;
@property (nonatomic, strong) NSMutableDictionary *extraOptions;
@property (nonatomic) NSModalSession session;
@property (nonatomic) BOOL previewOpened;
@property (nonatomic) BOOL darkBackground;

@end

@implementation MCPresetManager

static MCPresetManager *_defaultManager = nil;

- (instancetype)init
{
    self = [super init];

    if (self != nil)
    {
	    _viewMappings = [[NSArray alloc] initWithObjects:	    @"-f",	    //1
	    	    	    	    	    	    	    	    @"-vcodec", //2
	    	    	    	    	    	    	    	    @"-b",	    //3
	    	    	    	    	    	    	    	    @"-s",	    //4
	    	    	    	    	    	    	    	    @"-r",	    //5
	    	    	    	    	    	    	    	    @"-acodec", //6
	    	    	    	    	    	    	    	    @"-ab",	    //7
	    	    	    	    	    	    	    	    @"-ar",	    //8
	    nil];
	    
	    _extraOptionMappings = [[NSArray alloc] initWithObjects:
	    	    	    	    	    	    	    	    //Video
	    	    	    	    	    	    	    	    @"Keep Aspect",    	    	    	    	    // Tag: 101
	    	    	    	    	    	    	    	    @"Auto Aspect",    	    	    	    	    // Tag: 102
	    	    	    	    	    	    	    	    @"Auto Size",    	    	    	    	    // Tag: 103
	    	    	    	    	    	    	    	    
	    	    	    	    	    	    	    	    //Subtitles
	    	    	    	    	    	    	    	    @"Subtitle Type",	    	    	    	    // Tag: 104
	    	    	    	    	    	    	    	    @"Subtitle Default Language",    	    	    // Tag: 105
	    	    	    	    	    	    	    	    // Hardcoded
	    	    	    	    	    	    	    	    @"Font",	    	    	    	    	    // Tag: 106
	    	    	    	    	    	    	    	    @"Font Size",    	    	    	    	    // Tag: 107
	    	    	    	    	    	    	    	    @"Color",	    	    	    	    	    // Tag: 108
	    	    	    	    	    	    	    	    @"Horizontal Alignment",	    	    	    // Tag: 109
	    	    	    	    	    	    	    	    @"Vertical Alignment",    	    	    	    // Tag: 110
	    	    	    	    	    	    	    	    @"Left Margin",    	    	    	    	    // Tag: 111
	    	    	    	    	    	    	    	    @"Right Margin",	    	    	    	    // Tag: 112
	    	    	    	    	    	    	    	    @"Top Margin",    	    	    	    	    // Tag: 113
	    	    	    	    	    	    	    	    @"Bottom Margin",	    	    	    	    // Tag: 114
	    	    	    	    	    	    	    	    @"Method",	    	    	    	    	    // Tag: 115
	    	    	    	    	    	    	    	    @"Box Color",    	    	    	    	    // Tag: 116
	    	    	    	    	    	    	    	    @"Box Marge",    	    	    	    	    // Tag: 117
	    	    	    	    	    	    	    	    @"Box Alpha Value",	    	    	    	    // Tag: 118
	    	    	    	    	    	    	    	    @"Border Color",	    	    	    	    // Tag: 119
	    	    	    	    	    	    	    	    @"Border Size",    	    	    	    	    // Tag: 120
	    	    	    	    	    	    	    	    @"Alpha Value",    	    	    	    	    // Tag: 121
	    	    	    	    	    	    	    	    // DVD
	    	    	    	    	    	    	    	    @"Subtitle Font",	    	    	    	    // Tag: 122
	    	    	    	    	    	    	    	    @"Subtitle Font Size",    	    	    	    // Tag: 123
	    	    	    	    	    	    	    	    @"Subtitle Horizontal Alignment",	    	    // Tag: 124
	    	    	    	    	    	    	    	    @"Subtitle Vertical Alignment",    	    	    // Tag: 125
	    	    	    	    	    	    	    	    @"Subtitle Left Margin",	    	    	    // Tag: 126
	    	    	    	    	    	    	    	    @"Subtitle Right Margin",	    	    	    // Tag: 127
	    	    	    	    	    	    	    	    @"Subtitle Top Margin",    	    	    	    // Tag: 128
	    	    	    	    	    	    	    	    @"Subtitle Bottom Margin",	    	    	    // Tag: 129
	    	    	    	    	    	    	    	    
	    	    	    	    	    	    	    	    //Advanced
	    	    	    	    	    	    	    	    @"Two Pass",    	    	    	    	    // Tag: 130
	    	    	    	    	    	    	    	    @"Start Atom",    	    	    	    	    // Tag: 131
	    nil];
	    
	    _extraOptionDefaultValues = [[NSArray alloc] initWithObjects:
	    	    	    	    	    	    	    	    //Video
	    	    	    	    	    	    	    	    [NSNumber numberWithInt:1],    	    	    	    	    	    // Keep Aspect
	    	    	    	    	    	    	    	    [NSNumber numberWithBool:NO],	    	    	    	    	    // Auto Aspect
	    	    	    	    	    	    	    	    [NSNumber numberWithBool:NO],	    	    	    	    	    // Auto Size
	    	    	    	    	    	    	    	    
	    	    	    	    	    	    	    	    //Subtitles
	    	    	    	    	    	    	    	    @"Subtitle Type",    	    	    	    	    	    	    // Subtitle Type
	    	    	    	    	    	    	    	    @"Subtitle Default Language",	    	    	    	    	    // Subtitle Default Language
	    	    	    	    	    	    	    	    // Hardcoded
	    	    	    	    	    	    	    	    @"Helvetica",	    	    	    	    	    	    	    // Font
	    	    	    	    	    	    	    	    [NSNumber numberWithDouble:24],    	    	    	    	    // Font Size
	    	    	    	    	    	    	    	    [NSArchiver archivedDataWithRootObject:[NSColor whiteColor]],	    // Color
	    	    	    	    	    	    	    	    @"center",    	    	    	    	    	    	    	    // Horizontal Alignment
	    	    	    	    	    	    	    	    @"bottom",    	    	    	    	    	    	    	    // Vertical Alignment
	    	    	    	    	    	    	    	    [NSNumber numberWithInteger:0],	    	    	    	    	    // Left Margin
	    	    	    	    	    	    	    	    [NSNumber numberWithInteger:0],	    	    	    	    	    // Right Margin
	    	    	    	    	    	    	    	    [NSNumber numberWithInteger:0],	    	    	    	    	    // Top Margin
	    	    	    	    	    	    	    	    [NSNumber numberWithInteger:0],	    	    	    	    	    // Bottom Margin
	    	    	    	    	    	    	    	    @"border",    	    	    	    	    	    	    	    // Method
	    	    	    	    	    	    	    	    [NSArchiver archivedDataWithRootObject:[NSColor darkGrayColor]],    // Box Color
	    	    	    	    	    	    	    	    [NSNumber numberWithInteger:10],    	    	    	    	    // Box Marge
	    	    	    	    	    	    	    	    [NSNumber numberWithDouble:0.50],    	    	    	    	    // Box Alpha Value
	    	    	    	    	    	    	    	    [NSArchiver archivedDataWithRootObject:[NSColor blackColor]],	    // Border Color
	    	    	    	    	    	    	    	    [NSNumber numberWithInteger:4],	    	    	    	    	    // Border Size
	    	    	    	    	    	    	    	    [NSNumber numberWithDouble:1.0],    	    	    	    	    // Alpha Value
	    	    	    	    	    	    	    	    // DVD
	    	    	    	    	    	    	    	    @"Helvetica",	    	    	    	    	    	    	    // Subtitle Font
	    	    	    	    	    	    	    	    [NSNumber numberWithDouble:24],    	    	    	    	    // Subtitle Font Size
	    	    	    	    	    	    	    	    @"center",    	    	    	    	    	    	    	    // Subtitle Horizontal Alignment
	    	    	    	    	    	    	    	    @"bottom",    	    	    	    	    	    	    	    // Subtitle Vertical Alignment
	    	    	    	    	    	    	    	    [NSNumber numberWithInteger:60],    	    	    	    	    // Subtitle Left Margin
	    	    	    	    	    	    	    	    [NSNumber numberWithInteger:60],    	    	    	    	    // Subtitle Right Margin
	    	    	    	    	    	    	    	    [NSNumber numberWithInteger:20],    	    	    	    	    // Subtitle Top Margin
	    	    	    	    	    	    	    	    [NSNumber numberWithInteger:30],    	    	    	    	    // Subtitle Bottom Margin
	    	    	    	    	    	    	    	    
	    	    	    	    	    	    	    	    //Advanced
	    	    	    	    	    	    	    	    [NSNumber numberWithBool:NO],	    	    	    	    	    // Two Pass
	    	    	    	    	    	    	    	    [NSNumber numberWithBool:NO],	    	    	    	    	    // Start Atom
	    nil];
	    
	    _darkBackground = NO;
	    
        [[NSBundle mainBundle] loadNibNamed:@"MCPresetManager" owner:self topLevelObjects:nil];
    }

    return self;
}


- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self setupPopups];
}

//////////////////
// Main actions //
//////////////////

#pragma mark -
#pragma mark •• Main actions

+ (MCPresetManager *)defaultManager
{
    static MCPresetManager *defaultManager = nil;
    static dispatch_once_t onceToken = 0;

    dispatch_once(&onceToken, ^
    {
        defaultManager = [[MCPresetManager alloc] init];
    });
    
    return defaultManager;
}

- (void)editPresetForWindow:(NSWindow *)window withPresetPath:(NSString *)path completionHandler:(void (^)(NSModalResponse returnCode))handler;
{
    NSDictionary *presetDictionary;
    
    if (path)
    {
	    [self setCurrentPresetPath:path];
	    presetDictionary = [NSDictionary dictionaryWithContentsOfFile:path];
    }
    else
    {
	    presetDictionary = @{@"Encoder Options": @[], @"Extension": @"", @"Extra Options": @{}, @"Name": @"", @"Version": @"2.0"};
    }

    [[self nameField] setStringValue:presetDictionary[@"Name"]];
    [[self extensionField] setStringValue:presetDictionary[@"Extension"]];
    
    NSArray *options = [presetDictionary objectForKey:@"Encoder Options"];
    
    NSPanel *presetsPanel = [self presetsPanel];

    [MCCommonMethods setViewOptions:[NSArray arrayWithObject:[presetsPanel contentView]] infoObject:options fallbackInfo:nil mappingsObject:[self viewMappings] startCount:0];

    [self setExtraOptions:[presetDictionary[@"Extra Options"] mutableCopy]];
    
    NSArray *extraOptionMappings = [self extraOptionMappings];
    [MCCommonMethods setViewOptions:[NSArray arrayWithObjects:[presetsPanel contentView], [self DVDSettingsView], [self hardcodedSettingsView], nil] infoObject:[self extraOptions] fallbackInfo:[NSDictionary dictionaryWithObjects:[self extraOptionDefaultValues] forKeys:extraOptionMappings] mappingsObject:extraOptionMappings startCount:100];
    
    NSMutableArray *filters;
    
    if ([[presetDictionary allKeys] containsObject:@"Video Filters"])
	    filters = [NSMutableArray arrayWithArray:[presetDictionary objectForKey:@"Video Filters"]];
    else
	    filters = [NSMutableArray array];
    
    [[self filterDelegate] setFilterOptions:filters];
    
    [self setSubtitleKind:nil];
    [self setHarcodedVisibility:nil];
	    
    NSString *aspectString = [options objectForKey:@"-vf"];
	    
    if (aspectString)
    {
	    if ([aspectString rangeOfString:@"setdar="].length > 0 && [[aspectString componentsSeparatedByString:@"setdar="] count] > 1)
        {
    	    [[self aspectRatioField] setStringValue:[[aspectString componentsSeparatedByString:@"setdar="] objectAtIndex:1]];
        }
	    else
        {
    	    aspectString = nil;
        }
    }

    [[self aspectRatioButton] setState:[[NSNumber numberWithBool:(aspectString != nil)] integerValue]];
    
    NSPopUpButton *modePopup = [self modePopup];
    if ([options containsObject:[NSDictionary dictionaryWithObject:@"1" forKey:@"-ac"]])
	    [modePopup selectItemAtIndex:0];
    else if ([options containsObject:[NSDictionary dictionaryWithObject:@"2" forKey:@"-ac"]])
	    [modePopup selectItemAtIndex:1];
    else
	    [modePopup selectItemAtIndex:3];
        
    [[self optionDelegate] addOptions:options];
    [[self advancedTableView] reloadData];
    
    [[self completeButton] setTitle:NSLocalizedString(@"Save", nil)];
    
    [self updatePreview];
    
    [NSApp beginSheet:presetsPanel modalForWindow:window modalDelegate:self didEndSelector:nil contextInfo:nil];
    [window beginSheet:[self window] completionHandler:^(NSModalResponse returnCode)
    {
        if (handler != nil)
        {
            handler(returnCode);
        }
    }];
}

- (void)savePresetForWindow:(NSWindow *)window withPresetPath:(NSString *)path
{
    NSDictionary *presetDictionary = [[NSDictionary alloc] initWithContentsOfFile:path];
    NSString *name = [presetDictionary objectForKey:@"Name"];

    NSSavePanel *sheet = [NSSavePanel savePanel];
    [sheet setAllowedFileTypes:@[@"mcpreset"]];
    [sheet setCanSelectHiddenExtension:YES];
    [sheet setMessage:NSLocalizedString(@"Choose a location to save the preset file", nil)];
    [sheet setNameFieldStringValue:[name stringByAppendingPathExtension:@"mcpreset"]];
    [sheet beginSheetModalForWindow:window completionHandler:^(NSModalResponse result)
    {
        if (result == NSModalResponseOK)
        {
            NSString *error = NSLocalizedString(@"An unkown error occured", nil);
            BOOL result = [MCCommonMethods writeDictionary:presetDictionary toFile:[[sheet URL] path] errorString:&error];

            if (result == NO)
                [MCCommonMethods standardAlertWithMessageText:NSLocalizedString(@"Failed save preset file", nil) withInformationText:error withParentWindow:nil withDetails:nil];
        }
    }];
}

- (NSInteger)openPresetFiles:(NSArray *)paths
{
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
	    NSAlert *alert = [[NSAlert alloc] init];
    	    
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
    	    return 0;
	    }

    }
    	    
    [self installPresetsWithNames:names presetDictionaries:dictionaries];
    
    return [dictionaries count];
}

- (NSInteger)installPresetsWithNames:(NSArray *)names presetDictionaries:(NSArray *)dictionaries
{
    NSString *savePath = nil;
    
    NSString *currentPresetPath = [self currentPresetPath];
    BOOL editingPreset = (currentPresetPath && [[[NSDictionary dictionaryWithContentsOfFile:currentPresetPath] objectForKey:@"Name"] isEqualTo:[names objectAtIndex:0]]);

    if (editingPreset == YES)
    {
	    savePath = currentPresetPath;
	    
	    NSDictionary *firstDictionary = [dictionaries objectAtIndex:0];
	    NSString *newName = [firstDictionary objectForKey:@"Name"];
	    NSString *oldName = [names objectAtIndex:0];
	    
	    if (![newName isEqualTo:oldName])
	    {
    	    /*NSDictionary *preset = [NSDictionary dictionaryWithObjectsAndKeys:newName, @"Name", currentPresetPath, @"Path", nil];
    	    
    	    [presetsData replaceObjectAtIndex:[presetsTableView selectedRow] withObject:preset];
    	    [standardDefaults setObject:presetsData forKey:@"MCPresets"];*/
	    }
    }

    if (!savePath)
    {
        MCInstallPanel *installPanel = [MCInstallPanel installPanel];
	    [installPanel setTaskText:NSLocalizedString(@"Install Presets for:", nil)];
	    NSString *applicationSupportFolder = [installPanel runModalForInstallLocation];
    	    
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
    	    [MCCommonMethods standardAlertWithMessageText:NSLocalizedString(@"Failed to create 'Presets' folder", nil) withInformationText:error withParentWindow:nil withDetails:nil];
	    	    
    	    return NSCancelButton;
	    }
    }
    
    if (!editingPreset)
    {
	    NSMutableArray *duplicatePresetNames = [NSMutableArray array];
    
	    NSInteger i;
	    for (i = 0; i < [names count]; i ++)
	    {
    	    //NSString *name = [names objectAtIndex:i];
	    
    	    //if ([[presetsData objectsForKey:@"Name"] containsObject:name])
    	    //    [duplicatePresetNames addObject:name];
	    }
    
	    if ([duplicatePresetNames count] > 0)
	    {
    	    NSAlert *alert = [[NSAlert alloc] init];
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
    	    	    //NSString *name = [duplicatePresetNames objectAtIndex:i];
    	    	    //NSDictionary *presetDictionary = [presetsData objectAtIndex:[presetsData indexOfObject:name forKey:@"Name"]];
    	    	    //[[NSFileManager defaultManager] removeFileAtPath:[presetDictionary objectForKey:@"Path"] handler:nil];
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
	    name = [NSString stringWithString:mString];
	    
	    NSDictionary *dictionary = [dictionaries objectAtIndex:i];
	    NSString *filePath;
	    
	    if (editingPreset)
    	    filePath = currentPresetPath;
	    else
    	    filePath = [MCCommonMethods uniquePathNameFromPath:[[savePath stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"mcpreset"] withSeperator:@" "];
	    
	    NSString *error = NSLocalizedString(@"An unkown error occured", nil);
	    BOOL result = [MCCommonMethods writeDictionary:dictionary toFile:filePath errorString:&error];
	    
	    if (result == NO)
	    {
    	    [MCCommonMethods standardAlertWithMessageText:NSLocalizedString(@"Failed install preset file", nil) withInformationText:error withParentWindow:nil withDetails:nil];
	    
    	    return NSCancelButton;
	    }
    }
	    
    //[self reloadPresets];
    
    return NSOKButton;
}

- (NSMutableDictionary *)presetDictionary
{
    NSMutableDictionary *presetDictionary;
    NSString *name;
    NSString *currentPresetPath = [self currentPresetPath];
    
    if (!currentPresetPath)
    {
	    presetDictionary = [NSMutableDictionary dictionary];
	    name = [[self nameField] stringValue];
    }
    else
    {
	    presetDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:currentPresetPath];
	    name = [NSString stringWithString:[presetDictionary objectForKey:@"Name"]];
    }
    
    [presetDictionary setObject:[[self nameField] stringValue] forKey:@"Name"];
    [presetDictionary setObject:@"1.3" forKey:@"Version"];
    [presetDictionary setObject:[[self extensionField] stringValue] forKey:@"Extension"];
    [presetDictionary setObject:[[self optionDelegate] options] forKey:@"Encoder Options"];
    [presetDictionary setObject:[self extraOptions] forKey:@"Extra Options"];
    [presetDictionary setObject:[[self filterDelegate] filterOptions] forKey:@"Video Filters"];
    
    return presetDictionary;
}

//////////////////////////
// Preset panel actions //
//////////////////////////

#pragma mark -
#pragma mark •• Preset panel actions

- (IBAction)toggleAdvancedView:(id)sender
{
    BOOL shouldExpand = ([sender state] == NSOnState);
    
    NSPanel *presetsPanel = [self presetsPanel];
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
    
    [[[self advancedTableView] enclosingScrollView] setHidden:(!shouldExpand)];
    [[self advancedAddButton] setHidden:(!shouldExpand)];
    [[self advancedDeleteButton] setHidden:(!shouldExpand)];
    [[self advancedBarButton] setHidden:(!shouldExpand)];
    
    if (!shouldExpand)
	    [presetsPanel setFrame:NSMakeRect(windowFrame.origin.x, newY, windowFrame.size.width, newHeight) display:YES animate:YES];
}

- (IBAction)setOption:(id)sender
{
    NSInteger index = [sender tag] - 1;
    NSString *option = [self viewMappings][index];
    NSString *settings = [sender objectValue];
    
    NSMutableArray *advancedOptions = [[self optionDelegate] options];
    
    if ([sender isKindOfClass:[MCPopupButton class]])
    {
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
	    	    
    	    [[self advancedTableView] reloadData];
	    	    
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
    [[self advancedTableView] reloadData];
}

- (IBAction)setExtraOption:(id)sender
{
    NSInteger index = [sender tag] - 101;
    NSString *option = [[self extraOptionMappings] objectAtIndex:index];

    [[self extraOptions] setObject:[sender objectValue] forKey:option];
    [[self advancedTableView] reloadData];
    
    if ([sender tag] > 105 && [sender tag] < 122)
    {
	    [self updatePreview];
    }
}

- (IBAction)endSheet:(id)sender
{
    NSInteger tag = [sender tag];
    NSInteger result = (NSInteger)(tag != 98);
    NSPanel *presetsPanel = [self presetsPanel];
    
    if (result)
    {
        NSString *currentPresetPath = [self currentPresetPath];
    
	    //Make sure the text fields are saved when ending the edit sheet
	    [presetsPanel endEditingFor:nil];
    
	    NSDictionary *newDictionary = [self presetDictionary];
	    NSString *fileName = [newDictionary objectForKey:@"Name"];
	    
	    fileName = [fileName stringByReplacingOccurrencesOfString:@"/" withString:@":"];
    
	    if (!currentPresetPath)
	    {
    	    NSString *folder = [[MCInstallPanel installPanel] runModalForInstallLocation];
    	    folder = [folder stringByAppendingPathComponent:@"Media Converter"];
    	    folder = [folder stringByAppendingPathComponent:@"Presets"];
    	    NSString *path = [folder stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mcpreset", fileName]];
	    
    	    currentPresetPath = [MCCommonMethods uniquePathNameFromPath:path withSeperator:@" "];
	    }
    
	    //Save the (new) dictionary
	    [newDictionary writeToFile:currentPresetPath atomically:YES];
    
	    NSString *oldFileName = [[currentPresetPath lastPathComponent] stringByDeletingPathExtension];

	    if (![fileName isEqualTo:oldFileName])
	    {
    	    NSString *newPresetPath = [[[currentPresetPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:@"mcpreset"];
    	    newPresetPath = [MCCommonMethods uniquePathNameFromPath:newPresetPath withSeperator:@" "];

    	    [MCCommonMethods moveItemAtPath:currentPresetPath toPath:newPresetPath error:nil];
	    
    	    NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
    	    NSMutableArray *newPresets = [NSMutableArray arrayWithArray:[standardDefaults objectForKey:@"MCPresets"]];
    	    [newPresets replaceObjectAtIndex:[newPresets indexOfObject:currentPresetPath] withObject:newPresetPath];
    	    [standardDefaults setObject:newPresets forKey:@"MCPresets"];
	    }
    }

    [NSApp endSheet:presetsPanel returnCode:result];
    [presetsPanel orderOut:self];
    
    [self setCurrentPresetPath:nil];
    [self setExtraOptions:nil];
}

// Video
#pragma mark -
#pragma mark •• - Video

- (IBAction)setAspect:(id)sender
{
    NSMutableArray *advancedOptions = [[self optionDelegate] options];

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
    [[self advancedTableView] reloadData];
}

// Audio
#pragma mark -
#pragma mark •• - Audio

- (IBAction)setMode:(id)sender
{
    NSString *settings = nil;

    if ([sender indexOfSelectedItem] < 2)
    {
        settings = [NSString stringWithFormat:@"%li", [sender indexOfSelectedItem] + 1];
    }

    NSMutableArray *advancedOptions = [[self optionDelegate] options];
    [advancedOptions setObject:settings forKey:@"-ac"];
    [[self advancedTableView] reloadData];
}

// Subtitles
#pragma mark -
#pragma mark •• - Subtitles

- (IBAction)setSubtitleKind:(id)sender
{
    NSMutableDictionary *extraOptions = [self extraOptions];
    if (sender)
    {
	    [extraOptions setObject:[sender objectValue] forKey:@"Subtitle Type"];
    }
    
    NSString *settings = [extraOptions objectForKey:@"Subtitle Type"];

    if (settings == nil)
	    settings = @"";
    
    BOOL isDVD = ([settings isEqualTo:@"dvd"]);
    BOOL isHardcoded = ([settings isEqualTo:@"hard"]);
    
    NSView *subtitleSettingsView = [self subtitleSettingsView];
    NSView *DVDSettingsView = [self DVDSettingsView];
    NSView *hardcodedSettingsView = [self hardcodedSettingsView];
    
    NSArray *subviews = [subtitleSettingsView subviews];
    
    if ([subviews containsObject:DVDSettingsView])
	    [DVDSettingsView removeFromSuperview];
    else if ([subviews containsObject:hardcodedSettingsView])
	    [hardcodedSettingsView removeFromSuperview];
    
    if (isDVD | isHardcoded)
    {
	    NSView *subview;
	    if (isDVD)
    	    subview = DVDSettingsView;
	    else
    	    subview = hardcodedSettingsView;

	    [subview setFrame:NSMakeRect(0, [subtitleSettingsView frame].size.height - [subview frame].size.height, [subview frame].size.width, [subview frame].size.height)];
	    [subtitleSettingsView addSubview:subview];
	    
	    [[self window] recalculateKeyViewLoop];
    }
}

// Subtitles
#pragma mark -
#pragma mark ••  -> Hardcoded

- (IBAction)setHarcodedVisibility:(id)sender
{
    NSPopUpButton *hardcodedVisiblePopup = [self hardcodedVisiblePopup];
    NSInteger selectedIndex = [hardcodedVisiblePopup indexOfSelectedItem];
    
    //Seems when editing a preset from the main window, we have to try until we're woken from the NIB
    while (selectedIndex == -1)
	    selectedIndex = [hardcodedVisiblePopup indexOfSelectedItem];
    
    NSTabView *hardcodedMethodTabView = [self hardcodedMethodTabView];
    if (selectedIndex < 2)
	    [hardcodedMethodTabView selectTabViewItemAtIndex:selectedIndex];
	    
    [hardcodedMethodTabView setHidden:(selectedIndex == 2)];

    if (sender != nil)
	    [self setExtraOption:sender];
}

/////////////////////
// Preview actions //
/////////////////////

#pragma mark -
#pragma mark •• Preview actions

- (void)updatePreview
{
    NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithObjects:[self extraOptionDefaultValues] forKeys:[self extraOptionMappings]];
    [settings addEntriesFromDictionary:[self extraOptions]];
    
    NSString *backgroundName = @"Sintel-frame";
    if ([self darkBackground] == YES)
	    backgroundName = @"Sintel-frame-dark";
    
    NSImageView *previewImageView = [self previewImageView];
    
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:backgroundName ofType:@"jpg"];
    NSData *imageData = [[NSData alloc] initWithContentsOfFile:imagePath];
    CGDataProviderRef imgDataProvider = CGDataProviderCreateWithCFData((CFDataRef)imageData);
    CGImageRef backgroundImage = CGImageCreateWithJPEGDataProvider(imgDataProvider, NULL, true, kCGRenderingIntentDefault);
    
    CGImageRef previewImage = [self previewBackgroundWithImage:backgroundImage forSize:[previewImageView frame].size];
    CGImageRelease(backgroundImage);
    
    size_t imageWidth = CGImageGetWidth(previewImage);
    size_t imageHeight = CGImageGetHeight(previewImage);
    NSSize imageSize = NSMakeSize(imageWidth, imageHeight);
    CGImageRef filterImage = [[self filterDelegate] previewImageWithSize:imageSize];
    
    CGContextRef bitmapContext = CGBitmapContextCreate(NULL, imageSize.width, imageSize.height, 8, imageSize.width * 4, CGColorSpaceCreateDeviceRGB(), (CGBitmapInfo)kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    
    CGContextDrawImage(bitmapContext, CGRectMake(0.0, 0.0, imageWidth, imageHeight), previewImage);
    CGImageRelease(previewImage);
    CGContextDrawImage(bitmapContext, CGRectMake(0.0, 0.0, imageWidth, imageHeight), filterImage);
    CGImageRelease(filterImage);
    
    if ([[settings objectForKey:@"Subtitle Type"] isEqualTo:@"hard"])
    {
        CGImageRef subtitleImage = [MCCommonMethods overlayImageWithObject:NSLocalizedString(@"This is a scene from the movie Sintel watch it at: www.sintel.org<br><i>second line in italic</i>", nil) withSettings:settings size:imageSize];
        CGContextDrawImage(bitmapContext, CGRectMake(0.0, 0.0, imageWidth, imageHeight), subtitleImage);
        CGImageRelease(subtitleImage);
    }
    
    CGImageRef finalImageRef = CGBitmapContextCreateImage(bitmapContext);
    NSImage *finalImage = [[NSImage alloc] initWithCGImage:finalImageRef size:imageSize];
    CGImageRelease(finalImageRef);
    CGContextRelease(bitmapContext);
    
    [previewImageView setImage:finalImage];
    [previewImageView display];
}

- (IBAction)showPreview:(id)sender
{
    NSPanel *previewPanel = [self previewPanel];
    if ([previewPanel isVisible])
	    [previewPanel orderOut:nil];
    else
	    [previewPanel orderFront:nil];
}

- (void)reloadHardcodedPreview
{
    NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithObjects:[self extraOptionDefaultValues] forKeys:[self extraOptionMappings]];
    [settings addEntriesFromDictionary:[self extraOptions]];
    
//    NSImageView *previewImageView = [self previewImageView];
//    NSImage *previewImage = [MCCommonMethods overlayImageWithObject:NSLocalizedString(@"This is a scene from the movie Sintel watch it at: www.sintel.org<br><i>second line in italic</i>", nil) withSettings:settings inputImage:[NSImage imageNamed:@"Sintel-frame"]];
//    [previewImageView setImage:previewImage];
//    [previewImageView display];
}

- (IBAction)toggleDarkBackground:(id)sender
{
    [self setDarkBackground:![self darkBackground]];
    [self updatePreview];
}

- (CGImageRef)previewBackgroundWithImage:(CGImageRef)image forSize:(NSSize)size
{
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    NSSize imageSize = NSMakeSize(width, height);
    CGFloat imageAspect = imageSize.width / imageSize.height;
    CGFloat outputAspect = size.width / size.height;
    CGContextRef bitmapContext = CGBitmapContextCreate(NULL, size.width, size.height, 8, size.width * 4, CGColorSpaceCreateDeviceRGB(), (CGBitmapInfo)kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    
    CGContextSetFillColorWithColor(bitmapContext, CGColorCreateGenericRGB(1.0, 0.0, 0.0, 1.0));
    CGContextFillRect(bitmapContext, CGRectMake(0.0, 0.0, size.width, size.height));
    
    // Height is smaller
    if (outputAspect > imageAspect)
    {
	    CGFloat y = ((size.width / imageAspect) - size.height) / 2;
        CGContextDrawImage(bitmapContext, NSMakeRect(0, 0 - y, size.width, size.height + y), image);
    }
    else
    {
	    CGFloat x = ((size.height * imageAspect) - size.width) / 2;
        CGContextDrawImage(bitmapContext, NSMakeRect(0 - x, 0, size.width + x, size.height), image);
    }
    
    return CGBitmapContextCreateImage(bitmapContext);
}

///////////////////
// Other actions //
///////////////////

#pragma mark -
#pragma mark •• Other actions

- (BOOL)updateForKey:(NSString *)key withProperty:(id)property
{
    NSArray *viewMappings = [self viewMappings];
    if ([viewMappings containsObject:key])
    {
	    NSInteger tag = [viewMappings indexOfObject:key] + 1;
	    
        NSPanel *presetsPanel = [self presetsPanel];
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
    	    [MCCommonMethods setProperty:property forControl:control];
    	    
            id cell = [control cell];
            if ([cell isKindOfClass:[MCTextCheckBoxCell class]])
            {
                [MCCommonMethods setProperty:property forControl:[(MCTextCheckBoxCell *)cell textField]];
            }
	    	    
	    }
	    
	    return YES;
    }
    
    return NO;
}

- (void)setupPopups
{
    MCConverter *converter = [[MCConverter alloc] init];
    [[self containerPopUp] setArray:[converter getFormats]];
    
    NSArray *videoCodecs = [NSArray arrayWithArray:[converter getCodecsOfType:@"V"]];
    NSMutableArray *audioCodecs = [NSMutableArray arrayWithArray:[converter getCodecsOfType:@"A"]];
    NSArray *codecsNames = [NSArray arrayWithObjects:NSLocalizedString(@"Disable", nil), NSLocalizedString(@"Passthrough", nil), @"", nil];
    NSArray *codecsFormats = [NSArray arrayWithObjects:@"none", @"copy", @"", nil];
    
    NSMutableArray *videoPopupItems = [MCCommonMethods popupArrayWithNames:codecsNames forFormats:codecsFormats];
    NSMutableArray *audioPopupItems = [NSMutableArray arrayWithArray:videoPopupItems];
    
    [videoPopupItems addObjectsFromArray:videoCodecs];
    [audioPopupItems addObjectsFromArray:audioCodecs];
    
    [[self videoFormatPopUp] setArray:videoPopupItems];
    [[self audioFormatPopUp] setArray:audioPopupItems];
    
    NSArray *subtitleNames = [NSArray arrayWithObjects:	    NSLocalizedString(@"Disable", nil),
                                                            @"",
                                                            NSLocalizedString(@"Hardcoded", nil),
                                                            NSLocalizedString(@"DVD MPEG2", nil),
                                                            NSLocalizedString(@"MPEG4 / 3GP", nil),
                                                            NSLocalizedString(@"Matroska (SRT)", nil),
                                                            NSLocalizedString(@"Ogg (Kate)", nil),
                                                            NSLocalizedString(@"SRT (External)", nil),
    nil];
    
    NSArray *subtitleFormats = [NSArray arrayWithObjects:    @"none",
                                                            @"",
                                                            @"hard",
                                                            @"dvd",
                                                            @"mp4",
                                                            @"mkv",
                                                            @"kate",
                                                            @"srt",
    nil];
    
    [[self subtitleFormatPopUp] setArray:[MCCommonMethods popupArrayWithNames:subtitleNames forFormats:subtitleFormats]];
    
    NSArray *horizontalAlignments = [MCCommonMethods defaultHorizontalPopupArray];
    [[self hAlignFormatPopUp] setArray:horizontalAlignments];
    [[self hardcodedHAlignPopup] setArray:horizontalAlignments];
    
    NSArray *verticalAlignments = [MCCommonMethods defaultVerticalPopupArray];
    [[self vAlignFormatPopUp] setArray:verticalAlignments];
    [[self hardcodedVAlignPopup] setArray:verticalAlignments];
    
    NSArray *textVisibleNames = [NSArray arrayWithObjects:NSLocalizedString(@"Text Border", nil), NSLocalizedString(@"Surounding Box", nil), NSLocalizedString(@"None", nil), nil];
    NSArray *textVisibleFormats = [NSArray arrayWithObjects:@"border", @"box", @"none", nil];
    [[self hardcodedVisiblePopup] setArray:[MCCommonMethods popupArrayWithNames:textVisibleNames forFormats:textVisibleFormats]];
    
    MCPopupButton *hardcodedFontPopup = [self hardcodedFontPopup];
    [hardcodedFontPopup removeAllItems];
    [hardcodedFontPopup addItemWithTitle:NSLocalizedString(@"Loading…", nil)];
    [hardcodedFontPopup setEnabled:NO];
    [hardcodedFontPopup setDelayed:YES];
    
    MCPopupButton *fontPopup = [self fontPopup];
    [fontPopup removeAllItems];
    [fontPopup addItemWithTitle:NSLocalizedString(@"Loading…", nil)];
    [fontPopup setEnabled:NO];
    [fontPopup setDelayed:YES];
    
    converter = nil;
    
    [self setupSlowPopups];
}

- (void)setupSlowPopups
{
    MCPopupButton *hardcodedFontPopup = [self hardcodedFontPopup];
    [hardcodedFontPopup removeAllItems];
    
    [[[NSOperationQueue alloc] init] addOperationWithBlock:^
    {
        NSArray *fontFamilies = [[NSFontManager sharedFontManager] availableFontFamilies];
        NSMutableArray *hardcodedFontDictionaries = [NSMutableArray array];
        
        NSInteger i;
        for (i = 0; i < [fontFamilies count]; i ++)
        {
            NSString *fontName = [fontFamilies objectAtIndex:i];
            NSFont *newFont = [NSFont fontWithName:fontName size:12.0];
            
            if (newFont)
            {
                    NSAttributedString *titleString;
                    NSMutableDictionary *titleAttr = [NSMutableDictionary dictionary];
                    [titleAttr setObject:newFont forKey:NSFontAttributeName];
                    titleString = [[NSAttributedString alloc] initWithString:[newFont displayName] attributes:titleAttr];

                    [hardcodedFontDictionaries addObject:[NSDictionary dictionaryWithObjectsAndKeys:titleString, @"Name", fontName, @"Format", nil]];
                
                    titleString = nil;
            }
            else
            {
                    [hardcodedFontDictionaries addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:NSLocalizedString(@"%@ (no preview)", nil), fontName], @"Name", fontName, @"Format", nil]];
            }
        }

        [[NSOperationQueue mainQueue] addOperationWithBlock:^
        {
            MCPopupButton *hardcodedFontPopup = [self hardcodedFontPopup];
            [hardcodedFontPopup setArray:hardcodedFontDictionaries];
            [hardcodedFontPopup setDelayed:NO];
            [hardcodedFontPopup setEnabled:YES];
        }];
    }];
    
    MCPopupButton *fontPopup = [self fontPopup];
    [fontPopup removeAllItems];
    
    [[[NSOperationQueue alloc] init] addOperationWithBlock:^
    {
        NSFileManager *defaultManager =     [NSFileManager defaultManager];
        NSString *fontPath = [[NSUserDefaults standardUserDefaults] objectForKey:@"MCFontFolderPath"];
        
        NSMutableArray *fontDictionaries = [NSMutableArray array];
        NSArray *fonts = [defaultManager subpathsAtPath:fontPath];

        NSInteger y;
        for (y = 0; y < [fonts count]; y ++)
        {
            NSString *font = [fonts objectAtIndex:y];
            
            if ([[font pathExtension] isEqualTo:@"ttf"])
            {
                    NSString *fontName = [font stringByDeletingPathExtension];
                    NSFont *newFont = [NSFont fontWithName:fontName size:12.0];
                
                    if (newFont)
                    {
                    NSAttributedString *titleString;
                    NSMutableDictionary *titleAttr = [NSMutableDictionary dictionary];
                    [titleAttr setObject:newFont forKey:NSFontAttributeName];
                    titleString = [[NSAttributedString alloc] initWithString:[newFont displayName] attributes:titleAttr];

                    [fontDictionaries addObject:[NSDictionary dictionaryWithObjectsAndKeys:titleString, @"Name", fontName, @"Format", nil]];
                    
                    titleString = nil;
                    }
                    else
                    {
                    [fontDictionaries addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:NSLocalizedString(@"%@ (no preview)", nil), fontName], @"Name", fontName, @"Format", nil]];
                    }
            }
        }

        [[NSOperationQueue mainQueue] addOperationWithBlock:^
        {
            MCPopupButton *fontPopup = [self fontPopup];
            [fontPopup setArray:fontDictionaries];
            [fontPopup setDelayed:NO];
            [fontPopup setEnabled:YES];
        }];
    }];
}

- (NSDictionary *)defaults
{
    return [NSDictionary dictionaryWithObjects:[self extraOptionDefaultValues] forKeys:[self extraOptionMappings]];
}

@end
