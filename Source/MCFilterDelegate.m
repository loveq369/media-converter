//
//  MCFilterDelegate.m
//  Media Converter
//
//  Created by Maarten Foukhar on 25-06-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import "MCFilterDelegate.h"
#import "MCCommonMethods.h"
#import "MCPopupButton.h"
#import "NSArray_Extensions.h"
#import "MCActionButton.h"
#import "MCWatermarkFilter.h"
#import "MCTextFilter.h"
#import "MCTableView.h"
#import "MCPresetEditPanel.h"

@interface MCFilterDelegate()

@property (nonatomic, weak) IBOutlet NSWindow *modalWindow;
@property (nonatomic, weak) IBOutlet MCTableView *tableView;
@property (nonatomic, strong) IBOutlet NSWindow *filterWindow;
@property (nonatomic, weak) IBOutlet MCPopupButton *filterPopup;
@property (nonatomic, weak) IBOutlet NSPanel *previewPanel;
@property (nonatomic, weak) IBOutlet NSImageView *previewImageView;
@property (nonatomic, weak) IBOutlet MCActionButton *actionButton;
@property (nonatomic, weak) IBOutlet NSButton *filterCloseButton;

@property (nonatomic, strong) NSMutableArray *tableData;
@property (nonatomic, strong) NSMutableArray *filters;
@property (nonatomic, strong) id openFilterOptions;
@property (nonatomic, strong) MCFilter *openFilter;

@end


@implementation MCFilterDelegate

- (instancetype)init
{
    self = [super init];

    if (self != nil)
    {
	    _tableData = [[NSMutableArray alloc] init];
	    _filters = [[NSMutableArray alloc] init];
    }

    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    //Setup filters and popup
    NSMutableArray *filters = [self filters];
    NSMutableArray *filterItems = [NSMutableArray array];
    
    MCFilter *watermarkFilter = [[MCWatermarkFilter alloc] init];
    [filters addObject:watermarkFilter];
    [filterItems insertObject:[NSDictionary dictionaryWithObjectsAndKeys:[MCWatermarkFilter localizedName], @"Name", [watermarkFilter name], @"Format", nil] atIndex:0];
    
    MCFilter *textFilter = [[MCTextFilter alloc] init];
    [filters addObject:textFilter];
    [filterItems insertObject:[NSDictionary dictionaryWithObjectsAndKeys:[MCTextFilter localizedName], @"Name", [textFilter name], @"Format", nil] atIndex:1];
    
    [[self filterPopup] setArray:filterItems];
    
    MCTableView *tableView = [self tableView];
    MCActionButton *actionButton = [self actionButton];
    [actionButton setMenuTarget:tableView];
    [actionButton addMenuItemWithTitle:NSLocalizedString(@"Edit Filter…", nil) withSelector:@selector(edit:)];
    [actionButton addMenuItemWithTitle:NSLocalizedString(@"Duplicate Filter", nil) withSelector:@selector(duplicate:)];
    
    
    [tableView setTarget:self];
    [tableView setDoubleAction:@selector(edit:)];
    [tableView registerForDraggedTypes:[NSArray arrayWithObject:@"NSGeneralPboardType"]];
    [tableView setReloadHandler:^
    {
        [[MCPresetEditPanel editPanel] updatePreview];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tableViewSelectionDidChange:) name:@"MCListSelected" object:tableView];
}

- (IBAction)addFilter:(id)sender
{    
    [self selectFilter:nil];
    [[self openFilter] resetView];
    
    [[self filterCloseButton] setTitle:NSLocalizedString(@"Add", nil)];

    [[self modalWindow] beginSheet:[self filterWindow] completionHandler:^(NSModalResponse returnCode)
    {
        if (returnCode == NSModalResponseOK)
        {
            MCFilter *currentFilter = [[self filters] objectAtIndex:[[self filterPopup] indexOfSelectedItem]];
            
            [[self tableData] addObject:[currentFilter filterDictionary]];
            [[self tableView] reloadData];
        }
        
        [self setOpenFilter:nil];
        
        [[MCPresetEditPanel editPanel] updatePreview];
    }];
}

- (IBAction)add:(id)sender
{
    NSWindow *filterWindow = [self filterWindow];
    [filterWindow orderOut:nil];
    [[self modalWindow] endSheet:filterWindow returnCode:NSModalResponseOK];
}

