//
//  MCWatermarkFilter.m
//  Media Converter
//
//  Created by Maarten Foukhar on 04-07-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import "MCWatermarkFilter.h"
#import "MCCommonMethods.h"
#import "MCPopupButton.h"
#import "MCPresetEditPanel.h"
#import "MCDropImageView.h"

@interface MCWatermarkFilter() <MCDropImageViewDelegate>

@property (nonatomic, weak) IBOutlet MCDropImageView *watermarkImage;
@property (nonatomic, weak) IBOutlet NSTextField *watermarkImageName;
@property (nonatomic, weak) IBOutlet NSTextField *watermarkWidthField;
@property (nonatomic, weak) IBOutlet NSTextField *watermarkHeightField;
@property (nonatomic, weak) IBOutlet NSButton *watermarkAspectCheckBox;
@property (nonatomic, weak) IBOutlet MCPopupButton *watermarkHorizontalPopup;
@property (nonatomic, weak) IBOutlet MCPopupButton *watermarkVerticalPopup;

@property (nonatomic) CGFloat aspectRatio;
@property (nonatomic, strong) NSArray *filterMappings;
@property (nonatomic, strong) NSArray *filterDefaultValues;
@property (nonatomic, strong) NSMutableDictionary *filterOptions;

@end


@implementation MCWatermarkFilter

- (instancetype)init
{
    if (self = [super init])
    {
	    [self setup];
        [[NSBundle mainBundle] loadNibNamed:@"MCWatermarkFilter" owner:self topLevelObjects:nil];
    }

    return self;
}

- (instancetype)initForPreview
{
    if (self = [super initForPreview])
    {
        [self setup];
    }

    return self;
}

- (void)setup
{
    _filterMappings = [[NSArray alloc] initWithObjects:        //Watermark
                                                                @"Horizontal Alignment",                //1
                                                                @"Vertical Alignment",                  //2
                                                                @"Left Margin",                         //3
                                                                @"Right Margin",                        //4
                                                                @"Top Margin",                          //5
                                                                @"Bottom Margin",                       //6
                                                                @"Width",                               //7
                                                                @"Height",                              //8
                                                                @"Keep Aspect",                         //9
                                                                @"Alpha Value",                         //10
        nil];
    
        _filterDefaultValues = [[NSArray alloc] initWithObjects:    //Watermark
                                                                    @"right",                           // Horizontal Alignment
                                                                    @"top",                             // Vertical Alignment
                                                                    [NSNumber numberWithInteger:30],    // Left Margin
                                                                    [NSNumber numberWithInteger:30],    // Right Margin
                                                                    [NSNumber numberWithInteger:30],    // Top Margin
                                                                    [NSNumber numberWithInteger:30],    // Bottom Margin
                                                                    [NSNumber numberWithInteger:0],     // Width
                                                                    [NSNumber numberWithInteger:0],     // Height
                                                                    [NSNumber numberWithBool:YES],      // Keep Aspect
                                                                    [NSNumber numberWithDouble:1.00],   // Alpha Value
        nil];
    
        _filterOptions = [[NSMutableDictionary alloc] initWithObjects:_filterDefaultValues forKeys:_filterMappings];
}

- (void)awakeFromNib
{
    [[self watermarkHorizontalPopup] setArray:[MCCommonMethods defaultHorizontalPopupArray]];
    [[self watermarkVerticalPopup] setArray:[MCCommonMethods defaultVerticalPopupArray]];
}

+ (NSString *)localizedName
{
    return NSLocalizedString(@"Watermark", nil);
}

- (void)resetView
{
    [[self watermarkImage] setImage:nil];
    [[self watermarkImageName] setStringValue:NSLocalizedString(@"No image selected", nil)];
    
    [super resetView];
}

- (IBAction)chooseWatermarkImage:(id)sender
{
    NSOpenPanel *sheet = [NSOpenPanel openPanel];
    [sheet setCanChooseFiles:YES];
    [sheet setCanChooseDirectories:NO];
    [sheet setAllowsMultipleSelection:NO];
    [sheet setAllowedFileTypes:[NSImage imageFileTypes]];
    
    NSInteger result = [sheet runModal];
    
    if (result == NSModalResponseOK)
    {
	    NSString *filePath = [[sheet URL] path];
	    NSString *identifier = [[NSFileManager defaultManager] displayNameAtPath:filePath];
	    NSImage *image = [[NSImage alloc] initWithContentsOfFile:filePath];
	    
	    [self setImage:image withIdentifier:identifier];
	    
	    [[MCPresetEditPanel editPanel] updatePreview];
    }
}

