//
//  MCMainController.m
//  Media Converter
//
//  Created by Maarten Foukhar on 22-01-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import "MCMainController.h"
#import "NSArray_Extensions.h"
#import "MCAlert.h"
#import "MCActionButton.h"
#import "MCCommonMethods.h"
#import "MCProgressPanel.h"
#import "MCConverter.h"
#import "MCPreferences.h"
#import "MCPresetEditPanel.h"
#import "MCTableView.h"
#import "MCDropView.h"
#import "MCPresetHelper.h"
#import <LetsMove/LetsMove.h>

@interface MCMainController() <NSFileManagerDelegate, NSApplicationDelegate, MCPreferencesDelegate, MCTableViewDelegate, MCDropViewDelegate, NSUserNotificationCenterDelegate>

// Outlets
@property (nonatomic, weak) IBOutlet NSWindow *mainWindow;
@property (nonatomic, weak) IBOutlet MCDropView *dropView;
@property (nonatomic, weak) IBOutlet NSPopUpButton *presetPopUp;
@property (nonatomic, weak) IBOutlet NSPanel *locationsPanel;
@property (nonatomic, strong) IBOutlet NSTextView *locationsTextField;
@property (nonatomic, weak) IBOutlet MCActionButton *actionButton;

// Custom objects
@property (nonatomic, strong) MCConverter *converter;
@property (nonatomic, strong) MCPreferences *preferences;

// Other variables
@property (nonatomic, strong) NSArray *inputFiles;
@property (nonatomic) BOOL cancelAddingFiles;

@end

@implementation MCMainController

