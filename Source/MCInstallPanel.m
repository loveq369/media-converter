//
//  MCInstallPanel.m
//  Media Converter
//
//  Created by Maarten Foukhar on 08-05-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import "MCInstallPanel.h"
#import "MCCommonMethods.h"

@interface MCInstallPanel()

@property (nonatomic, weak) IBOutlet NSPanel *installModePanel;
@property (nonatomic, weak) IBOutlet NSPopUpButton *installModePopup;
@property (nonatomic, weak) IBOutlet NSButton *suppressButton;
@property (nonatomic, weak) IBOutlet NSTextField *taskField;

@end

@implementation MCInstallPanel

- (instancetype)init
{
    self = [super init];
    
    if (self != nil)
    {
        [[NSBundle mainBundle] loadNibNamed:@"MCInstallPanel" owner:self topLevelObjects:nil];
    }

    return self;
}

+ (MCInstallPanel *)installPanel
{
    static MCInstallPanel *installPanel = nil;
    static dispatch_once_t onceToken = 0;

    dispatch_once(&onceToken, ^
    {
        installPanel = [[MCInstallPanel alloc] init];
    });
    
    return installPanel;
}

- (NSString *)runModalForInstallLocation
{
    NSInteger installMode = [[[NSUserDefaults standardUserDefaults] objectForKey:@"MCInstallMode"] integerValue];
	    
    if (installMode == 0)
    {
        NSPanel *installModePanel = [self installModePanel];
	    [NSApp runModalForWindow:installModePanel];
	    [installModePanel orderOut:self];
	    	    
	    installMode = [[self installModePopup] indexOfSelectedItem] + 1;
    }
    	    
    if (installMode == 1)
    {
	    return @"/Library/Application Support";
    }
    else
    {
	    return [@"~/Library/Application Support" stringByExpandingTildeInPath];
    }
}

- (NSString *)taskText
{
    return [[self taskField] stringValue];
}

- (void)setTaskText:(NSString *)text
{
    [[self taskField] setStringValue:[text copy]];
}

//////////////////////////
// Install Mode actions //
//////////////////////////

#pragma mark -
#pragma mark •• Install Mode actions

- (IBAction)endSettingMode:(id)sender
{
    NSButton *suppressButton = [self suppressButton];
    if ([suppressButton state] == NSOnState)
    {
	    NSInteger mode = [[self installModePopup] indexOfSelectedItem] + 1;
	    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:mode] forKey:@"MCInstallMode"];
	    [[NSNotificationCenter defaultCenter] postNotificationName:@"MCInstallModeChanged" object:@(mode)];
	    [suppressButton setState:NSOffState];
    }

    [NSApp abortModal];
}

@end
