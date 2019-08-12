//
//  MCPresetDefaults.m
//  Media Converter
//
//  Created by Maarten Foukhar on 08/08/2019.
//

#import "MCPresetDefaults.h"

@implementation MCPresetDefaults

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

+ (MCPresetDefaults *)standardDefaults
{
    static MCPresetDefaults *standardDefaults = nil;
    static dispatch_once_t onceToken = 0;

    dispatch_once(&onceToken, ^
    {
        standardDefaults = [[MCPresetDefaults alloc] init];
    });
    
    return standardDefaults;
}

- (NSDictionary *)defaults
{
    return [NSDictionary dictionaryWithObjects:[self extraOptionDefaultValues] forKeys:[self extraOptionMappings]];
}

@end
