//
//  MCPresetManager.m
//  Media Converter
//
//  Created by Maarten Foukhar on 18-09-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import "MCPresetEditPanel.h"
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
#import "MCCommonMethods.h"
#import "MCPresetHelper.h"

@interface MCPresetEditPanel()

/* Preset panel */
@property (nonatomic, strong) IBOutlet NSPanel *presetsPanel;
@property (nonatomic, weak) IBOutlet NSTabView *mainTabView;
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
@property (nonatomic, strong) IBOutlet NSView *hardcodedSettingsView;
@property (nonatomic, weak) IBOutlet MCPopupButton *hardcodedFontPopup;
@property (nonatomic, weak) IBOutlet MCPopupButton *hardcodedHAlignPopup;
@property (nonatomic, weak) IBOutlet MCPopupButton *hardcodedVAlignPopup;
@property (nonatomic, weak) IBOutlet MCPopupButton *hardcodedVisiblePopup;
@property (nonatomic, weak) IBOutlet NSTabView *hardcodedMethodTabView;
// -> DVD
@property (nonatomic, strong) IBOutlet NSView *DVDSettingsView;
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
@property (nonatomic, strong) NSString *currentPresetPath;
@property (nonatomic, strong) NSMutableDictionary *extraOptions;
@property (nonatomic) NSModalSession session;
@property (nonatomic) BOOL previewOpened;
@property (nonatomic) BOOL darkBackground;

@end

@implementation MCPresetEditPanel

static MCPresetEditPanel *_defaultManager = nil;

- (instancetype)init
{
    self = [super init];

    if (self != nil)
    {
	    _viewMappings = [[NSArray alloc] initWithObjects:   @"-f",	    //1
                                                            @"-vcodec", //2
                                                            @"-b:v",	//3
                                                            @"-s",	    //4
                                                            @"-r",	    //5
                                                            @"-acodec", //6
                                                            @"-b:a",	//7
                                                            @"-ar",	    //8
	    nil];
	    
	    _darkBackground = NO;
	    
        [[NSBundle mainBundle] loadNibNamed:@"MCPresetEditPanel" owner:self topLevelObjects:nil];
    }

    return self;
}


- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self setupPopups];
    [self setHarcodedVisibility:nil];
}

//////////////////
// Main actions //
//////////////////

#pragma mark -
#pragma mark •• Main actions

+ (MCPresetEditPanel *)editPanel
{
    static MCPresetEditPanel *editPanel = nil;
    static dispatch_once_t onceToken = 0;

    dispatch_once(&onceToken, ^
    {
        editPanel = [[MCPresetEditPanel alloc] init];
    });
    
    return editPanel;
}