+ (void)initialize
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] localizedInfoDictionary];

    //Setup some defaults for the preferences (used when options aren't set)
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *appDefaults =  @{ @"MCInstallMode": @(0),
                                    @"MCSaveMethod": @(0),
                                    @"MCSaveLocation": [@"~/Movies" stringByExpandingTildeInPath],
                                    @"MCDebug": @(NO),
                                    @"MCUseCustomFFMPEG": @(NO),
                                    @"MCCustomFFMPEG": @"",
                                    @"MCSavedPrefView": @"General",
                                    @"MCSelectedPreset": @(0),
                                    @"MCDVDForceAspect": @(0),
                                    @"MCMuxSeperateStreams": @(NO),
                                    @"MCRemuxMPEG2Streams": @(NO),
                                    @"MCSubtitleLanguage": infoDictionary[@"MCSubtitleLanguage"],
                                    @"MCQuitAfterConvertion": @(NO),
                                 };
    
    [defaults registerDefaults:appDefaults];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
    // Add the old identifier preferences, we had to change it, since underscore isn't allowed anymore
    [standardDefaults addSuiteNamed:@"com.kiwifruitware.Media_Converter"];

    //Setup action button
    MCActionButton *actionButton = [self actionButton];
    [actionButton setMenuTarget:self];
    [actionButton addMenuItemWithTitle:NSLocalizedString(@"Edit Preset…", nil) withSelector:@selector(edit:)];
    [actionButton addMenuItemWithTitle:NSLocalizedString(@"Export Preset…", nil) withSelector:@selector(saveDocumentAs:)];
    [actionButton addSeparatorItem];
    [actionButton addMenuItemWithTitle:NSLocalizedString(@"Create Preset…", nil) withSelector:@selector(create:)];
    
    //Placeholder error string
    NSString *error = NSLocalizedString(@"An unknown error occured", nil);
    
    //Quit the application when the main window is closed (seems to be accepted in Mac OS X)
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeWindow) name:NSWindowWillCloseNotification object:[self mainWindow]];
    
    //Setup Preset popup in the main window
    NSPopUpButton *presetPopUp = [self presetPopUp];
    [presetPopUp removeAllItems];
    
    // Make sure the preset list format is right, it used to be a list of dictionaries, now they're paths
    NSArray *presets = [standardDefaults objectForKey:@"MCPresets"];
    NSMutableArray *updatedPresets = [[NSMutableArray alloc] init];
    for (id presetObject in presets)
    {
        if ([presetObject isKindOfClass:[NSDictionary class]])
        {
            NSString *path = presetObject[@"Path"];
            if (path != nil)
            {
                [updatedPresets addObject:path];
            }
        }
        else
        {
            [updatedPresets addObject:presetObject];
        }
    }
    [standardDefaults setObject:updatedPresets forKey:@"MCPresets"];
    
    // First check if there are still themes installed in /Library/Application Support/ by previous versions and move those presets
    NSFileManager *defaultManager =  [NSFileManager defaultManager];
    NSString *applicationSupportFolder = @"/Library/Application Support/Media Converter";
    NSString *folder = [applicationSupportFolder stringByAppendingPathComponent:@"Presets"];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *applicationSupportDirectory = [paths firstObject];
    NSString *userSupportFolder = [applicationSupportDirectory stringByAppendingPathComponent:@"Media Converter"];
    NSString *userPresetsFolder = [userSupportFolder stringByAppendingPathComponent:@"Presets"];
    BOOL supportIsWritable = [defaultManager isWritableFileAtPath:folder];
    
    if (supportIsWritable && [defaultManager fileExistsAtPath:folder])
    {
        NSString *fontPath = [applicationSupportFolder stringByAppendingPathComponent:@"Fonts"];
        NSString *newFontPath = [userSupportFolder stringByAppendingPathComponent:@"Fonts"];
        if (![defaultManager fileExistsAtPath:newFontPath])
        {
            NSError *error;
            [defaultManager moveItemAtPath:fontPath toPath:newFontPath error:nil];
            if (error != nil)
            {
                NSLog(@"Error: %@", error);
            }
        }
    
        NSMutableArray *checkedPresets = [updatedPresets mutableCopy];
        for (NSString *presetPath in updatedPresets)
        {
            if ([presetPath rangeOfString:folder].length > 0)
            {
                if ([defaultManager fileExistsAtPath:presetPath])
                {
                    NSError *error;
                    if (![defaultManager fileExistsAtPath:userPresetsFolder])
                    {
                        [defaultManager createDirectoryAtPath:userPresetsFolder withIntermediateDirectories:YES attributes:@{} error:&error];
                        if (error != nil)
                        {
                            NSLog(@"Error: %@", error);
                        }
                    }
                    
                    NSString *fileName = [presetPath lastPathComponent];
                    NSString *newPath = [userPresetsFolder stringByAppendingPathComponent:fileName];
                    if ([defaultManager fileExistsAtPath:newPath])
                    {
                        newPath = [MCCommonMethods uniquePathNameFromPath:newPath withSeperator:@" "];
                    }
                    [defaultManager moveItemAtPath:presetPath toPath:newPath error:&error];
                    if (error != nil)
                    {
                        NSLog(@"Error: %@", error);
                    }
                    [checkedPresets replaceObjectAtIndex:[checkedPresets indexOfObject:presetPath] withObject:newPath];
                }
                else
                {
                    [checkedPresets removeObjectAtIndex:[checkedPresets indexOfObject:presetPath]];
                }
            }
        }
        [standardDefaults setObject:checkedPresets forKey:@"MCPresets"];
        [defaultManager removeItemAtPath:applicationSupportFolder error:nil];
    }
    
    NSString *userFolder = [userSupportFolder stringByAppendingPathComponent:@"Presets"];
    BOOL hasSupportFolder = [defaultManager fileExistsAtPath:userFolder];
    
    //Popupulate preset folder after creating it
    if (!hasSupportFolder || [updatedPresets count] == 0)
    {
	    if (!hasSupportFolder)
	    {
            NSString *presetsFolder = [[NSBundle mainBundle] pathForResource:@"Presets" ofType:@""];
    	    BOOL supportWritable = YES;

            if (![defaultManager fileExistsAtPath:userSupportFolder])
            {
                supportWritable = [MCCommonMethods createDirectoryAtPath:userSupportFolder errorString:&error];
            }
            
            if (supportWritable)
            {
                supportWritable = [MCCommonMethods copyItemAtPath:presetsFolder toPath:userFolder errorString:&error];
            }
    	    
    	    if (!supportWritable)
    	    {
	    	    [MCCommonMethods standardAlertWithMessageText:NSLocalizedString(@"Failed to copy 'Presets' folder", nil) withInformationText:error withParentWindow:nil withDetails:nil];
	    	    
	    	    [presetPopUp setEnabled:NO];
	    	    [presetPopUp addItemWithTitle:NSLocalizedString(@"No Presets", nil)];
	    	    
	    	    return;
    	    }
	    }
	    
	    NSArray *presetPaths = [MCCommonMethods getFullPathsForFolders:@[userFolder] withType:@"mcpreset"];
	    NSMutableArray *savedPresets = [NSMutableArray array];
	    
	    NSInteger i;
	    for (i = 0; i < [presetPaths count]; i ++)
	    {
    	    NSString *path = [presetPaths objectAtIndex:i];
    	    [savedPresets addObject:path];
	    }

	    [standardDefaults setObject:savedPresets forKey:@"MCPresets"];
    }
    
    //Now really update preset popup
    [self updatePresets];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];

    [[NSOperationQueue mainQueue] addOperationWithBlock:^
    {
        [self versionUpdateCheckWithCompletion:^
        {
            PFMoveToApplicationsFolderIfNecessary();
        }];
    }];
}

//Files dropped on the application icon, opened with... or other external open methods
//Check for preset files, the other files are checked if they can be convertered
- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
    NSMutableArray *presetFiles = [NSMutableArray array];
    NSMutableArray *otherFiles = [NSMutableArray array];
    
    NSInteger i;
    for (i = 0; i < [filenames count]; i ++)
    {
	    NSString *file = [filenames objectAtIndex:i];
	    NSString *extension = [file pathExtension];
	    
	    if ([[extension lowercaseString] isEqualTo:@"mcpreset"])
    	    [presetFiles addObject:file];
	    else
    	    [otherFiles addObject:file];
    }
    
    if ([presetFiles count] > 0)
    {
	    NSInteger result = [[MCPresetHelper sharedHelper] openPresetFiles:filenames];
	    
	    if (result != 0)
	    {
    	    [self updatePresets];
        }
    }
    
    if ([otherFiles count] > 0)
    {
	    [self checkFiles:otherFiles];
    }
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

#pragma mark - Update Methods

