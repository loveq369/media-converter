//
//  MCOptionsDelegate.m
//
//  Created by Maarten Foukhar on 27-01-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import "MCAdvancedOptionsDelegate.h"
#import "MCPresetEditPanel.h"
#import "MCCommonMethods.h"

@interface MCAdvancedOptionsDelegate()

@property (nonatomic, weak) IBOutlet NSTableView *tableView;
@property (nonatomic, weak) IBOutlet MCPresetEditPanel *presetManager;

@property (nonatomic, strong) NSMutableArray *tableData;

@property (nonatomic, strong) IBOutlet NSPanel *accessibilityAddPanel;
@property (nonatomic, weak) IBOutlet NSTextField *accessibilityAddOptionTextField;
@property (nonatomic, weak) IBOutlet NSTextField *accessibilityAddSettingTextField;
@property (nonatomic, weak) IBOutlet NSButton *accessibilityAddButton;

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
    
    if ([MCCommonMethods isVoiceOverEnabled])
    {
        [[self accessibilityAddOptionTextField] setStringValue:@""];
        [[self accessibilityAddSettingTextField] setStringValue:@""];
        [[self accessibilityAddButton] setEnabled:NO];
        [[self accessibilityAddPanel] makeFirstResponder:[self accessibilityAddOptionTextField]];
    
        [[[self presetManager] presetsPanel] beginSheet:[self accessibilityAddPanel] completionHandler:^(NSModalResponse returnCode)
        {
            if (returnCode == NSModalResponseOK)
            {
                [tableData addObject:@{[[self accessibilityAddOptionTextField] stringValue]: [[self accessibilityAddSettingTextField] stringValue]}];
                [tableView reloadData];
            }
        }];
    }
    else
    {
        [tableData addObject:[NSDictionary dictionaryWithObject:@"" forKey:@""]];
        [tableView reloadData];
        
        NSInteger lastRow = [tableData count] - 1;
        [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:lastRow] byExtendingSelection:NO];
        [tableView editColumn:0 row:lastRow withEvent:nil select:YES];
    }
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

///////////////////////////
// Accessibility actions //
///////////////////////////

#pragma mark -
#pragma mark •• Accessibility actions

- (void)controlTextDidChange:(NSNotification *)notification
{
    [self updateAddButton:nil];
}

- (IBAction)updateAddButton:(id)sender
{
    BOOL enabled = (![[[self accessibilityAddOptionTextField] stringValue] isEqualToString:@""]) && (![[[self accessibilityAddSettingTextField] stringValue] isEqualToString:@""]);
    [[self accessibilityAddButton] setEnabled:enabled];
}

- (IBAction)add:(id)sender
{
    NSPanel *accessibilityAddPanel = [self accessibilityAddPanel];
    [accessibilityAddPanel orderOut:nil];
    [[[self presetManager] presetsPanel] endSheet:accessibilityAddPanel returnCode:NSModalResponseOK];
}

- (IBAction)cancelAdd:(id)sender
{
    NSPanel *accessibilityAddPanel = [self accessibilityAddPanel];
    [accessibilityAddPanel orderOut:nil];
    [[[self presetManager] presetsPanel] endSheet:accessibilityAddPanel returnCode:NSModalResponseCancel];
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
    {
	    return currentKey;
    }
    else
    {
	    return [currentDictionary objectForKey:currentKey];
    }
}

//We don't want to make people change our row values
- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return ![MCCommonMethods isVoiceOverEnabled];
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
