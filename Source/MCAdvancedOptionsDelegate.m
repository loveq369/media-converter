//
//  MCOptionsDelegate.m
//
//  Created by Maarten Foukhar on 27-01-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import "MCAdvancedOptionsDelegate.h"
#import "MCPresetEditPanel.h"

@interface MCAdvancedOptionsDelegate()

@property (nonatomic, weak) IBOutlet NSTableView *tableView;
@property (nonatomic, weak) IBOutlet MCPresetEditPanel *presetManager;

@property (nonatomic, strong) NSMutableArray *tableData;

@end

@implementation MCAdvancedOptionsDelegate

- (instancetype)init
{
    self = [super init];

    if (self != nil)
    {
	    _tableData = [[NSMutableArray alloc] init];
    }

    return self;
}

- (IBAction)addOption:(id)sender
{
    NSTableView *tableView = [self tableView];
    NSMutableArray *tableData = [self tableData];
    
    [tableData addObject:[NSDictionary dictionaryWithObject:@"" forKey:@""]];
    [tableView reloadData];
    
    NSInteger lastRow = [tableData count] - 1;
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:lastRow] byExtendingSelection:NO];
    [tableView editColumn:0 row:lastRow withEvent:nil select:YES];
}

- (IBAction)removeOption:(id)sender
{
    NSTableView *tableView = [self tableView];
    NSMutableArray *tableData = [self tableData];
    
    NSArray *removeObjects = [self allSelectedItemsInTableView:tableView fromArray:tableData];
    
    NSInteger i;
    for (i = 0; i < [removeObjects count]; i ++)
    {
	    id object = [removeObjects objectAtIndex:i];
	    NSInteger index = [tableData indexOfObject:object];
	    NSDictionary *currentDictionary = [tableData objectAtIndex:index];
	    NSString *currentKey = [[currentDictionary allKeys] objectAtIndex:0];
	    
	    [[self presetManager] updateForKey:currentKey withProperty:nil];
    }

    [tableData removeObjectsInArray:removeObjects];
    [tableView reloadData];
}

- (void)addOptions:(NSArray *)options
{
    NSMutableArray *tableData = [self tableData];
    [tableData removeAllObjects];
    [tableData addObjectsFromArray:options];
}

- (NSMutableArray *)options
{
    return [self tableData];
}

//////////////////////
// Tableview actions //
///////////////////////

#pragma mark -
#pragma mark •• Tableview actions

//Count the number of rows, not really needed anywhere
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [[self tableData] count];
}

//return selected row
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSDictionary *currentDictionary = [[self tableData] objectAtIndex:row];
    NSString *currentKey = [[currentDictionary allKeys] objectAtIndex:0];
    
    NSString *identifier = [tableColumn identifier];
    
    if ([identifier isEqualTo:@"option"])
	    return currentKey;
    else
	    return [currentDictionary objectForKey:currentKey];
}

//We don't want to make people change our row values
- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return YES;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSMutableArray *tableData = [self tableData];
    NSDictionary *currentDictionary = [tableData objectAtIndex:row];
    NSString *currentKey = [[currentDictionary allKeys] objectAtIndex:0];
    NSInteger currentIndex = [tableData indexOfObject:currentDictionary];
    
    NSString *identifier = [tableColumn identifier];
    NSDictionary *newDictionary;
    
    MCPresetEditPanel *windowController = [self presetManager];
    if ([identifier isEqualTo:@"option"])
    {
	    id currentObject = [currentDictionary objectForKey:currentKey];
	    newDictionary = [NSDictionary dictionaryWithObject:currentObject forKey:anObject];
	    
	    [windowController updateForKey:currentKey withProperty:nil];
	    [windowController updateForKey:anObject withProperty:currentObject];
    }
    else
    {
	    newDictionary = [NSDictionary dictionaryWithObject:anObject forKey:currentKey];
	    [windowController updateForKey:currentKey withProperty:anObject];
    }

    [tableData replaceObjectAtIndex:currentIndex withObject:newDictionary];
}

- (NSArray *)allSelectedItemsInTableView:(NSTableView *)table fromArray:(NSArray *)array
{
    NSMutableArray *items = [NSMutableArray array];
    NSIndexSet *indexSet = [table selectedRowIndexes];
    
    NSUInteger current_index = [indexSet firstIndex];
    while (current_index != NSNotFound)
    {
	    if ([array objectAtIndex:current_index]) 
    	    [items addObject:[array objectAtIndex:current_index]];
    	    
        current_index = [indexSet indexGreaterThanIndex: current_index];
    }

    return items;
}

@end