//Some things changed in newer versions, check if we need to update things
- (void)versionUpdateCheckWithCompletion:(void (^)(void))completion
{
    NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
    
    CGFloat lastCheck = [[standardDefaults objectForKey:@"MCLastCheck"] doubleValue];
    NSInteger returnCode;
    
    if (lastCheck < 1.2)
    {
        // Check for old presets
        NSArray *presets = [standardDefaults objectForKey:@"MCPresets"];
        BOOL hasOldPresets = NO;
        for (NSString *path in presets)
        {
            NSDictionary *preset = [NSMutableDictionary dictionaryWithContentsOfFile:path];
            if ([preset[@"Version"] doubleValue] < 1.2)
            {
                hasOldPresets = YES;
            }
        }
        
        if (hasOldPresets)
        {
            //Ask if the user wants to update the presets for using subtitles
            NSAlert *upgradeAlert = [[NSAlert alloc] init];
            [upgradeAlert addButtonWithTitle:NSLocalizedString(@"Update", nil)];
            [upgradeAlert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
            [[[upgradeAlert buttons] objectAtIndex:1] setKeyEquivalent:@"\E"];
            [upgradeAlert setMessageText:NSLocalizedString(@"This release of 'Media Converter' adds subtitle support", nil)];
            [upgradeAlert setInformativeText:NSLocalizedString(@"Would you like to update the presets to support it?", nil)];
            
            returnCode = [upgradeAlert runModal];
            
            //Update presets when the user chose "Update"
            if (returnCode == NSAlertFirstButtonReturn)
            {
                NSArray *presets = [standardDefaults objectForKey:@"MCPresets"];
                for (NSString *path in presets)
                {
                    NSMutableDictionary *preset = [NSMutableDictionary dictionaryWithContentsOfFile:path];
                    [preset setObject:@(1.2) forKey:@"Version"];

                    NSArray *encoderOptions = [preset objectForKey:@"Encoder Options"];
                    NSMutableDictionary *extraOptions = [preset objectForKey:@"Extra Options"];
                
                    if ([encoderOptions indexOfObject:@"matroska" forKey:@"-f"] != NSNotFound)
                        [extraOptions setObject:@"mkv" forKey:@"Subtitle Type"];
                    
                    if ([encoderOptions indexOfObject:@"ogg" forKey:@"-f"] != NSNotFound)
                        [extraOptions setObject:@"kate" forKey:@"Subtitle Type"];
                    
                    if ([encoderOptions indexOfObject:@"ogv" forKey:@"-f"] != NSNotFound)
                        [extraOptions setObject:@"kate" forKey:@"Subtitle Type"];
                    
                    if ([encoderOptions indexOfObject:@"ipod" forKey:@"-f"] != NSNotFound)
                        [extraOptions setObject:@"mp4" forKey:@"Subtitle Type"];
                    
                    if ([encoderOptions indexOfObject:@"mp4" forKey:@"-f"] != NSNotFound)
                        [extraOptions setObject:@"mp4" forKey:@"Subtitle Type"];
                    
                    if ([encoderOptions indexOfObject:@"3gp" forKey:@"-f"] != NSNotFound)
                        [extraOptions setObject:@"mp4" forKey:@"Subtitle Type"];
                    
                    if ([encoderOptions indexOfObject:@"3g2" forKey:@"-f"] != NSNotFound)
                        [extraOptions setObject:@"mp4" forKey:@"Subtitle Type"];
                    
                    if ([encoderOptions indexOfObject:@"avi" forKey:@"-f"] != NSNotFound)
                        [extraOptions setObject:@"srt" forKey:@"Subtitle Type"];
                    
                    if ([encoderOptions indexOfObject:@"dvd" forKey:@"-f"] != NSNotFound)
                        [extraOptions setObject:@"dvd" forKey:@"Subtitle Type"];
                    
                    [extraOptions setObject:@"Helvetica" forKey:@"Subtitle Font"];
                    [extraOptions setObject:@"24" forKey:@"Subtitle Font Size"];
                    [extraOptions setObject:@"center" forKey:@"Subtitle Horizontal Alignment"];
                    [extraOptions setObject:@"bottom" forKey:@"Subtitle Vertical Alignment"];
                    [extraOptions setObject:@"60" forKey:@"Subtitle Left Margin"];
                    [extraOptions setObject:@"60" forKey:@"Subtitle Right Margin"];
                    [extraOptions setObject:@"20" forKey:@"Subtitle Top Margin"];
                    [extraOptions setObject:@"30" forKey:@"Subtitle Bottom Margin"];
                    
                    [preset setObject:extraOptions forKey:@"Extra Options"];
                    [preset writeToFile:path atomically:YES];
                    [MCCommonMethods writeDictionary:preset toFile:path errorString:nil];
                }
            }
         
            [MCMainController updateFontListForWindow:[self mainWindow] withCompletion:completion];
        }
        else
        {
            NSString *userSupportFolder = [@"~/Library/Application Support/Media Converter" stringByExpandingTildeInPath];
            NSString *fontPath = [userSupportFolder stringByAppendingPathComponent:@"Fonts"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:fontPath])
            {
                if (completion != nil)
                {
                    completion();
                }
            }
            else
            {
                [MCMainController updateFontListForWindow:[self mainWindow] withCompletion:completion];
            }
        }
    }
    else
    {
        NSString *userSupportFolder = [@"~/Library/Application Support/Media Converter" stringByExpandingTildeInPath];
        NSString *fontPath = [userSupportFolder stringByAppendingPathComponent:@"Fonts"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:fontPath])
        {
            if (completion != nil)
            {
                completion();
            }
        }
        else
        {
            [MCMainController updateFontListForWindow:[self mainWindow] withCompletion:completion];
        }
    }
    
    if (lastCheck < 2.0)
    {
        // Update presets to work with newer versions of FFmpeg (4.2 currently)
        NSArray *presets = [[NSUserDefaults standardUserDefaults] objectForKey:@"MCPresets"];
        for (NSString *path in presets)
        {
            [[MCPresetHelper sharedHelper] updatePresetAtPath:path];
        }
        
        //Update "MCLastCheck" so we'll won't check again
        [standardDefaults setObject:@(2.0) forKey:@"MCLastCheck"];
    }
}

