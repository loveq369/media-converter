//
//  MCPopupButton.m
//  Media Converter
//
//  Created by Maarten Foukhar on 15-02-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import "MCPopupButton.h"

@interface MCPopupButton()

@property (nonatomic, strong) NSMutableArray *popUpArray;
@property (nonatomic) NSInteger startIndex;
@property (nonatomic, getter = isDelayed) BOOL delayed;
@property (nonatomic, weak) id delayedObject;

@end


@implementation MCPopupButton

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];

    if (self != nil)
    {
	    _startIndex = 0;
	    _delayed = NO;
	    _delayedObject = nil;
        _popUpArray = [NSMutableArray array];
    }
	    
    return self;
}

- (void)setArray:(NSMutableArray *)array
{
    NSMutableArray *popUpArray = [self popUpArray];
    [popUpArray removeAllObjects];
    
    [self removeAllItems];
    
    //Get the containers from ffmpeg
    NSInteger i;
    for (i = 0; i < [array count]; i ++)
    {
	    NSDictionary *itemDictionary = [array objectAtIndex:i];
    
	    id name = [itemDictionary objectForKey:@"Name"];
	    
	    if ([name isEqualTo:@""])
	    {
    	    [[self menu] addItem:[NSMenuItem separatorItem]];
	    }
	    else
	    {
    	    if ([name isKindOfClass:[NSAttributedString class]])
    	    {
	    	    [self addItemWithTitle:[(NSAttributedString *)name string]];
	    	    [[self lastItem] setAttributedTitle:(NSAttributedString *)name];
    	    }
    	    else
    	    {
	    	    if ([self indexOfItemWithTitle:(NSString *)name] > -1)
    	    	    name = [NSString stringWithFormat:@"%@ (2)", (NSString *)name];
	    
	    	    [self addItemWithTitle:(NSString *)name];
    	    }
	    }
	    
	    NSString *rawName = [itemDictionary objectForKey:@"Format"];

	    [popUpArray addObject:rawName];
    }
}

- (id)objectValue
{	    
    return [[self popUpArray] objectAtIndex:[self indexOfSelectedItem]];
}

- (void)setObjectValue:(id)obj
{
    if ([self isDelayed] == YES)
    {
	    [self setDelayedObject:obj];
    }
    else
    {
        NSMutableArray *popUpArray = [self popUpArray];
	    if (obj == nil || [popUpArray indexOfObject:obj] == NSNotFound)
    	    [self selectItemAtIndex:0];
	    else
    	    [self selectItemAtIndex:[popUpArray indexOfObject:obj]];
    }
}

- (NSInteger)indexOfObjectValue:(id)obj
{
    return [[self popUpArray] indexOfObject:obj];
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
    [super controlTextDidChange:aNotification];
}

- (void)setDelayed:(BOOL)del
{
    _delayed = del;
    
    id delayedObject = [self delayedObject];
    if (del == NO && delayedObject != nil)
	    [self setObjectValue:delayedObject];
}

@end