- (void)beginModalForWindow:(NSWindow *)window withPresetPath:(NSString *)path completionHandler:(void (^)(NSModalResponse returnCode))handler;
{
    NSDictionary *presetDictionary;
    
    [[self mainTabView] selectTabViewItemAtIndex:0];
    
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
    
    NSArray *options = presetDictionary[@"Encoder Options"];
    
    NSPanel *presetsPanel = [self presetsPanel];

    [MCCommonMethods setViewOptions:[NSArray arrayWithObject:[presetsPanel contentView]] infoObject:options fallbackInfo:nil mappingsObject:[self viewMappings] startCount:0];
    
    if (options[@"-vn"] != nil)
    {
        [[self videoFormatPopUp] selectItemAtIndex:2];
    }
    
    if (options[@"-an"] != nil)
    {
        [[self audioFormatPopUp] selectItemAtIndex:2];
    }

    [self setExtraOptions:[presetDictionary[@"Extra Options"] mutableCopy]];
    
    NSArray *extraOptionMappings = [[MCPresetHelper sharedHelper] extraOptionMappings];
    [MCCommonMethods setViewOptions:[NSArray arrayWithObjects:[presetsPanel contentView], [self DVDSettingsView], [self hardcodedSettingsView], nil] infoObject:[self extraOptions] fallbackInfo:[NSDictionary dictionaryWithObjects:[[MCPresetHelper sharedHelper] extraOptionDefaultValues] forKeys:extraOptionMappings] mappingsObject:extraOptionMappings startCount:100];
    
    NSMutableArray *filters;
    
    if ([[presetDictionary allKeys] containsObject:@"Video Filters"])
	    filters = [NSMutableArray arrayWithArray:presetDictionary[@"Video Filters"]];
    else
	    filters = [NSMutableArray array];
    
    [[self filterDelegate] setFilterOptions:filters];
	    
    NSString *aspectString = options[@"-aspect"];
	    
    if (aspectString)
    {
	    [[self aspectRatioField] setStringValue:aspectString];
    }

    [[self aspectRatioButton] setState:[[NSNumber numberWithBool:(aspectString != nil)] integerValue]];
    
    NSPopUpButton *modePopup = [self modePopup];
    if ([options containsObject:@{@"-ac": @"1"}])
    {
	    [modePopup selectItemAtIndex:0];
    }
    else if ([options containsObject:@{@"-ac": @"2"}])
    {
	    [modePopup selectItemAtIndex:1];
    }
    else
    {
	    [modePopup selectItemAtIndex:3];
    }
        
    [[self optionDelegate] addOptions:options];
    [[self advancedTableView] reloadData];
    
    [self updateSubtitleOptions];
    [self setSubtitleKind:nil];
    
    [[self completeButton] setTitle:NSLocalizedString(@"Save", nil)];
    
    [self updatePreview];
    
    [window beginSheet:[self window] completionHandler:^(NSModalResponse returnCode)
    {
        [[self previewPanel] orderOut:nil];
    
        if (handler != nil)
        {
            handler(returnCode);
        }
    }];
}

- (void)savePresetForWindow:(NSWindow *)window withPresetPath:(NSString *)path
{
    NSDictionary *presetDictionary = [[NSDictionary alloc] initWithContentsOfFile:path];
    NSString *name = presetDictionary[@"Name"];

    NSSavePanel *sheet = [NSSavePanel savePanel];
    [sheet setAllowedFileTypes:@[@"mcpreset"]];
    [sheet setCanSelectHiddenExtension:YES];
    [sheet setMessage:NSLocalizedString(@"Choose a location to save the preset file", nil)];
    [sheet setNameFieldStringValue:[name stringByAppendingPathExtension:@"mcpreset"]];
    [sheet beginSheetModalForWindow:window completionHandler:^(NSModalResponse result)
    {
        if (result == NSModalResponseOK)
        {
            NSString *error = NSLocalizedString(@"An unknown error occured", nil);
            BOOL result = [MCCommonMethods writeDictionary:presetDictionary toFile:[[sheet URL] path] errorString:&error];

            if (result == NO)
            {
                [MCCommonMethods standardAlertWithMessageText:NSLocalizedString(@"Failed save preset file", nil) withInformationText:error withParentWindow:nil withDetails:nil];
            }
        }
    }];
}