//When the application starts or when a change has been made related to the presets update the preset menu
//in the main window
- (void)updatePresets
{
    NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
    
    NSPopUpButton *presetPopUp = [self presetPopUp];
    NSString *currentTitle = [presetPopUp titleOfSelectedItem];

    [presetPopUp removeAllItems];
    
    NSArray *presets = [standardDefaults objectForKey:@"MCPresets"];

    BOOL hasPresets = ([presets count] > 0);
    [presetPopUp setEnabled:hasPresets];
    
    if (!hasPresets)
    {
	    [presetPopUp addItemWithTitle:NSLocalizedString(@"No Presets", nil)];
    }
    else
    {
	    NSInteger i;
	    for (i = 0; i < [presets count]; i ++)
	    {
    	    NSString *path = [presets objectAtIndex:i];
    	    
    	    if ([[NSFileManager defaultManager] fileExistsAtPath:path])
    	    {
	    	    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:path];
	    	    NSString *name = [dictionary objectForKey:@"Name"];
    	    
	    	    [presetPopUp addItemWithTitle:name];
    	    }
	    }
    
	    if (currentTitle && [presetPopUp itemWithTitle:currentTitle])
	    {
    	    [presetPopUp selectItemWithTitle:currentTitle];
    	    NSNumber *selectIndex = [NSNumber numberWithInteger:[presetPopUp indexOfItemWithTitle:currentTitle]];
    	    [standardDefaults setObject:selectIndex forKey:@"MCSelectedPreset"];
	    }
	    else
	    {
    	    NSInteger saveIndex = [[standardDefaults objectForKey:@"MCSelectedPreset"] integerValue];
	    
    	    while (saveIndex >= [presets count])
    	    {
	    	    saveIndex = saveIndex - 1;
    	    }
	    
    	    [presetPopUp selectItemAtIndex:saveIndex];
	    }
    }
}

///////////////////////
// Interface actions //
///////////////////////

#pragma mark -
#pragma mark •• Interface actions

//Save the current preset to the preferences
- (IBAction)selectPreset:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:[sender objectValue] forKey:@"MCSelectedPreset"];
}

//Edit the preset
- (IBAction)edit:(id)sender
{
    NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
    NSArray *presets = [standardDefaults objectForKey:@"MCPresets"];
    NSString *path = [presets objectAtIndex:[[standardDefaults objectForKey:@"MCSelectedPreset"] integerValue]];
    
    MCPresetEditPanel *presetManager = [MCPresetEditPanel editPanel];
    [presetManager beginModalForWindow:[self mainWindow] withPresetPath:path completionHandler:^(NSModalResponse returnCode)
    {
        if (returnCode == NSModalResponseOK)
        {
            [self updatePresets];
        }
    }];
}

//Save the preset
- (IBAction)saveDocumentAs:(id)sender
{    
    NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
    NSArray *presets = [standardDefaults objectForKey:@"MCPresets"];
    
    NSString *path = [presets objectAtIndex:[[standardDefaults objectForKey:@"MCSelectedPreset"] integerValue]];

    [[MCPresetEditPanel editPanel] savePresetForWindow:[self mainWindow] withPresetPath:path];
}

// Create a new preset
- (IBAction)create:(id)sender
{
    MCPresetEditPanel *presetManager = [MCPresetEditPanel editPanel];
    [presetManager beginModalForWindow:[self mainWindow] withPresetPath:nil completionHandler:^(NSModalResponse returnCode)
    {
        if (returnCode == NSModalResponseOK)
        {
            [self updatePresets];
            
            NSPopUpButton *presetPopUp = [self presetPopUp];
            NSInteger numberOfItems = [presetPopUp numberOfItems];
            if (numberOfItems > 0)
            {
                [presetPopUp selectItemAtIndex:numberOfItems - 1];
                [self selectPreset:presetPopUp];
            }
        }
    }];
}

//////////////////
// Menu actions //
//////////////////

#pragma mark -
#pragma mark •• Menu actions

//Manually open about panel (needed since using Retina images messes the about panel up)
- (IBAction)openAboutPanel:(id)sender
{
    NSDictionary *options;
    NSImage *iconImage = [NSImage imageNamed: @"Media Converter"];
    [iconImage setSize:NSMakeSize(64, 64)];
    options = [NSDictionary dictionaryWithObjectsAndKeys:iconImage, @"ApplicationIcon", nil];
    [[NSApplication sharedApplication] orderFrontStandardAboutPanelWithOptions:options];
}

