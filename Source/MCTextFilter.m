//
//  MCTextFilter.m
//  Media Converter
//
//  Created by Maarten Foukhar on 04-07-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import "MCTextFilter.h"
#import "MCCommonMethods.h"
#import "MCPopupButton.h"
#import "MCPresetManager.h"

@interface MCTextFilter()

@property (nonatomic, strong) IBOutlet NSTextView *textView;
@property (nonatomic, weak) IBOutlet MCPopupButton *textHorizontalPopup;
@property (nonatomic, weak) IBOutlet MCPopupButton *textVerticalPopup;
@property (nonatomic, weak) IBOutlet MCPopupButton *textVisiblePopup;
@property (nonatomic, weak) IBOutlet NSTabView *textMethodTabView;

@property (nonatomic, strong) NSArray *filterMappings;
@property (nonatomic, strong) NSArray *filterDefaultValues;
@property (nonatomic, strong) NSMutableDictionary *filterOptions;

@end

@implementation MCTextFilter

- (instancetype)init
{
    self = [super init];

    if (self != nil)
    {
	    _filterMappings = [[NSArray alloc] initWithObjects:	    //Text
	    	    	    	    	    	    	    	    @"Horizontal Alignment",	    	    //1
	    	    	    	    	    	    	    	    @"Vertical Alignment",    	    	    //2
	    	    	    	    	    	    	    	    @"Left Margin",    	    	    	    //3
	    	    	    	    	    	    	    	    @"Right Margin",	    	    	    //4
	    	    	    	    	    	    	    	    @"Top Margin",    	    	    	    //5
	    	    	    	    	    	    	    	    @"Bottom Margin",	    	    	    //6
	    	    	    	    	    	    	    	    @"Method",	    	    	    	    //7
	    	    	    	    	    	    	    	    @"Border Color",	    	    	    //8
	    	    	    	    	    	    	    	    @"Border Size",    	    	    	    //9
	    	    	    	    	    	    	    	    @"Box Color",    	    	    	    //10
	    	    	    	    	    	    	    	    @"Box Marge",    	    	    	    //11
	    	    	    	    	    	    	    	    @"Box Alpha Value",	    	    	    //12
	    	    	    	    	    	    	    	    @"Alpha Value",    	    	    	    //13
	    nil];
	    
	    _filterDefaultValues = [[NSArray alloc] initWithObjects:	    //Text
    	    	    	    	    	    	    	    	    @"left",    	    	    	    	    	    	    	    // Horizontal Alignment
    	    	    	    	    	    	    	    	    @"top",	    	    	    	    	    	    	    	    // Vertical Alignment
    	    	    	    	    	    	    	    	    [NSNumber numberWithInteger:30],    	    	    	    	    // Left Margin
    	    	    	    	    	    	    	    	    [NSNumber numberWithInteger:30],    	    	    	    	    // Right Margin
    	    	    	    	    	    	    	    	    [NSNumber numberWithInteger:30],    	    	    	    	    // Top Margin
    	    	    	    	    	    	    	    	    [NSNumber numberWithInteger:0],	    	    	    	    	    // Bottom Margin
    	    	    	    	    	    	    	    	    @"border",    	    	    	    	    	    	    	    // Subtitle Method
    	    	    	    	    	    	    	    	    [NSArchiver archivedDataWithRootObject:[NSColor blackColor]],	    // Subtitle Border Color
    	    	    	    	    	    	    	    	    [NSNumber numberWithInteger:4],	    	    	    	    	    // Subtitle Border Size
    	    	    	    	    	    	    	    	    [NSArchiver archivedDataWithRootObject:[NSColor darkGrayColor]],    // Subtitle Box Color
    	    	    	    	    	    	    	    	    [NSNumber numberWithInteger:10],    	    	    	    	    // Subtitle Box Marge
    	    	    	    	    	    	    	    	    [NSNumber numberWithDouble:0.50],    	    	    	    	    // Subtitle Box Alpha Value
    	    	    	    	    	    	    	    	    [NSNumber numberWithDouble:1.00],    	    	    	    	    // Alpha Value
	    nil];
	    
	    _filterOptions = [[NSMutableDictionary alloc] initWithObjects:_filterDefaultValues forKeys:_filterMappings];
        
        [[NSBundle mainBundle] loadNibNamed:@"MCTextFilter" owner:self topLevelObjects:nil];
    }

    return self;
}

