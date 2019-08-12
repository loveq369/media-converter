//
//  MCFilter.m
//  Media Converter
//
//  Created by Maarten Foukhar on 04-07-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import "MCFilter.h"
#import "MCPresetEditPanel.h"
#import "MCCommonMethods.h"

@interface MCFilter()

@property (nonatomic, strong) IBOutlet NSView *filterView;

@end

@implementation MCFilter

- (instancetype)init
{
    self = [super init];
    
    if (self != nil)
    {
        [[NSBundle mainBundle] loadNibNamed:[self name] owner:self topLevelObjects:nil];
    }
    
    return self;
}

- (instancetype)initForPreview
{
    self = [super init];
    
    if (self != nil)
    {
    }
    
    return self;
}

- (void)setOptions:(NSDictionary *)options
{
    NSDictionary *fallBackDictionary = [NSMutableDictionary dictionaryWithObjects:[self filterDefaultValues] forKeys:[self filterMappings]];
    NSMutableDictionary *filterOptions = [self filterOptions];
    [filterOptions removeAllObjects];
    [filterOptions addEntriesFromDictionary:fallBackDictionary];
    [filterOptions addEntriesFromDictionary:options];
    
}

- (void)setupView
{
    NSArray *filterMappings = [self filterMappings];
    NSDictionary *fallBackDictionary = [NSMutableDictionary dictionaryWithObjects:[self filterDefaultValues] forKeys:filterMappings];
    [MCCommonMethods setViewOptions:@[[self filterView]] infoObject:[self filterOptions] fallbackInfo:fallBackDictionary mappingsObject:filterMappings startCount:0];
}

- (void)resetView
{
    NSMutableDictionary *filterOptions = [self filterOptions];
    [filterOptions removeAllObjects];
    [filterOptions addEntriesFromDictionary:[[NSMutableDictionary alloc] initWithObjects:[self filterDefaultValues] forKeys:[self filterMappings]]];
}

- (NSDictionary *)filterDictionary
{
    return  @{  @"Type": [[self name] copy],
                @"Options": [[self filterOptions] copy],
                @"Identifier": [[self filterIdentifier] copy]
             };
}

- (NSString *)name
{
    return NSStringFromClass([self class]);
}

- (NSString *)filterIdentifier
{
    return @"";
}

+ (NSString *)localizedName
{
    return @"";
}



- (NSArray *)filterMappings
{
    return @[];
}

- (NSArray *)filterDefaultValues
{
    return @[];
}

- (NSMutableDictionary *)filterOptions
{
    return [NSMutableDictionary dictionary];
}

- (CGImageRef)newImageWithSize:(NSSize)size
{
    return NULL;
}

- (IBAction)setFilterOption:(id)sender
{
    NSInteger index = [sender tag] - 1;
    NSString *option = [self filterMappings][index];
    
    [self filterOptions][option] = [sender objectValue];

    [[MCPresetEditPanel editPanel] updatePreview];
}

@end