//Open the preferences
- (IBAction)openPreferences:(id)sender
{
    [self setPreferences:nil];
    MCPreferences *preferences = [self preferences];
    if (preferences == nil)
    {
	    preferences = [[MCPreferences alloc] init];
	    [preferences setDelegate:self];
        [self setPreferences:preferences];
    }
    
    [preferences showPreferences];
}

//Open media files
- (IBAction)openFiles:(id)sender
{
    NSOpenPanel *sheet = [NSOpenPanel openPanel];
    [sheet setCanChooseFiles:YES];
    [sheet setCanChooseDirectories:YES];
    [sheet setAllowsMultipleSelection:YES];
    [sheet beginSheetModalForWindow:[self mainWindow] completionHandler:^(NSModalResponse result)
    {
        if (result == NSModalResponseOK)
        {
            NSMutableArray *filenames = [[NSMutableArray alloc] init];
            for (NSURL *url in [sheet URLs])
            {
                [filenames addObject:[url path]];
            }
        
            [self checkFiles:filenames];
        }
    }];
}

//Open internet URL files
- (IBAction)openURLs:(id)sender
{
    [[self mainWindow] beginSheet:[self locationsPanel] completionHandler:^(NSModalResponse returnCode)
    {
        NSTextView *locationsTextField = [self locationsTextField];

        if (returnCode == NSModalResponseOK)
        {
            NSString *fieldString = [[locationsTextField textStorage] string];
        
            [self checkFiles:[fieldString componentsSeparatedByString:@"\n"]];
        }
        
        [locationsTextField setString:@""];
    }];
}

//Stop locations panel with return code
- (IBAction)endOpenLocations:(id)sender
{
    NSWindow *locationsPanel = [self locationsPanel];
    [locationsPanel orderOut:nil];
    [[self mainWindow] endSheet:locationsPanel returnCode:[sender tag]];
}

//Visit the site
- (IBAction)goToSite:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://media-converter.sourceforge.io"]];
}

//Get the application or external applications source (links to a folder)
- (IBAction)downloadSource:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://sourceforge.net/projects/media-converter/files/media-converter/1.3/"]];
}

//Opens internal donation html page
- (IBAction)makeDonation:(id)sender
{
    [[NSWorkspace sharedWorkspace] openFile:[[[NSBundle mainBundle] pathForResource:@"Donation" ofType:@""] stringByAppendingPathComponent:@"donate.html"]];
}

- (IBAction)contactSupport:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:NSLocalizedString(@"menu-help-mail-link", nil)]];
}

//////////////////
// Main actions //
//////////////////

#pragma mark -
#pragma mark •• Main actions

//Start a thread to check our files
- (void)checkFiles:(NSArray *)inputFiles
{
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setCancelAdding) name:@"cancelAdding" object:nil];

    [self setCancelAddingFiles:NO];

    MCProgressPanel *progressPanel = [MCProgressPanel progressPanel];
    [progressPanel setTask:NSLocalizedString(@"Checking files...", nil)];
    [progressPanel setStatus:NSLocalizedString(@"Scanning for files and folders", nil)];
    [progressPanel setMaximumValue:0.0];
    [progressPanel setCancelButtonTitle:NSLocalizedString(@"progress-panel-cancel-button", nil)];
    [progressPanel setCancelHandler:^
    {
        [self setCancelAddingFiles:YES];
    }];
    [progressPanel beginSheetForWindow:[self mainWindow]];
    
    [[[NSOperationQueue alloc] init] addOperationWithBlock:^
    {
        MCConverter *convertObject = [[MCConverter alloc] init];
        
        NSFileManager *defaultManager = [NSFileManager defaultManager];
        NSMutableArray *files = [NSMutableArray array];
        NSInteger protectedCount = 0;
        
        NSInteger x = 0;
        for (x = 0; x < [inputFiles count]; x++)
        {
            if ([self cancelAddingFiles] == YES)
                break;
            
            NSDirectoryEnumerator *enumer;
            NSString* pathName;
            NSString *realPath = [self getRealPath:[inputFiles objectAtIndex:x]];
            BOOL fileIsFolder = NO;
            
            [defaultManager fileExistsAtPath:realPath isDirectory:&fileIsFolder];

            if (fileIsFolder)
            {
                enumer = [defaultManager enumeratorAtPath:realPath];
                while (pathName = [enumer nextObject])
                {
                    if ([self cancelAddingFiles] == YES)
                        break;
                    
                    NSString *realPathName = [self getRealPath:[realPath stringByAppendingPathComponent:pathName]];
                
                    if (![self isProtected:realPathName])
                    {
                        if ([convertObject isMediaFile:realPathName])
                            [files addObject:realPathName];
                    }
                    else
                    {
                        protectedCount = protectedCount + 1;
                    }
                }
            }
            else
            {
                if ([self cancelAddingFiles] == YES)
                    break;
                
                if (![self isProtected:realPath])
                {
                    if ([convertObject isMediaFile:realPath])
                        [files addObject:realPath];
                }
                else
                {
                    protectedCount = protectedCount + 1;
                }
            }
        }
        
        if ([files count] > 0)
        {
            [self setInputFiles:[files copy]];
        }
        
        [self setConverter:nil];
        [self setCancelAddingFiles:NO];

        //Stop being the observer
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"cancelAdding" object:nil];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^
        {
            if ([files count] > 0)
            {
                [self showAlert:@(protectedCount)];
            }
        }];
    }];
}