- (void)awakeFromNib
{
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self selector:@selector(textChanged) name:@"NSTextDidChangeNotification" object:[self textView]];

    [[self textHorizontalPopup] setArray:[MCCommonMethods defaultHorizontalPopupArray]];
    [[self textVerticalPopup] setArray:[MCCommonMethods defaultVerticalPopupArray]];
    
    NSMutableArray *textVisibilities = [NSMutableArray array];
    [textVisibilities insertObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Text Border", nil), @"Name", @"border", @"Format", nil] atIndex:0];
    [textVisibilities insertObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Surounding Box", nil), @"Name", @"box", @"Format", nil] atIndex:1];
    [textVisibilities insertObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"None", nil), @"Name", @"none", @"Format", nil] atIndex:2];
    [[self textVisiblePopup] setArray:textVisibilities];
}

+ (NSString *)localizedName
{
    return NSLocalizedString(@"Text", nil);
}

- (void)resetView
{
    [[self textView] setString:@""];
    
    [super resetView];
}

- (void)setupView
{
    NSData *textData = [[self filterOptions] objectForKey:@"Text"];
    
    if (textData != nil)
    {
	    NSAttributedString *attrString = [NSUnarchiver unarchiveObjectWithData:textData];
	    [[self textView] insertText:attrString];
    }
    
    [super setupView];
}

- (void)textChanged
{
    NSMutableDictionary *filterOptions = [self filterOptions];

    NSAttributedString *attrString = [[NSAttributedString alloc] initWithAttributedString:[[self textView] textStorage]];
    [filterOptions setObject:[NSArchiver archivedDataWithRootObject:attrString] forKey:@"Text"];
    
    NSString *identString = [attrString string];
    
    if ([identString length] > 60)
	    identString = [[identString substringWithRange:NSMakeRange(0, 60)] stringByAppendingString:@"…"];
	    
    [filterOptions setObject:identString forKey:@"Identifier"];
    
    [[MCPresetManager defaultManager] updatePreview];
}

- (NSString *)filterIdentifier
{
    NSMutableDictionary *filterOptions = [self filterOptions];
    if ([[filterOptions allKeys] containsObject:@"Identifier"])
    {
	    return [filterOptions objectForKey:@"Identifier"];
    }
    else
    {
	    return NSLocalizedString(@"No Text", nil);
    }
}

- (IBAction)setTextVisibility:(id)sender
{
    MCPopupButton *textVisiblePopup = [self textVisiblePopup];
    NSInteger selectedIndex = [textVisiblePopup indexOfSelectedItem];
    
    //Seems when editing a preset from the main window, we have to try until we're woken from the NIB
    while (selectedIndex == -1)
	    selectedIndex = [textVisiblePopup indexOfSelectedItem];
    
    NSTabView *textMethodTabView = [self textMethodTabView];
    if (selectedIndex < 2)
	    [textMethodTabView selectTabViewItemAtIndex:selectedIndex];
	    
    [textMethodTabView setHidden:(selectedIndex == 2)];

    if (sender != nil)
	    [self setFilterOption:sender];
}

- (CGImageRef)imageWithSize:(NSSize)size
{
   NSMutableDictionary *filterOptions = [self filterOptions];
    NSData *textData = [filterOptions objectForKey:@"Text"];
    NSAttributedString *attrString = [NSUnarchiver unarchiveObjectWithData:textData];

    return [MCCommonMethods overlayImageWithObject:attrString withSettings:filterOptions size:size];
}

@end