- (IBAction)cancel:(id)sender
{
    NSWindow *filterWindow = [self filterWindow];
    [filterWindow orderOut:nil];
    [[self modalWindow] endSheet:filterWindow returnCode:NSModalResponseCancel];
}

- (IBAction)delete:(id)sender
{
    NSMutableArray *tableData = [self tableData];
    NSTableView *tableView = [self tableView];
    
    NSArray *removeObjects = [self allSelectedItemsInTableView:tableView fromArray:tableData];

    [tableData removeObjectsInArray:removeObjects];
    [tableView reloadData];
}

- (IBAction)duplicate:(id)sender
{
    NSMutableArray *tableData = [self tableData];
    NSTableView *tableView = [self tableView];

    NSInteger selRow = [tableView selectedRow];
    
    if (selRow > -1)
    {
	    NSArray *selectedObjects = [MCCommonMethods allSelectedItemsInTableView:tableView fromArray:tableData];
	    [tableView deselectAll:nil];
	    
	    NSInteger i;
	    for (i = 0; i < [selectedObjects count]; i ++)
	    {
    	    NSDictionary *selectedObject = [selectedObjects objectAtIndex:i];

    	    NSMutableDictionary *filterDictionary = [NSMutableDictionary dictionaryWithDictionary:selectedObject];
    	    
    	    NSString *oldIdentifier = [filterDictionary objectForKey:@"Identifier"];
    	    NSString *newIdentifier = [NSString stringWithFormat:NSLocalizedString(@"%@ copy", nil), oldIdentifier];
    	    [filterDictionary setObject:newIdentifier forKey:@"Identifier"];
    	    
    	    NSInteger uniqueInt = 2;
    	    while ([tableData containsObject:filterDictionary])
    	    {
                [filterDictionary setObject:[NSString stringWithFormat:@"%@ %li", newIdentifier, (long)uniqueInt] forKey:@"Identifier"];
	    	    uniqueInt = uniqueInt + 1;
    	    }
    	    
    	    [tableData addObject:filterDictionary];
	    }
	    
	    [tableView reloadData];
    }
}

- (IBAction)edit:(id)sender
{
    NSInteger selectedRow = [[self tableView] selectedRow];
    
    if (selectedRow > - 1)
    {
	    NSDictionary *filterOptions = [[self tableData] objectAtIndex:selectedRow];
	    NSString *type = [filterOptions objectForKey:@"Type"];
        
        [self setOpenFilterOptions:filterOptions];
        
        NSPopUpButton *filterPopup = [self filterPopup];
	    [filterPopup setObjectValue:type];
	    [self selectFilter:nil];
    
	    MCFilter *openFilter = [[self filters] objectAtIndex:[filterPopup indexOfSelectedItem]];
	    [openFilter setOptions:[filterOptions objectForKey:@"Options"]];
	    [openFilter setupView];
        [self setOpenFilter:openFilter];
        
        [[MCPresetEditPanel editPanel] updatePreview];
    
	    [[self filterCloseButton] setTitle:NSLocalizedString(@"Save", nil)];
    
	    [[self modalWindow] beginSheet:[self filterWindow] completionHandler:^(NSModalResponse returnCode)
        {
            if (returnCode == NSModalResponseOK)
            {
                MCFilter *currentFilter = [[self filters] objectAtIndex:[[self filterPopup] indexOfSelectedItem]];

                MCTableView *tableView = [self tableView];
                [[self tableData] replaceObjectAtIndex:[tableView selectedRow] withObject:[currentFilter filterDictionary]];
                [tableView reloadData];
            }
            
            [self setOpenFilterOptions:nil];
            [self setOpenFilter:nil];
            
            [[MCPresetEditPanel editPanel] updatePreview];
        }];
    }
}

- (void)filterEditSheetDidEnd:(NSWindow*)panel returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [panel makeFirstResponder:nil];
    [panel orderOut:nil];
}