//Show an alert if needed (protected or no default files
- (void)showAlert:(NSNumber *)protectedFiles
{
    NSInteger incompatibleFiles = [protectedFiles integerValue];
    
    if (incompatibleFiles > 0)
    {
        [[MCProgressPanel progressPanel] endSheet];
    
        NSArray *inputFiles = [self inputFiles];
	    if ([inputFiles count] > 0)
	    {
    	    NSAlert *alert = [[NSAlert alloc] init];
    	    [alert addButtonWithTitle:NSLocalizedString(@"Continue", nil)];
    	    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    	    [[[alert buttons] objectAtIndex:1] setKeyEquivalent:@"\E"];
	    
    	    NSString *protectedString;
	    
    	    if (incompatibleFiles > 1)
    	    {
	    	    [alert setMessageText:NSLocalizedString(@"Some protected files", nil)];
	    	    protectedString = NSLocalizedString(@"These can't be converted, would you like to continue?", nil);
    	    }
    	    else
    	    {
	    	    [alert setMessageText:NSLocalizedString(@"One protected file", nil)];
	    	    protectedString = NSLocalizedString(@"This file can't be converted, would you like to continue?", nil);;
    	    }
	    
    	    [alert setInformativeText:protectedString];
    	    [alert beginSheetModalForWindow:[self mainWindow] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
	    }
	    else if ([inputFiles count] == 0)
	    {
    	    NSString *message;
    	    NSString *information;
    	    
    	    if (incompatibleFiles > 1)
    	    {
	    	    message = NSLocalizedString(@"Some protected mp4 files", nil);
	    	    information = NSLocalizedString(@"These files can't be converted", nil);
    	    }
    	    else
    	    {
	    	    message = NSLocalizedString(@"One protected mp4 file", nil);
	    	    information = NSLocalizedString(@"This file can't be converted", nil);
    	    }

    	    [MCCommonMethods standardAlertWithMessageText:message withInformationText:information withParentWindow:[self mainWindow] withDetails:nil];
	    }
    }
    else
    {
	    [self saveFiles];
    }
}

//Check preferences for desired save method
- (void)saveFiles
{
    NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
    
    NSInteger saveMethod = [[standardDefaults objectForKey:@"MCSaveMethod"] integerValue];
    if (saveMethod == 2)
    {
        MCProgressPanel *progressPanel = [MCProgressPanel progressPanel];
        [progressPanel endSheetWithCompletion:^
        {
            NSOpenPanel *sheet = [NSOpenPanel openPanel];
            [sheet setCanChooseFiles: NO];
            [sheet setCanChooseDirectories: YES];
            [sheet setAllowsMultipleSelection: NO];
            [sheet setCanCreateDirectories: YES];
            [sheet setPrompt:NSLocalizedString(@"Choose", nil)];
            [sheet setMessage:NSLocalizedString(@"Choose a location to save the converted files", nil)];
            [sheet beginSheetModalForWindow:[self mainWindow] completionHandler:^(NSModalResponse result)
            {
                if (result == NSModalResponseOK)
                {
                    [[MCProgressPanel progressPanel] beginSheetForWindow:[self mainWindow]];
                    [self convertFiles:[[sheet URL] path]];
                }
                else
                {
                    [self setInputFiles:nil];
                }
            }];
        }];
    }
    else
    {
        [self convertFiles:[standardDefaults objectForKey:@"MCSaveLocation"]];
    }
}

//Alert did end, whe don't need to do anything special, well releasing the alert we do, the user should
- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [[alert window] orderOut:self];
    
    if (returnCode == NSAlertFirstButtonReturn) 
	    [self saveFiles];
}

/////////////////////
// Convert actions //
/////////////////////

#pragma mark -
#pragma mark •• Convert actions

//Convert files to path
- (void)convertFiles:(NSString *)path
{
    MCProgressPanel *progressPanel = [MCProgressPanel progressPanel];
    [progressPanel setTask:NSLocalizedString(@"Preparing to encode", nil)];
    [progressPanel setStatus:NSLocalizedString(@"Checking file...", nil)];
    [progressPanel setMaximumValue:100 * [[self inputFiles] count]];
    [progressPanel setCancelButtonTitle:NSLocalizedString(@"converter-progress-panel-cancel-button", nil)];

    MCConverter *converter = [[MCConverter alloc] init];
    [self setConverter:converter];
    
    NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
    NSArray *presets = [standardDefaults objectForKey:@"MCPresets"];
    NSString *presetPath = [presets objectAtIndex:[[standardDefaults objectForKey:@"MCSelectedPreset"] integerValue]];
    NSDictionary *options = [NSDictionary dictionaryWithContentsOfFile:presetPath];
    
    [[[NSOperationQueue alloc] init] addOperationWithBlock:^
    {
        NSString *errorString = nil;
        NSArray *inputFiles = [self inputFiles];
        NSInteger result = [converter batchConvert:inputFiles toDestination:path withOptions:options errorString:&errorString];
        
        [progressPanel endSheetWithCompletion:^
        {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^
            {
                [self setConverter:nil];

                if (result == 0)
                {
                    NSString *finishMessage;
                
                    if ([inputFiles count] > 1)
                        finishMessage = [NSString stringWithFormat:NSLocalizedString(@"Finished converting %ld files", nil),(long)[inputFiles count]];
                    else
                        finishMessage = NSLocalizedString(@"Finished converting 1 file", nil);
                    
                    NSString *firstPath = inputFiles[0];
                    NSImage *image = [[NSWorkspace sharedWorkspace] iconForFile:firstPath];
                    [self showNotificationWithTitle:NSLocalizedString(@"Finished converting", nil) withMessage:finishMessage withImage:image];
                    
                    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"MCQuitAfterConvertion"])
                    {
                        [[NSApplication sharedApplication] terminate:nil];
                    }
                }
                else if (result == 1)
                {
                    [self performSelectorOnMainThread:@selector(showConvertFailAlert:) withObject:errorString waitUntilDone:YES];
                }
            }];
        }];
    }];
}

