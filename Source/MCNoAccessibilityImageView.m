//
//  MCNoAccessibilityImageView.m
//  Media Converter
//
//  Created by Maarten Foukhar on 11/08/2019.
//

#import "MCNoAccessibilityImageView.h"

@implementation MCNoAccessibilityImageView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    if (@available(macOS 10.10, *))
    {
        [[self cell] setAccessibilityElement:NO];
    }
    else
    {
        [[self cell] accessibilitySetOverrideValue:@"" forAttribute:NSAccessibilityRoleAttribute];
    }
}

@end
