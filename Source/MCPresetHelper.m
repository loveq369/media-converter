//
//  MCPresetDefaults.m
//  Media Converter
//
//  Created by Maarten Foukhar on 08/08/2019.
//

#import "MCPresetHelper.h"
#import "NSArray_Extensions.h"
#import "MCCommonMethods.h"

@implementation MCPresetHelper

- (instancetype)init
{
    self = [super init];
    
    if (self)
    {
        _extraOptionMappings = @[   //Video
                                    @"Keep Aspect",                                     // Tag: 101
                                    @"Auto Aspect",                                     // Tag: 102
                                    @"Auto Size",                                       // Tag: 103

                                    //Subtitles
                                    @"Subtitle Type",                                   // Tag: 104
                                    @"Subtitle Default Language",                       // Tag: 105
                                    // Hardcoded
                                    @"Font",                                            // Tag: 106
                                    @"Font Size",                                       // Tag: 107
                                    @"Color",                                           // Tag: 108
                                    @"Horizontal Alignment",                            // Tag: 109
                                    @"Vertical Alignment",                              // Tag: 110
                                    @"Left Margin",                                     // Tag: 111
                                    @"Right Margin",                                    // Tag: 112
                                    @"Top Margin",                                      // Tag: 113
                                    @"Bottom Margin",                                   // Tag: 114
                                    @"Method",                                          // Tag: 115
                                    @"Box Color",                                       // Tag: 116
                                    @"Box Marge",                                       // Tag: 117
                                    @"Box Alpha Value",                                 // Tag: 118
                                    @"Border Color",                                    // Tag: 119
                                    @"Border Size",                                     // Tag: 120
                                    @"Alpha Value",                                     // Tag: 121
                                    // DVD
                                    @"Subtitle Font",                                   // Tag: 122
                                    @"Subtitle Font Size",                              // Tag: 123
                                    @"Subtitle Horizontal Alignment",                   // Tag: 124
                                    @"Subtitle Vertical Alignment",                     // Tag: 125
                                    @"Subtitle Left Margin",                            // Tag: 126
                                    @"Subtitle Right Margin",                           // Tag: 127
                                    @"Subtitle Top Margin",                             // Tag: 128
                                    @"Subtitle Bottom Margin",                          // Tag: 129

                                    //Advanced
                                    @"Two Pass",                                        // Tag: 130
                                    @"Start Atom",                                      // Tag: 131
                                 ];
        
        _extraOptionDefaultValues = @[  //Video
                                        @(1),                                                               // Keep Aspect
                                        @(NO),                                                              // Auto Aspect
                                        @(NO),                                                              // Auto Size
             
                                        //Subtitles
                                        @"Subtitle Type",                                                   // Subtitle Type
                                        @"Subtitle Default Language",                                       // Subtitle Default Language
                                        // Hardcoded
                                        @"Helvetica",                                                       // Font
                                        @(24),                                                              // Font Size
                                        [NSArchiver archivedDataWithRootObject:[NSColor whiteColor]],       // Color
                                        @"center",                                                          // Horizontal Alignment
                                        @"bottom",                                                          // Vertical Alignment
                                        @(0),                                                               // Left Margin
                                        @(0),                                                               // Right Margin
                                        @(0),                                                               // Top Margin
                                        @(0),                                                               // Bottom Margin
                                        @"box",                                                             // Method
                                        [NSArchiver archivedDataWithRootObject:[NSColor darkGrayColor]],    // Box Color
                                        @(10),                                                              // Box Marge
                                        @(0.50),                                                            // Box Alpha Value
                                        [NSArchiver archivedDataWithRootObject:[NSColor blackColor]],       // Border Color
                                        @(4),                                                               // Border Size
                                        @(1.0),                                                             // Alpha Value
                                        // DVD
                                        @"Helvetica",                                                       // Subtitle Font
                                        @(24),                                                              // Subtitle Font Size
                                        @"center",                                                          // Subtitle Horizontal Alignment
                                        @"bottom",                                                          // Subtitle Vertical Alignment
                                        @(60),                                                              // Subtitle Left Margin
                                        @(60),                                                              // Subtitle Right Margin
                                        @(20),                                                              // Subtitle Top Margin
                                        @(30),                                                              // Subtitle Bottom Margin
             
                                        //Advanced
                                        @(NO),                                                              // Two Pass
                                        @(NO),                                                              // Start Atom
                                     ];
    }
    
    return self;
}

+ (MCPresetHelper *)sharedHelper
{
    static MCPresetHelper *sharedHelper = nil;
    static dispatch_once_t onceToken = 0;

    dispatch_once(&onceToken, ^
    {
        sharedHelper = [[MCPresetHelper alloc] init];
    });
    
    return sharedHelper;
}

- (NSDictionary *)defaults
{
    return [NSDictionary dictionaryWithObjects:[self extraOptionDefaultValues] forKeys:[self extraOptionMappings]];
}