//Show an alert if some files failed to be converted
- (void)showConvertFailAlert:(NSString *)errorString
{
    MCAlert *alert = [[MCAlert alloc] init];
    [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
	    
    if ([errorString rangeOfString:@"\n"].length > 0)
    {
	    [alert setMessageText:NSLocalizedString(@"Media Converter failed to encode some files", nil)];
    }
    else
    {
	    [alert setMessageText:NSLocalizedString(@"Media Converter failed to encode one file", nil)];
    }
	    
    NSArray *errorParts = [errorString componentsSeparatedByString:@"\nMCLog:"];
    NSString *fileErrors = [errorParts objectAtIndex:0];
    [alert setInformativeText:fileErrors];
    
    [alert beginSheetModalForWindow:[self mainWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
    
    if ([errorParts count] > 1)
    {
	    NSString *ffmpegLog = [errorParts objectAtIndex:1];
	    [alert setDetails:ffmpegLog];
    }
}

#pragma mark - Drop View Delegate Methods

- (void)dropView:(MCDropView *)dropView didDropFiles:(NSArray *)files
{
    [self checkFiles:files];
}

- (void)dropView:(MCDropView *)dropView didDropURL:(NSURL *)url
{
    [self checkFiles:@[[url absoluteString]]];
}

#pragma mark - Preferences Delegate Methods

- (void)preferencesDidUpdatePresets:(MCPreferences *)preferences
{
    [self updatePresets];
}

///////////////////
// Other actions //
///////////////////

#pragma mark -
#pragma mark •• Other actions

//Use some c to get the real path
- (NSString *)getRealPath:(NSString *)inPath
{
    NSURL *url = [NSURL fileURLWithPath:inPath];
    
    CFErrorRef *errorRef = NULL;
    CFDataRef bookmark = CFURLCreateBookmarkDataFromFile (NULL, (__bridge CFURLRef)url, errorRef);
    if (bookmark == nil)
    {
        return inPath;
    }
    
    CFURLRef resolvedUrl = CFURLCreateByResolvingBookmarkData (NULL, bookmark, kCFBookmarkResolutionWithoutUIMask, NULL, NULL, false, errorRef);
    CFRelease(bookmark);
    return CFBridgingRelease(resolvedUrl);
}

//Check for protected file types
- (BOOL)isProtected:(NSString *)path
{
    NSArray *protectedFileTypes = [NSArray arrayWithObjects:@"m4p", @"m4b", NSFileTypeForHFSTypeCode('M4P '), NSFileTypeForHFSTypeCode('M4B '), nil];
    
    long hfsType = [[[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] objectForKey:NSFileHFSTypeCode] longValue];
    return ([protectedFileTypes containsObject:[[path pathExtension] lowercaseString]] || [protectedFileTypes containsObject:NSFileTypeForHFSTypeCode((OSType)hfsType)]);
}

- (void)closeWindow
{
    [NSApp terminate:self];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ([[self mainWindow] attachedSheet] && (aSelector == @selector(openFiles:) || aSelector == @selector(openURLs:) || aSelector == @selector(saveDocumentAs:) || aSelector == @selector(edit:)))
	    return NO;
    
    return [super respondsToSelector:aSelector];
}

+ (void)updateFontListForWindow:(NSWindow *)window withCompletion:(void (^)(void))completion
{
    NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
    NSString *fontPath = [standardDefaults objectForKey:@"MCFontFolderPath"];
    if (fontPath != nil)
    {
        [[NSFileManager defaultManager]  removeItemAtPath:fontPath error:nil];
    }

    MCConverter *converter = [[MCConverter alloc] init];

    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSString *applicationSupportFolder = [@"~/Library/Application Support" stringByExpandingTildeInPath];
    fontPath = [[applicationSupportFolder stringByAppendingPathComponent:@"Media Converter"] stringByAppendingPathComponent:@"Fonts"];
    [standardDefaults setObject:fontPath forKey:@"MCFontFolderPath"];
    
    MCProgressPanel *progressPanel = [MCProgressPanel progressPanel];
    [progressPanel setTask:NSLocalizedString(@"Adding fonts (one time)", nil)];
    [progressPanel setStatus:NSLocalizedString(@"Checking font: %@", nil)];
    [progressPanel setMaximumValue:0.0];
    [progressPanel setAllowCanceling:NO];
    [progressPanel beginSheetForWindow:window];
    
    [defaultManager createDirectoryAtPath:fontPath withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSMutableArray *fontFolderPaths = [NSMutableArray arrayWithObjects:@"/System/Library/Fonts", @"/Library/Fonts", nil];
    NSString *homeFontsFolder = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Fonts"];
    
    if ([defaultManager fileExistsAtPath:homeFontsFolder])
    {
        [fontFolderPaths addObject:homeFontsFolder];
        
        NSString *msFonts = [homeFontsFolder stringByAppendingPathComponent:@"Microsoft"];
        
        if ([defaultManager fileExistsAtPath:homeFontsFolder])
            [fontFolderPaths addObject:msFonts];
    }
    
    NSArray *fontPaths = [MCCommonMethods getFullPathsForFolders:fontFolderPaths withType:@"ttf"];
    [progressPanel setMaximumValue:[fontPaths count] + 4];
    
    [[[NSOperationQueue alloc] init] addOperationWithBlock:^
    {
        NSInteger i;
        for (i = 0; i < [fontPaths count]; i ++)
        {
            NSString *currentFontPath = [fontPaths objectAtIndex:i];
            NSString *fontName = [currentFontPath lastPathComponent];
            
            [progressPanel setStatus:[NSString stringWithFormat:NSLocalizedString(@"Checking font: %@", nil), fontName]];

            NSString *newFontPath = [fontPath stringByAppendingPathComponent:fontName];
            
            if (![defaultManager fileExistsAtPath:newFontPath])
            {
                #if MAC_OS_X_VERSION_MAX_ALLOWED >= 1060
                [defaultManager createSymbolicLinkAtPath:newFontPath withDestinationPath:currentFontPath error:nil];
                #else
                [defaultManager createSymbolicLinkAtPath:newFontPath pathContent:currentFontPath];
                #endif
                
                if (![converter testFontWithName:fontName])
                    #if MAC_OS_X_VERSION_MAX_ALLOWED >= 1060
                    [[NSFileManager defaultManager] removeItemAtPath:newFontPath error:nil];
                    #else
                    [[NSFileManager defaultManager] removeFileAtPath:newFontPath handler:nil];
                    #endif
            }
            
            [progressPanel setValue:i + 1];
        }
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^
        {
            [progressPanel endSheet];
        
            NSArray *defaultFonts = [NSArray arrayWithObjects:      @"AppleGothic.ttf", @"Hei.ttf",
                                                                    @"Osaka.ttf",
                                                                    @"AlBayan.ttf",
                                                                    @"Raanana.ttf", @"Ayuthaya.ttf",
                                                                    @"儷黑 Pro.ttf", @"MshtakanRegular.ttf",
                                                                    nil];
            
            NSArray *defaultLanguages = [NSArray arrayWithObjects:      NSLocalizedString(@"Korean", nil), NSLocalizedString(@"Simplified Chinese", nil),
                                                                        NSLocalizedString(@"Japanese", nil),
                                                                        NSLocalizedString(@"Arabic", nil),
                                                                        NSLocalizedString(@"Hebrew", nil), NSLocalizedString(@"Thai", nil),
                                                                        NSLocalizedString(@"Traditional Chinese", nil), NSLocalizedString(@"Armenian", nil),
                                                                        nil];
            
            NSString *errorMessage = NSLocalizedString(@"Not found:", nil);
            BOOL shouldWarn = NO;
            
            NSInteger z;
            for (z = 0; z < [defaultFonts count]; z ++)
            {
                NSString *font = [defaultFonts objectAtIndex:z];
                
                if (![defaultManager fileExistsAtPath:[fontPath stringByAppendingPathComponent:font]])
                {
                    NSString *language = [defaultLanguages objectAtIndex:z];
                    
                    shouldWarn = YES;
                    
                    NSString *warningString = [NSString stringWithFormat:@"%@ (%@)", font, language];
                    
                    if ([errorMessage isEqualTo:@""])
                        errorMessage = warningString;
                    else
                        errorMessage = [NSString stringWithFormat:@"%@\n%@", errorMessage, warningString];
                }
            }
            
            if (shouldWarn == YES)
            {
                [MCCommonMethods standardAlertWithMessageText:NSLocalizedString(@"Failed to add some default language fonts", nil) withInformationText:NSLocalizedString(@"You can savely ignore this message if you don't use these languages (see details).", nil) withParentWindow:window withDetails:errorMessage completionHandler:^(NSModalResponse returnCode)
                {
                    if (completion)
                    {
                        completion();
                    }
                }];
            }
            else
            {
                if (completion)
                {
                    completion();
                }
            }
        }];
    }];
}

- (void)showNotificationWithTitle:(nonnull NSString *)title withMessage:(nonnull NSString *)message withImage:(NSImage *)image
{
    // TODO: use new methods on the upcoming Mac OS release
    NSUserNotification *userNotification = [[NSUserNotification alloc] init];
    [userNotification setTitle:title];
    [userNotification setInformativeText:message];
    [userNotification setIdentifier:[[NSUUID UUID] UUIDString]];
    [userNotification setSoundName:NSUserNotificationDefaultSoundName];
    if (image != nil)
    {
        [userNotification setContentImage:image];
    }
    
    NSUserNotificationCenter *defaultUserNotificationCenter = [NSUserNotificationCenter defaultUserNotificationCenter];
    [defaultUserNotificationCenter deliverNotification:userNotification];
}

@end
