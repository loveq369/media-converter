//
//  MCColorView.h
//  Media Converter (Intel 64-bit)
//
//  Created by Maarten Foukhar on 05/08/2019.
//

#import <Cocoa/Cocoa.h>

IB_DESIGNABLE

/**
 *  A view that allows you to set the background colour, even in Interface Builder
 *
 *  @discussion It doesn't use the layer for setting the background colour for greater compatibility
 */
@interface MCColorView : NSView

/**
 *  The background colour of the view
 */
@property (nonatomic, strong) IBInspectable NSColor *backgroundColor;

@end