- (IBAction)selectFilter:(id)sender
{
    NSMutableArray *filters = [self filters];
    NSWindow *filterWindow = [self filterWindow];

    for (MCFilter *filter in filters)
    {
	    NSView *currentView = [filter filterView];
	    
	    if ([[[filterWindow contentView] subviews] containsObject:currentView])
        {
    	    [currentView removeFromSuperview];
         }
    }
    
    MCFilter *openFilter = [filters objectAtIndex:[[self filterPopup] indexOfSelectedItem]];
    [openFilter setupView];
    [self setOpenFilter:openFilter];
    
    NSView *newView = [openFilter filterView];

    NSRect filterViewFrame = [newView frame];
    NSRect windowFrame = [filterWindow frame];
    
    CGFloat newWidth = filterViewFrame.size.width;
    CGFloat newHeight = filterViewFrame.size.height + 112;
    
    //Took me a while to figure out a height problem (when this call is done before the sheet opens the window misses a title bar)
    if (![filterWindow isSheet])
    {
	    newHeight += 22;
    }
    
    CGFloat newY = windowFrame.origin.y - (newHeight - windowFrame.size.height);
    
    [filterWindow setFrame:NSMakeRect(windowFrame.origin.x, newY, newWidth, newHeight) display:YES animate:(sender != nil)];
    [newView setFrame:NSMakeRect(0, 60, filterViewFrame.size.width, filterViewFrame.size.height)];
    
    [[filterWindow contentView] addSubview:newView];
    [filterWindow recalculateKeyViewLoop];
    
    [[MCPresetEditPanel editPanel] updatePreview];
}

- (void)setFilterOptions:(NSMutableArray *)filterOptions
{
    [self setTableData:[filterOptions mutableCopy]];
    [[self tableView] reloadData];
}

- (NSMutableArray *)filterOptions
{
    return [self tableData];
}

- (IBAction)showPreview:(id)sender
{
    NSPanel *previewPanel = [self previewPanel];
    if ([previewPanel isVisible])
    {
	    [previewPanel orderOut:nil];
    }
    else
    {
	    [previewPanel orderFront:nil];
    }
}

- (CGImageRef)newPreviewImageWithSize:(NSSize)size
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmapContext = CGBitmapContextCreate(NULL, size.width, size.height, 8, size.width * 4, colorSpace, (CGBitmapInfo)kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    BOOL openFilterDrawn = NO;
    for (NSDictionary *filterOptions in [self tableData])
    {
	    if (filterOptions != [self openFilterOptions])
	    {
    	    NSString *type = [filterOptions objectForKey:@"Type"];
	    
    	    MCFilter *filter = [[NSClassFromString(type) alloc] initForPreview];
    	    [filter setOptions:[filterOptions objectForKey:@"Options"]];
    	    
            CGImageRef filterImage = [filter newImageWithSize:size];
            if (filterImage != NULL)
            {
                CGContextDrawImage(bitmapContext, NSMakeRect(0, 0, size.width, size.height), filterImage);
                CGImageRelease(filterImage);
            }
	    }
        else
        {
            MCFilter *openFilter = [self openFilter];
            if (openFilter != nil)
            {
                CGImageRef filterImage = [openFilter newImageWithSize:size];
                if (filterImage != NULL)
                {
                    CGContextDrawImage(bitmapContext, NSMakeRect(0, 0, size.width, size.height), filterImage);
                    CGImageRelease(filterImage);
                }
            }
            openFilterDrawn = YES;
        }
    }
    
    if (!openFilterDrawn)
    {
        MCFilter *openFilter = [self openFilter];
        if (openFilter != nil)
        {
            CGImageRef filterImage = [openFilter newImageWithSize:size];
            if (filterImage != NULL)
            {
                CGContextDrawImage(bitmapContext, NSMakeRect(0, 0, size.width, size.height), filterImage);
                CGImageRelease(filterImage);
            }
        }
    }
    
    CGImageRef previewImage = CGBitmapContextCreateImage(bitmapContext);
    CGContextRelease(bitmapContext);
    return previewImage;
}

//////////////////////
// Tableview actions //
///////////////////////

#pragma mark -
#pragma mark •• Tableview actions

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSString *newTitle;
    if ([[self tableView] numberOfSelectedRows] > 1)
	    newTitle = NSLocalizedString(@"Duplicate Filters", nil);
    else
	    newTitle = NSLocalizedString(@"Duplicate Filter", nil);
    
    [[self actionButton] setTitle:newTitle atIndex:1];
}

//Count the number of rows, not really needed anywhere
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [[self tableData] count];
}

//return selected row
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSDictionary *currentDictionary = [[self tableData] objectAtIndex:row];
    NSString *type = [currentDictionary objectForKey:@"Type"];
    NSString *identifier = [currentDictionary objectForKey:@"Identifier"];

    NSString *rowName = [NSString stringWithFormat:@"%@ (%@)", [NSClassFromString(type) localizedName], identifier];

    return rowName;
}

//We don't want to make people change our row values
- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return NO;
}

