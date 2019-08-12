//
//  MCNoAccessibiltyTextField.m
//  Media Converter
//
//  Created by Maarten Foukhar on 11/08/2019.
//

#import "MCNoAccessibiltyTextField.h"

@implementation MCNoAccessibiltyTextField

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
