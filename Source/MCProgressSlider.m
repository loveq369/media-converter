//
//  MCProgressSlider.m
//  Media Converter
//
//  Created by Maarten Foukhar on 30-08-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import "MCProgressSlider.h"
#import "MCCommonMethods.h"

@interface MCProgressSlider()

@property (nonatomic, weak) IBOutlet id statusText;

@end

@implementation MCProgressSlider

- (void)setObjectValue:(id <NSCopying>)obj
{
    [super setObjectValue:obj];
    [self updateText:[self doubleValue]];
}

- (BOOL)sendAction:(SEL)theAction to:(id)theTarget
{
    [self updateText:[self doubleValue]];
    
    return [super sendAction:theAction to:theTarget];
}

- (void)updateText:(CGFloat)value
{
    NSString *percentString = [NSString stringWithFormat:@"%0.f %%", value * 100.0];
    [[self statusText] setStringValue:percentString];
}

@end
