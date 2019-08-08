//
//  MCAddPresetCellView.h
//  Media Converter
//
//  Created by Maarten Foukhar on 07/08/2019.
//

#import <Cocoa/Cocoa.h>

/**
 *  A table cell view that's used when adding presets
 */
@interface MCAddPresetCellView : NSTableCellView

/**
 *  A sub text field, below the main one
 */
@property (nonatomic, weak) IBOutlet NSTextField *subTextField;

@end
