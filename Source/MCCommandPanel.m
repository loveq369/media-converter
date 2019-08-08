#import "MCCommandPanel.h"

@interface MCCommandPanel()

@property (nonatomic, weak) IBOutlet NSTableView *commandTableView;
@property (nonatomic, weak) IBOutlet NSPopUpButton *popupButton;
@property (nonatomic, weak) IBOutlet NSSearchField *searchField;

@property (nonatomic, strong) NSMutableArray *rows;
@property (nonatomic, strong) NSString *path;

@end

@implementation MCCommandPanel

- (instancetype)init
{
    self = [super init];
    
    if (self != nil)
    {
        _rows = [[NSMutableArray alloc] init];
        [[NSBundle mainBundle] loadNibNamed:@"MCCommandPanel" owner:self topLevelObjects:nil];
    }

    return self;
}

//When we wake, init array, setup tableview
- (void)awakeFromNib
{
    NSTableView *commandTableView = [self commandTableView];
    [commandTableView setDoubleAction:@selector(chooseCommand:)];
    [commandTableView setTarget:self];
    
    [[self window] makeFirstResponder:[self searchField]];
    
    [self reloadTable];
}

#pragma mark - Main Methods

- (void)beginSheetForWindow:(nonnull NSWindow *)window completionHandler:(nullable void (^)(NSModalResponse returnCode, NSString *commandPath))handler
{
    [window beginSheet:[self window] completionHandler:^(NSModalResponse returnCode)
    {
        if (handler != nil)
        {
            handler(returnCode, [self path]);
        }
    }];
}

- (NSModalResponse)runModal
{
    return [NSApp runModalForWindow:[self window]];
}

#pragma mark - Interface Methods

- (IBAction)cancelCommand:(id)sender
{
    NSWindow *window = [self window];
    [window makeFirstResponder:[self searchField]];
    
    if ([window isSheet])
    {
        NSWindow *sheetParent = [window sheetParent];
        [window orderOut:self];
        [sheetParent endSheet:window returnCode:NSModalResponseCancel];
    }
    else
    {
        [NSApp stopModalWithCode:NSModalResponseCancel];
    }
}

- (IBAction)chooseCommand:(id)sender
{
    NSTableView *commandTableView = [self commandTableView];
    
    if ([commandTableView selectedRow] > -1)
    {
        NSWindow *window = [self window];
    
	    NSString *path = [[[self rows] objectAtIndex:[commandTableView selectedRow]] objectForKey:@"Path"];
	    [self setPath:path];
	    
	    [window makeFirstResponder:[self searchField]];
	    
        if ([window isSheet])
        {
            NSWindow *sheetParent = [window sheetParent];
            [window orderOut:self];
            [sheetParent endSheet:window returnCode:NSModalResponseOK];
        }
        else
        {
            [NSApp stopModalWithCode:NSModalResponseOK];
        }
    }
}

- (IBAction)browseCommand:(id)sender
{
     NSOpenPanel *openPanel = [NSOpenPanel openPanel];
     NSWindow *window = [self window];

    if ([window isSheet])
    {
        NSWindow *sheetParent = [window sheetParent];
        [window orderOut:self];
        [sheetParent endSheet:window returnCode:NSModalResponseCancel];
        
        [openPanel beginSheetModalForWindow:sheetParent completionHandler:^(NSModalResponse result)
        {
            if (result == NSModalResponseOK)
            {
                NSString *path = [[openPanel URL] path];
                [self setPath:path];
            }
        }];
    }
    else
    {
        NSInteger result = [openPanel runModal];

        //User clicked OK in the open dialog
        if (result == NSModalResponseOK)
        {
            NSString *path = [[openPanel URL] path];
            [self setPath:path];
            
            [NSApp stopModalWithCode:NSModalResponseOK];
        }
        else
        {
            [NSApp stopModalWithCode:result];
        }
    }

    
}

- (IBAction)popupChange:(id)sender
{
    [self reloadTable];
}

- (IBAction)searchType:(id)sender
{
    [self reloadTable];
}

- (void)reloadTable
{
    NSArray *paths = nil;
    NSPopUpButton *popupButton = [self popupButton];
    if ([popupButton indexOfSelectedItem] == [popupButton numberOfItems] - 1)
    {
	    paths = [NSArray arrayWithObjects:@"/bin/", @"/usr/bin/", @"/usr/local/bin/", @"/sw/bin/", @"/opt/bin", nil];
    }
    else
    {
	    paths = [NSArray arrayWithObjects:[popupButton title], nil];
    }

    NSInteger x;
    NSMutableArray *rows = [self rows];
    [rows removeAllObjects];

    for(x = 0; x < [paths count]; x ++)
    {
	    NSArray *itemsInPathToOpen = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[paths objectAtIndex:x] error:nil];
	    NSInteger i;
	    NSInteger pathcount;
	    pathcount = [itemsInPathToOpen count];

	    for (i = 0; i < pathcount; i++)
	    {
    	    NSString *item = [itemsInPathToOpen objectAtIndex:i];
    
    	    if ([item rangeOfString:[[self searchField] stringValue]].length > 0 || [[[self searchField] stringValue] isEqualTo:@""])
    	    {
	    	    NSMutableDictionary *rowData = [NSMutableDictionary dictionary];
	    	    [rowData setObject:[[item lastPathComponent] stringByDeletingPathExtension] forKey:@"Command"];
	    	    [rowData setObject:[[paths objectAtIndex:x] stringByAppendingPathComponent:[item lastPathComponent]] forKey:@"Path"];
	    	    [rows addObject:rowData];
    	    }
	    }

	    [[self commandTableView] reloadData];
    }
}

#pragma mark - TableView Delegate / DataSource Methods

//Count the number of rows, not really needed anywhere
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [[self rows] count];
}

//return selected row
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSDictionary *rowData = [[self rows] objectAtIndex:row];
    return [rowData objectForKey:[tableColumn identifier]];
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSMutableDictionary *rowData = [[self rows] objectAtIndex:row];
    [rowData setObject:anObject forKey:[tableColumn identifier]];
}

//We don't want to make people change our row values
- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return NO;
}

@end
