//
//  MCFilter.m
//  Media Converter
//
//  Created by Maarten Foukhar on 04-07-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import "MCFilter.h"


@implementation MCFilter

- (void)dealloc
{
	[filterOptions release];
	filterOptions = nil;
	
	[super dealloc];
}

- (void)setOptions:(NSDictionary *)options
{
	[filterOptions release];
	filterOptions = nil;
	
	filterOptions = [[NSMutableDictionary alloc] initWithDictionary:options];
}

- (void)setupView
{
	[MCCommonMethods setViewOptions:[NSArray arrayWithObject:filterView] infoObject:filterOptions fallbackInfo:nil mappingsObject:filterMappings startCount:0];
}

- (void)resetView
{
	[filterOptions release];
	filterOptions = nil;

	filterOptions = [[NSMutableDictionary alloc] initWithObjects:filterDefaultValues forKeys:filterMappings];
}

- (NSString *)name
{
	return NSStringFromClass([self class]);
}

- (NSString *)identifyer
{
	return @"";
}

+ (NSString *)localizedName
{
	return @"";
}

- (NSView *)filterView
{
	return filterView;
}

- (NSArray *)filterMappings
{
	return filterMappings;
}

- (NSArray *)filterDefaultValues
{
	return filterDefaultValues;
}

- (NSDictionary *)filterOptions
{
	return filterOptions;
}

- (NSImage *)imageWithSize:(NSSize)size
{
	return nil;
}

- (IBAction)setFilterOption:(id)sender
{
	NSInteger index = [sender tag] - 1;
	NSString *option = [filterMappings objectAtIndex:index];

	[filterOptions setObject:[sender objectValue] forKey:option];

	[[NSNotificationCenter defaultCenter] postNotificationName:@"MCUpdatePreview" object:self];
}

@end
