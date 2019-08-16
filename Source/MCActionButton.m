//
//  MCActionButton.m
//  Media Converter
//
//  Created by Maarten Foukhar on 27-07-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import "MCActionButton.h"
#import "MCCommonMethods.h"

@interface MCActionButton()

@property (nonatomic, strong) NSPopUpButton *menuPopup;

@end


@implementation MCActionButton

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    self = [super initWithCoder:decoder];

    if (self != nil)
    {
        NSRect buttonFrame = [self frame];
        NSRect newFrame = NSMakeRect(buttonFrame.origin.x - 3, buttonFrame.origin.y - (buttonFrame.size.height - 23) , buttonFrame.size.width, buttonFrame.size.height);
        _menuPopup = [[NSPopUpButton alloc] initWithFrame:newFrame pullsDown:YES];
        [_menuPopup addItemWithTitle:@""];
        [_menuPopup setHidden:YES];
    }
    
    return self;
}

- (void)awakeFromNib
{
    [[self superview] addSubview:[self menuPopup]];
}

- (void)layout
{
    [super layout];
    
    [self setImage:[NSImage imageNamed:isAppearanceIsDark([self effectiveAppearance]) ? @"Gear with arrow (dark)" : @"Gear with arrow"]];
}


- (void)addMenuItemWithTitle:(NSString *)title withSelector:(SEL)sel
{
    NSPopUpButton *menuPopup = [self menuPopup];
    [menuPopup addItemWithTitle:title];
    NSMenuItem *editMenuItem = [menuPopup lastItem];
    [editMenuItem setAction:sel];
    [editMenuItem setTarget:[self menuTarget]];
}

- (void)addSeparatorItem
{
    NSPopUpButton *menuPopup = [self menuPopup];
    [[menuPopup menu] addItem:[NSMenuItem separatorItem]];
}

- (void)setTitle:(NSString *)title atIndex:(NSInteger)index
{
    NSArray *menuItems = [[self menuPopup] itemArray];
    NSMenuItem *menuItem = [menuItems objectAtIndex:index + 1];
    [menuItem setTitle:title];
}

- (BOOL)sendAction:(SEL)theAction to:(id)theTarget
{
    [[self menuPopup] performClick:theTarget];

    return YES;
}

@end
