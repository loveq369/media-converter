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
#import "MCPresetEditPanel.h"

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
    if (self = [super init])
    {
        [self setup];
        [[NSBundle mainBundle] loadNibNamed:@"MCTextFilter" owner:self topLevelObjects:nil];
    }

    return self;
}

- (instancetype)initForPreview
{
    if (self = [super initForPreview])
    {
        [self setup];
    }

    return self;
}

- (void)setup
{
     _filterMappings = @[   @"Horizontal Alignment",                                                //1
                            @"Vertical Alignment",                                                  //2
                            @"Left Margin",                                                         //3
                            @"Right Margin",                                                        //4
                            @"Top Margin",                                                          //5
                            @"Bottom Margin",                                                       //6
                            @"Method",                                                              //7
                            @"Border Color",                                                        //8
                            @"Border Size",                                                         //9
                            @"Box Color",                                                           //10
                            @"Box Marge",                                                           //11
                            @"Box Alpha Value",                                                     //12
                            @"Alpha Value",                                                         //13
                       ];
    
    _filterDefaultValues = @[   @"left",                                                            // Horizontal Alignment
                                @"top",                                                             // Vertical Alignment
                                @(30),                                                              // Left Margin
                                @(30),                                                              // Right Margin
                                @(30),                                                              // Top Margin
                                @(0),                                                               // Bottom Margin
                                @"none",                                                            // Method
                                [NSArchiver archivedDataWithRootObject:[NSColor blackColor]],       // Border Color
                                @(4),                                                               // Border Size
                                [NSArchiver archivedDataWithRootObject:[NSColor darkGrayColor]],    // Box Color
                                @(10),                                                              // Box Marge
                                @(0.50),                                                            // Box Alpha Value
                                @(1.00),                                                            // Alpha Value
                           ];
    
    _filterOptions = [[NSMutableDictionary alloc] initWithObjects:_filterDefaultValues forKeys:_filterMappings];
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter addObserver:self selector:@selector(textChanged) name:@"NSTextDidChangeNotification" object:[self textView]];

    [[self textHorizontalPopup] setArray:[MCCommonMethods defaultHorizontalPopupArray]];
    [[self textVerticalPopup] setArray:[MCCommonMethods defaultVerticalPopupArray]];
    
    NSMutableArray *textVisibilities = [NSMutableArray array];
    [textVisibilities insertObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"None", nil), @"Name", @"none", @"Format", nil] atIndex:0];
    [textVisibilities insertObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Text Border", nil), @"Name", @"border", @"Format", nil] atIndex:1];
    [textVisibilities insertObject:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Surounding Box", nil), @"Name", @"box", @"Format", nil] atIndex:2];
    [[self textVisiblePopup] setArray:textVisibilities];
    
    [self setTextVisibility:nil];
}

+ (NSString *)localizedName
{
    return NSLocalizedString(@"Text", nil);
}

- (void)resetView
{
    [[[self textView] textStorage] setAttributedString:[[NSAttributedString alloc] initWithString:@""]];
    
    [super resetView];
}

- (void)setupView
{
    NSData *textData = [[self filterOptions] objectForKey:@"Text"];
    
    if (textData != nil)
    {
	    NSAttributedString *attrString = [NSUnarchiver unarchiveObjectWithData:textData];
        [[[self textView] textStorage] setAttributedString:attrString];
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
    
    [[MCPresetEditPanel editPanel] updatePreview];
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
    if (selectedIndex > 0)
	    [textMethodTabView selectTabViewItemAtIndex:selectedIndex - 1];
	    
    [textMethodTabView setHidden:(selectedIndex == 0)];

    if (sender != nil)
	    [self setFilterOption:sender];
}

- (CGImageRef)newImageWithSize:(NSSize)size
{
    NSMutableDictionary *filterOptions = [self filterOptions];
    NSData *textData = [filterOptions objectForKey:@"Text"];
    
    if (textData != nil)
    {
        NSAttributedString *attrString = [NSUnarchiver unarchiveObjectWithData:textData];

        return [MCCommonMethods newOverlayImageWithObject:attrString withSettings:filterOptions size:size];
    }
    
    return NULL;
}

@end