- (NSMutableDictionary *)presetDictionary
{
    NSMutableDictionary *presetDictionary;
    // TODO: why is name never used???
//    NSString *name;
    NSString *currentPresetPath = [self currentPresetPath];
    
    if (!currentPresetPath)
    {
	    presetDictionary = [NSMutableDictionary dictionary];
//        name = [[self nameField] stringValue];
    }
    else
    {
	    presetDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:currentPresetPath];
//        name = [NSString stringWithString:[presetDictionary objectForKey:@"Name"]];
    }
    
    presetDictionary[@"Name"] = [[self nameField] stringValue];
    presetDictionary[@"Version"] = @(2.0);
    presetDictionary[@"Extension"] = [[self extensionField] stringValue];
    presetDictionary[@"Encoder Options"] = [[self optionDelegate] options];
    presetDictionary[@"Extra Options"] = [self extraOptions];
    presetDictionary[@"Video Filters"] = [[self filterDelegate] filterOptions];
    
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
    {
	    [presetsPanel setFrame:NSMakeRect(windowFrame.origin.x, newY, windowFrame.size.width, newHeight) display:YES animate:YES];
    }
    
    [[[self advancedTableView] enclosingScrollView] setHidden:(!shouldExpand)];
    [[self advancedAddButton] setHidden:(!shouldExpand)];
    [[self advancedDeleteButton] setHidden:(!shouldExpand)];
    [[self advancedBarButton] setHidden:(!shouldExpand)];
    
    if (!shouldExpand)
    {
	    [presetsPanel setFrame:NSMakeRect(windowFrame.origin.x, newY, windowFrame.size.width, newHeight) display:YES animate:YES];
    }
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
            {
	    	    [advancedOptions setObject:@"" forKey:@"-an"];
            }
    	    else
            {
	    	    [advancedOptions setObject:@"" forKey:@"-vn"];
            }
	    	    
    	    [[self advancedTableView] reloadData];
	    	    
    	    return;
	    }
        else if ([settings isEqualToString:@"automatic"])
        {
            if ([option isEqualTo:@"-acodec"])
            {
                NSInteger index = [advancedOptions indexOfObject:[NSDictionary dictionaryWithObject:@"" forKey:@"-an"]];
                
                if (index != NSNotFound)
                {
                    [advancedOptions removeObjectAtIndex:index];
                }
                
                NSString *codec = advancedOptions[@"-acodec"];
                if (codec != nil)
                {
                    index = [advancedOptions indexOfObject:@{@"-acodec": advancedOptions[@"-acodec"]}];
                    
                    if (index != NSNotFound)
                    {
                        [advancedOptions removeObjectAtIndex:index];
                    }
                }
            }
            else if ([option isEqualTo:@"-vcodec"])
            {
                NSInteger index = [advancedOptions indexOfObject:[NSDictionary dictionaryWithObject:@"" forKey:@"-vn"]];
                
                if (index != NSNotFound)
                {
                    [advancedOptions removeObjectAtIndex:index];
                }
                
                NSString *codec = advancedOptions[@"-vcodec"];
                if (codec != nil)
                {
                    index = [advancedOptions indexOfObject:@{@"-vcodec": advancedOptions[@"-vcodec"]}];
                    
                    if (index != NSNotFound)
                    {
                        [advancedOptions removeObjectAtIndex:index];
                    }
                }
            }
        }
        else
        {
            if ([option isEqualTo:@"-acodec"])
            {
                NSInteger index = [advancedOptions indexOfObject:[NSDictionary dictionaryWithObject:@"" forKey:@"-an"]];
                
                if (index != NSNotFound)
                {
                    [advancedOptions removeObjectAtIndex:index];
                }
            }
            else if ([option isEqualTo:@"-vcodec"])
            {
                NSInteger index = [advancedOptions indexOfObject:[NSDictionary dictionaryWithObject:@"" forKey:@"-vn"]];
                
                if (index != NSNotFound)
                {
                    [advancedOptions removeObjectAtIndex:index];
                }
            }
        }
    }
    else
    {
	    if ([sender objectValue])
        {
    	    settings = [sender stringValue];
        }
    }
    
    if (![settings isEqualToString:@"automatic"])
    {
        [advancedOptions setObject:settings forKey:option];
    }
    
    [[self advancedTableView] reloadData];
}

