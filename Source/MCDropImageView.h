//
//  MCImageView.h
//  Media Converter
//
//  Created by Maarten Foukhar on 07-08-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MCDropImageView;

/**
 *  Drop image view delegate, gets notified about dropped images
 */
@protocol MCDropImageViewDelegate <NSObject>

/**
 *  An image or image file has been dropped on the view
 *
 *  @param dropImageView The drop image view
 *  @param image The image
 *  @param identifier An identifier
 */
- (void)dropImageView:(MCDropImageView *)dropImageView didDropImage:(NSImage *)image withIdentifier:(NSString *)identifier;

@end

/**
 *  An image view that allows the user to drop images and image files
 */
@interface MCDropImageView : NSImageView

/**
 *  A delegate that gets notified about dropped images
 */
@property (nonatomic, assign) IBOutlet id <MCDropImageViewDelegate> delegate;

@end