//Needed to be able to drag rows
- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op
{
    NSInteger result = NSDragOperationNone;
    
    NSPasteboard *pboard = [info draggingPasteboard];
    NSData *data = [pboard dataForType:@"NSGeneralPboardType"];
    NSIndexSet *rowIndexes = [NSUnarchiver unarchiveObjectWithData:data];
    NSInteger firstIndex = [rowIndexes firstIndex];
    
    if (row > firstIndex - 1 && row < firstIndex + [rowIndexes count] + 1)
	    return result;

    if (op == NSTableViewDropAbove) {
        result = NSDragOperationMove;
    }

    return (result);
}

- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)op
{
    NSPasteboard *pboard = [info draggingPasteboard];
    NSMutableArray *tableData = [self tableData];

    if ([[pboard types] containsObject:@"NSGeneralPboardType"])
    {
	    NSData *data = [pboard dataForType:@"NSGeneralPboardType"];
	    NSIndexSet *rowIndexes = [NSUnarchiver unarchiveObjectWithData:data];
        NSInteger firstIndex = [rowIndexes firstIndex];
    
	    NSMutableArray *filterList = [NSMutableArray array];
     
        [rowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop)
        {
            [filterList addObject:[[self tableData] objectAtIndex:idx]];
        }];
	    
	    if (firstIndex < row)
	    {
    	    for (id object in filterList)
    	    {
	    	    NSInteger index = row - 1;
	    	    
	    	    [self moveRowAtIndex:[tableData indexOfObject:object] toIndex:index];
    	    }
	    }
	    else
	    {
    	    for (id object in [filterList reverseObjectEnumerator])
    	    {
	    	    NSInteger index = row;
	    	    
	    	    [self moveRowAtIndex:[tableData indexOfObject:object] toIndex:index];
    	    }
	    }
    }
    
    return YES;
}

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pasteboard
{
    NSData *data = [NSArchiver archivedDataWithRootObject:rowIndexes];
    [pasteboard declareTypes: [NSArray arrayWithObjects:@"NSGeneralPboardType", nil] owner:nil];
    [pasteboard setData:data forType:@"NSGeneralPboardType"];
   
    return YES;
}

- (NSArray*)allSelectedItemsInTableView:(NSTableView *)tableView fromArray:(NSArray *)array
{
    NSMutableArray *items = [NSMutableArray array];
    NSIndexSet *indexSet = [tableView selectedRowIndexes];
    
    NSUInteger current_index = [indexSet firstIndex];
    while (current_index != NSNotFound)
    {
	    if ([array objectAtIndex:current_index]) 
    	    [items addObject:[array objectAtIndex:current_index]];
    	    
        current_index = [indexSet indexGreaterThanIndex: current_index];
    }

    return items;
}

- (void)moveRowAtIndex:(NSInteger)index toIndex:(NSInteger)destIndex
{
    NSMutableArray *tableData = [self tableData];
    MCTableView *tableView = [self tableView];

    NSArray *allSelectedItems = [self allSelectedItemsInTableView:tableView fromArray:tableData];
    NSData *data = [NSArchiver archivedDataWithRootObject:[tableData objectAtIndex:index]];
    BOOL isSelected = [allSelectedItems containsObject:[tableData objectAtIndex:index]];
	    
    if (isSelected)
	    [tableView deselectRow:index];
    
    if (destIndex < index)
    {
	    NSInteger x;
	    for (x = index; x > destIndex; x --)
	    {
    	    id object = [tableData objectAtIndex:x - 1];
    
    	    [tableData replaceObjectAtIndex:x withObject:object];
	    
    	    if ([allSelectedItems containsObject:object])
    	    {
	    	    [tableView deselectRow:x - 1];
	    	    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:x] byExtendingSelection:YES];
    	    }
	    }
    }
    else
    {
	    NSInteger x;
	    for (x = index;x<destIndex;x++)
	    {
    	    id object = [tableData objectAtIndex:x + 1];
    
    	    [tableData replaceObjectAtIndex:x withObject:object];
	    
    	    if ([allSelectedItems containsObject:object])
    	    {
	    	    [tableView deselectRow:x + 1];
	    	    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:x] byExtendingSelection:YES];
    	    
    	    }
	    }
    }
    
    [tableData replaceObjectAtIndex:destIndex withObject:[NSUnarchiver unarchiveObjectWithData:data]];
    [tableView reloadData];
    
    if (isSelected)
    {
	    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:destIndex] byExtendingSelection:YES];
    }
}

@end
