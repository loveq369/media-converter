//
//  MCOptionsTableView.m
//  Media Converter
//
//  Created by Maarten Foukhar on 08-03-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import "MCAdvancedOptionsTableView.h"
#import "MCAdvancedOptionsDelegate.h"

@interface MCAdvancedOptionsDelegate (Private)

- (IBAction)addOption:(id)sender;

@end


@implementation MCAdvancedOptionsTableView

- (void)textDidEndEditing:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSInteger textMovement = [[userInfo valueForKey:@"NSTextMovement"] integerValue];
    NSInteger editedColumn = [self editedColumn];
    NSInteger editedRow = [self editedRow];
    
    [super textDidEndEditing:notification];

    if (textMovement == NSTabTextMovement)
    {
	    if (editedColumn == 1)
	    {
    	    if (editedRow < [self numberOfRows] - 1)
    	    {
	    	    [self selectRowIndexes:[NSIndexSet indexSetWithIndex:editedRow + 1] byExtendingSelection:NO];
	    	    [self editColumn:0 row:editedRow+1 withEvent:nil select:YES];
    	    }
    	    else
    	    {
	    	    [(MCAdvancedOptionsDelegate *)[self delegate] addOption:nil];
    	    }
	    }
    }
    else if (textMovement == NSBacktabTextMovement)
    {
	    if (editedColumn == 0)
	    {
    	    [self selectRowIndexes:[NSIndexSet indexSetWithIndex:editedRow - 1] byExtendingSelection:NO];
    	    [self editColumn:1 row:editedRow - 1 withEvent:nil select:YES];
	    }
    }
}

@end