- (void)updatePresetAtPath:(NSString *)path
{
    NSMutableDictionary *preset = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    if ([preset[@"Version"] doubleValue] < 2.0)
    {
        [preset setObject:@(2.0) forKey:@"Version"];

        NSMutableArray *encoderOptions = [preset objectForKey:@"Encoder Options"];

        NSMutableArray *modifiedEncoderOptions = [[NSMutableArray alloc] init];

        NSInteger deblokAlpha = [encoderOptions[@"-deblockalpha"] integerValue];
        NSInteger deblockBeta = [encoderOptions[@"-deblockbeta"] integerValue];
        BOOL deblockSet = NO;

        // Modernise certain FFmpeg options
        for (NSDictionary *dictionary in encoderOptions)
        {
            NSString *key = [dictionary allKeys][0];
            id value = dictionary[key];
            
            if ([key isEqualToString:@"-b"])
            {
                [modifiedEncoderOptions addObject:@{@"-b:v": dictionary[key]}];
            }
            else if ([key isEqualToString:@"-ab"])
            {
                [modifiedEncoderOptions addObject:@{@"-b:a": dictionary[key]}];
            }
            else if (([key isEqualToString:@"deblockalpha"] || [key isEqualToString:@"deblockbeta"]) && (!deblockSet))
            {
                [modifiedEncoderOptions addObject:@{@"-deblock": [NSString stringWithFormat:@"%li:%li", deblokAlpha, deblockBeta]}];
            
                deblockSet = YES;
            }
            else if ([key isEqualToString:@"-async"] && [value isEqualToString:@"1"])
            {
                [modifiedEncoderOptions addObject:@{@"-af": @"aresample=async=1:min_hard_comp=0.100000:first_pts=0"}];
            }
            else if ([key isEqualToString:@"-me_method"])
            {
                [modifiedEncoderOptions addObject:@{@"-motion-est": [NSString stringWithFormat:@"%li", MIN([value integerValue], 4)]}];
            }
            else if ([key isEqualToString:@"-acodec"] && [value isEqualToString:@"libfaac"])
            {
                [modifiedEncoderOptions addObject:@{@"-acodec": @"aac"}];
            }
            else if ((!([key isEqualToString:@"flags"] && [value isEqualToString:@"+loop+slice"])) && (!([key isEqualToString:@"rc_eq"] && [value isEqualToString:@"'blurCplx^(1-qComp)'"])))
            {
                [modifiedEncoderOptions addObject:dictionary];
            }
        }

        [preset setObject:modifiedEncoderOptions forKey:@"Encoder Options"];

        [preset writeToFile:path atomically:YES];
        [MCCommonMethods writeDictionary:preset toFile:path errorString:nil];
    }
}

- (NSInteger)openPresetFiles:(NSArray *)paths
{
    NSInteger numberOfFiles = [paths count];
    NSMutableArray *names = [NSMutableArray array];
    NSMutableArray *dictionaries = [NSMutableArray array];
    
    for (NSString *path in paths)
    {
        NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:path];
        
        if (dictionary)
        {
            [names addObject:dictionary[@"Name"]];
            [dictionaries addObject:dictionary];
        }
    }
    
    NSInteger numberOfDicts = [dictionaries count];
    if (numberOfDicts == 0 || numberOfDicts < numberOfFiles)
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
            [[alert buttons][1] setKeyEquivalent:@"\E"];
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
        {
            detailsString = [NSString stringWithFormat:NSLocalizedString(@"%@ Would you like to continue?", nil), detailsString];
        }
        
        [alert setMessageText:warningString];
        [alert setInformativeText:detailsString];
        NSInteger result = [alert runModal];

        if (result != NSAlertFirstButtonReturn || numberOfDicts == 0)
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

    if (!savePath)
    {
        NSString *applicationSupportFolder = [@"~/Library/Application Support" stringByExpandingTildeInPath];
        
        NSFileManager *defaultManager = [NSFileManager defaultManager];
        NSString *folder = [applicationSupportFolder stringByAppendingPathComponent:@"Media Converter"];
        
        BOOL supportWritable = YES;
        NSString *error = NSLocalizedString(@"An unknown error occured", nil);
        
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
    
    NSInteger i;
    for (i = 0; i < [names count]; i ++)
    {
        NSString *name = [names objectAtIndex:i];
        
        // '/' in the Finder is in reality ':' took me a while to figure that out (failed to save the "iPod / iPhone" dict)
        NSMutableString *mString = [name mutableCopy];
        [mString replaceOccurrencesOfString:@"/" withString:@":" options:NSCaseInsensitiveSearch range:(NSRange){0,[mString length]}];
        name = [NSString stringWithString:mString];
        
        NSDictionary *dictionary = [dictionaries objectAtIndex:i];
        NSString *filePath = [MCCommonMethods uniquePathNameFromPath:[[savePath stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"mcpreset"] withSeperator:@" "];
        
        NSString *error = NSLocalizedString(@"An unknown error occured", nil);
        BOOL result = [MCCommonMethods writeDictionary:dictionary toFile:filePath errorString:&error];
        
        if (result)
        {
            [self updatePresetAtPath:filePath];
        }
        else
        {
            [MCCommonMethods standardAlertWithMessageText:NSLocalizedString(@"Failed to install the preset file", nil) withInformationText:error withParentWindow:nil withDetails:nil];
        
            return NSModalResponseCancel;
        }
    }
    
    return NSModalResponseOK;
}

@end