- (void)setImage:(NSImage *)image withIdentifier:(NSString *)identifier
{
    [[self watermarkImageName] setStringValue:identifier];
    [[self watermarkImage] setImage:image];
    
    NSSize imageSize = [image size];
    [self setAspectRatio:imageSize.width / imageSize.height];

    [[self watermarkWidthField] setObjectValue:[NSNumber numberWithDouble:imageSize.width]];
    [[self watermarkHeightField] setObjectValue:[NSNumber numberWithDouble:imageSize.height]];
    
    NSMutableDictionary *filterOptions = [self filterOptions];
    [filterOptions setObject:[NSNumber numberWithDouble:imageSize.width] forKey:@"Width"];
    [filterOptions setObject:[NSNumber numberWithDouble:imageSize.height] forKey:@"Height"];
    
    NSData *tiffData = [image TIFFRepresentation];
    NSBitmapImageRep *bitmap = [NSBitmapImageRep imageRepWithData:tiffData];
    NSData *imageData = [bitmap representationUsingType:NSPNGFileType properties:@{}];
	    
    [filterOptions setObject:imageData forKey:@"Overlay Image"];
    [filterOptions setObject:identifier forKey:@"Identifier"];
    
    [[MCPresetEditPanel editPanel] updatePreview];
}

- (NSString *)filterIdentifier
{
    NSMutableDictionary *filterOptions = [self filterOptions];
    if ([[filterOptions allKeys] containsObject:@"Identifier"])
    {
	    return [[NSFileManager defaultManager] displayNameAtPath:[filterOptions objectForKey:@"Identifier"]];
    }
    else
    {
	    return NSLocalizedString(@"No Image", nil);
    }
}

- (void)setupView
{
    NSMutableDictionary *filterOptions = [self filterOptions];
    NSData *imageData = [filterOptions objectForKey:@"Overlay Image"];
    
    if (imageData != nil)
    {
	    NSImage *image = [[NSImage alloc] initWithData:imageData];
	    [[self watermarkImage] setImage:image];
	    [[self watermarkImageName] setStringValue:[filterOptions objectForKey:@"Identifier"]];
	    NSSize imageSize = [image size];
	    [self setAspectRatio:imageSize.width / imageSize.height];
    }
    
    [super setupView];
}

- (IBAction)setFilterOption:(id)sender
{
    NSTextField *watermarkWidthField = [self watermarkWidthField];
    NSTextField *watermarkHeightField = [self watermarkHeightField];
    NSButton *watermarkAspectCheckBox = [self watermarkAspectCheckBox];
    CGFloat aspectRatio = [self aspectRatio];

    if (([sender isEqualTo:watermarkWidthField] || [sender isEqualTo:watermarkHeightField]) && [watermarkAspectCheckBox state] == NSOnState)
    {
	    CGFloat width = [watermarkWidthField doubleValue];
	    CGFloat height = [watermarkHeightField doubleValue];

	    if ([sender isEqualTo:watermarkWidthField])
	    {
    	    [watermarkHeightField setObjectValue:[NSNumber numberWithDouble:(width / aspectRatio)]];
	    }
	    else
	    {
    	    [watermarkWidthField setObjectValue:[NSNumber numberWithDouble:(height * aspectRatio)]];
	    }
	    
	    [super setFilterOption:watermarkWidthField];
	    [super setFilterOption:watermarkHeightField];
	    
	    return;
    }
    else if ([sender isEqualTo:watermarkAspectCheckBox])
    {
	    if ([watermarkAspectCheckBox state] == NSOnState)
    	    [self setFilterOption:watermarkWidthField];
    }

    [super setFilterOption:sender];
}

- (CGImageRef)newImageWithSize:(NSSize)size
{
    NSMutableDictionary *filterOptions = [self filterOptions];
    NSData *imageData = [filterOptions objectForKey:@"Overlay Image"];
    if (imageData != nil)
    {
        return [MCCommonMethods newOverlayImageWithObject:imageData withSettings:filterOptions size:size];
    }
    
    return NULL;
}

- (void)dropImageView:(MCDropImageView *)dropImageView didDropImage:(NSImage *)image withIdentifier:(NSString *)identifier
{
    [self setImage:image withIdentifier:identifier];
    
    [[MCPresetEditPanel editPanel] updatePreview];
}

@end
