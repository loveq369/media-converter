//
//  MCDetailsTextView.m
//  Media Converter
//
//  Created by Maarten Foukhar on 16/08/2019.
//

#import "MCDetailsTextView.h"

@implementation MCDetailsTextView

- (id)accessibilityAttributeValue:(NSString *)attribute
{
    //The notification calls this method for attributes:
    //AXRole: returns AXTextArea
    //AXSharedCharacterRange: returns range of the text view

    return [super accessibilityAttributeValue:attribute];
}

- (NSArray *)accessibilityAttributeNames
{
    NSMutableArray *attributeNames = [[super accessibilityAttributeNames] mutableCopy];
    [attributeNames addObject:NSAccessibilityValueAttribute];
    return attributeNames;
}

@end