- (IBAction)setExtraOption:(id)sender
{
    NSInteger index = [sender tag] - 101;
    NSString *option = [[[MCPresetHelper sharedHelper] extraOptionMappings] objectAtIndex:index];

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
    	    NSString *folder = [@"~/Library/Application Support" stringByExpandingTildeInPath];
    	    folder = [folder stringByAppendingPathComponent:@"Media Converter"];
    	    folder = [folder stringByAppendingPathComponent:@"Presets"];
    	    NSString *path = [folder stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mcpreset", fileName]];
	    
    	    currentPresetPath = [MCCommonMethods uniquePathNameFromPath:path withSeperator:@" "];
         
            NSUserDefaults *standardDefaults = [NSUserDefaults standardUserDefaults];
            NSMutableArray *newPresets = [NSMutableArray arrayWithArray:[standardDefaults objectForKey:@"MCPresets"]];
            [newPresets addObject:currentPresetPath];
            [standardDefaults setObject:newPresets forKey:@"MCPresets"];
	    }
    
	    //Save the (new) dictionary
	    [newDictionary writeToFile:currentPresetPath atomically:YES];
    }
    
    [[presetsPanel sheetParent] endSheet:presetsPanel returnCode:result];
    [presetsPanel orderOut:nil];
    
    [self setCurrentPresetPath:nil];
    [self setExtraOptions:nil];
}

// Video
#pragma mark -
#pragma mark •• - Video

- (IBAction)setAspect:(id)sender
{
    NSMutableArray *advancedOptions = [[self optionDelegate] options];

    NSString *option = @"-aspect";
    NSString *settings = nil;
    
    if ([sender objectValue])
    {
	    if (![[sender stringValue] isEqualTo:@""])
	    {
    	    settings = [sender stringValue];
	    }
    }
	    
    [advancedOptions setObject:settings forKey:option];
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
    {
	    settings = @"";
    }
    
    BOOL isDVD = ([settings isEqualTo:@"dvd"]);
    BOOL isHardcoded = ([settings isEqualTo:@"hard"]);
    
    NSView *subtitleSettingsView = [self subtitleSettingsView];
    NSView *DVDSettingsView = [self DVDSettingsView];
    NSView *hardcodedSettingsView = [self hardcodedSettingsView];
    
    NSArray *subviews = [subtitleSettingsView subviews];
    
    if ([subviews containsObject:DVDSettingsView])
    {
	    [DVDSettingsView removeFromSuperview];
    }
    else if ([subviews containsObject:hardcodedSettingsView])
    {
	    [hardcodedSettingsView removeFromSuperview];
    }
    
    if (isDVD || isHardcoded)
    {
	    NSView *subview = isDVD ? DVDSettingsView : hardcodedSettingsView;
	    [subview setFrame:NSMakeRect(0, [subtitleSettingsView frame].size.height - [subview frame].size.height, [subtitleSettingsView frame].size.width, [subview frame].size.height)];
	    [subtitleSettingsView addSubview:subview];
	    
	    [[self window] recalculateKeyViewLoop];
    }
    
    if (isHardcoded)
    {
        [self setHarcodedVisibility:nil];
    }
}

// Subtitles
#pragma mark -
#pragma mark ••  -> Hardcoded

- (IBAction)setHarcodedVisibility:(id)sender
{
    NSPopUpButton *hardcodedVisiblePopup = [self hardcodedVisiblePopup];
    NSInteger selectedIndex = [hardcodedVisiblePopup indexOfSelectedItem];
    
    NSTabView *hardcodedMethodTabView = [self hardcodedMethodTabView];
    if (selectedIndex > 0)
    {
	    [hardcodedMethodTabView selectTabViewItemAtIndex:selectedIndex - 1];
    }
	    
    [hardcodedMethodTabView setHidden:(selectedIndex == 0)];

    if (sender != nil)
    {
	    [self setExtraOption:sender];
    }
}

/////////////////////
// Preview actions //
/////////////////////

#pragma mark -
#pragma mark •• Preview actions

- (void)updatePreview
{
    MCPresetHelper *standardDefaults = [MCPresetHelper sharedHelper];
    NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithObjects:[standardDefaults extraOptionDefaultValues] forKeys:[standardDefaults extraOptionMappings]];
    [settings addEntriesFromDictionary:[self extraOptions]];
    
    NSString *backgroundName = [self darkBackground] ? @"Sintel-frame-dark" : @"Sintel-frame";
    NSImageView *previewImageView = [self previewImageView];
    
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:backgroundName ofType:@"jpg"];
    NSData *imageData = [[NSData alloc] initWithContentsOfFile:imagePath];
    CGDataProviderRef imgDataProvider = CGDataProviderCreateWithCFData((CFDataRef)imageData);
    CGImageRef backgroundImage = CGImageCreateWithJPEGDataProvider(imgDataProvider, NULL, true, kCGRenderingIntentDefault);
    CGDataProviderRelease(imgDataProvider);
    
    CGImageRef previewImage = [self newPreviewBackgroundWithImage:backgroundImage forSize:[previewImageView frame].size];
    CGImageRelease(backgroundImage);
    
    size_t imageWidth = CGImageGetWidth(previewImage);
    size_t imageHeight = CGImageGetHeight(previewImage);
    NSSize imageSize = NSMakeSize(imageWidth, imageHeight);
    CGImageRef filterImage = [[self filterDelegate] newPreviewImageWithSize:imageSize];
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmapContext = CGBitmapContextCreate(NULL, imageSize.width, imageSize.height, 8, imageSize.width * 4, colorSpace, (CGBitmapInfo)kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(bitmapContext, CGRectMake(0.0, 0.0, imageWidth, imageHeight), previewImage);
    CGImageRelease(previewImage);
    CGContextDrawImage(bitmapContext, CGRectMake(0.0, 0.0, imageWidth, imageHeight), filterImage);
    CGImageRelease(filterImage);
    
    if ([[settings objectForKey:@"Subtitle Type"] isEqualTo:@"hard"])
    {
        CGImageRef subtitleImage = [MCCommonMethods newOverlayImageWithObject:NSLocalizedString(@"This is a scene from the movie Sintel watch it at: www.sintel.org<br><i>second line in italic</i>", nil) withSettings:settings size:imageSize];
        CGContextDrawImage(bitmapContext, CGRectMake(0.0, 0.0, imageWidth, imageHeight), subtitleImage);
        CGImageRelease(subtitleImage);
    }
    
    CGImageRef finalImageRef = CGBitmapContextCreateImage(bitmapContext);
    CGContextRelease(bitmapContext);
    NSImage *finalImage = [[NSImage alloc] initWithCGImage:finalImageRef size:imageSize];
    CGImageRelease(finalImageRef);
    
    [previewImageView setImage:finalImage];
    [previewImageView display];
}

- (IBAction)showPreview:(id)sender
{
    NSPanel *previewPanel = [self previewPanel];
    [self updatePreview];
    if ([previewPanel isVisible])
    {
	    [previewPanel orderOut:nil];
    }
    else
    {
	    [previewPanel orderFront:nil];
    }
}

- (IBAction)toggleDarkBackground:(id)sender
{
    [self setDarkBackground:![self darkBackground]];
    [self updatePreview];
}

- (CGImageRef)newPreviewBackgroundWithImage:(CGImageRef)image forSize:(NSSize)size
{
    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);
    NSSize imageSize = NSMakeSize(width, height);
    CGFloat imageAspect = imageSize.width / imageSize.height;
    CGFloat outputAspect = size.width / size.height;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmapContext = CGBitmapContextCreate(NULL, size.width, size.height, 8, size.width * 4, colorSpace, (CGBitmapInfo)kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    
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
    
    CGImageRef previewBackgroundImage = CGBitmapContextCreateImage(bitmapContext);
    CGContextRelease(bitmapContext);
    return previewBackgroundImage;;
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
    NSString *automaticString = NSLocalizedString(@"preset-panel-pop-up-automatic", nil);
    NSMutableArray *formats = [[NSMutableArray alloc] initWithObjects:@{@"Name": automaticString, @"Format": @"automatic"}, @{@"Name": @"", @"Format": @""}, nil];
    [formats addObjectsFromArray:[converter getFormats]];
    [[self containerPopUp] setArray:formats];
    
    NSArray *videoCodecs = [NSArray arrayWithArray:[converter getCodecsOfType:@"V"]];
    NSMutableArray *audioCodecs = [NSMutableArray arrayWithArray:[converter getCodecsOfType:@"A"]];
    NSArray *codecsNames = [NSArray arrayWithObjects:NSLocalizedString(@"preset-panel-pop-up-automatic", nil), @"", NSLocalizedString(@"Disable", nil), NSLocalizedString(@"Passthrough", nil), @"", nil];
    NSArray *codecsFormats = [NSArray arrayWithObjects:@"automatic", @"", @"none", @"copy", @"", nil];
    
    NSMutableArray *videoPopupItems = [MCCommonMethods popupArrayWithNames:codecsNames forFormats:codecsFormats];
    NSMutableArray *audioPopupItems = [NSMutableArray arrayWithArray:videoPopupItems];
    
    [videoPopupItems addObjectsFromArray:videoCodecs];
    [audioPopupItems addObjectsFromArray:audioCodecs];
    
    [[self videoFormatPopUp] setArray:videoPopupItems];
    [[self audioFormatPopUp] setArray:audioPopupItems];
    
    NSArray *subtitleNames = [NSArray arrayWithObjects:	    NSLocalizedString(@"Disable", nil),
                                                            @"",
                                                            NSLocalizedString(@"Hardcoded", nil),
                                                            NSLocalizedString(@"SRT (External)", nil),
                                                            NSLocalizedString(@"DVD MPEG2", nil),
                                                            NSLocalizedString(@"MPEG4 / 3GP", nil),
                                                            NSLocalizedString(@"Matroska (SRT)", nil),
                                                            NSLocalizedString(@"Ogg (Kate)", nil),
    nil];
    
    NSArray *subtitleFormats = [NSArray arrayWithObjects:   @"none",
                                                            @"",
                                                            @"hard",
                                                            @"srt",
                                                            @"dvd",
                                                            @"mp4",
                                                            @"mkv",
                                                            @"kate",
    nil];
    
    MCPopupButton *subtitleFormatPopUp = [self subtitleFormatPopUp];
    [subtitleFormatPopUp setArray:[MCCommonMethods popupArrayWithNames:subtitleNames forFormats:subtitleFormats]];
    
    NSArray *horizontalAlignments = [MCCommonMethods defaultHorizontalPopupArray];
    [[self hAlignFormatPopUp] setArray:horizontalAlignments];
    [[self hardcodedHAlignPopup] setArray:horizontalAlignments];
    
    NSArray *verticalAlignments = [MCCommonMethods defaultVerticalPopupArray];
    [[self vAlignFormatPopUp] setArray:verticalAlignments];
    [[self hardcodedVAlignPopup] setArray:verticalAlignments];
    
    NSArray *textVisibleNames = [NSArray arrayWithObjects:NSLocalizedString(@"None", nil), NSLocalizedString(@"Text Border", nil), NSLocalizedString(@"Surounding Box", nil), nil];
    NSArray *textVisibleFormats = [NSArray arrayWithObjects:@"none", @"border", @"box", nil];
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
        
        for (NSString *font in fonts)
        {
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

- (void)updateSubtitleOptions
{
    NSArray *encoderOptions = [[self optionDelegate] options];
    NSString *format = encoderOptions[@"-f"];
    
    MCPopupButton *subtitleFormatPopUp = [self subtitleFormatPopUp];
    if ([subtitleFormatPopUp numberOfItems] == 8) // Just to be sure (@"none", @"", @"hard", @"srt", @"dvd", @"mp4", @"mkv", @"kate")
    {
        [[subtitleFormatPopUp itemArray][4] setEnabled:[format isEqualToString:@"dvd"]];
        [[subtitleFormatPopUp itemArray][5] setEnabled:[format isEqualToString:@"ipod"] || [format isEqualToString:@"mp4"] || [format isEqualToString:@"3gp"] || [format isEqualToString:@"3g2"]];
        [[subtitleFormatPopUp itemArray][6] setEnabled:[format isEqualToString:@"matroska"]];
        [[subtitleFormatPopUp itemArray][7] setEnabled:[format isEqualToString:@"ogg"] || [format isEqualToString:@"ogv"]];
    }
}

@end
