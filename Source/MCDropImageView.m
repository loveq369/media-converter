//
//  MCImageView.m
//  Media Converter
//
//  Created by Maarten Foukhar on 07-08-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import "MCDropImageView.h"
#import "MCCommonMethods.h"
#import "MCWatermarkFilter.h"

@implementation MCDropImageView

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    return NSDragOperationGeneric;
}



- (void)draggingExited:(id <NSDraggingInfo>)sender
{
}


- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *paste = [sender draggingPasteboard];
    NSArray *types = [NSArray arrayWithObjects:NSTIFFPboardType, NSFilenamesPboardType, nil];
    NSString *desiredType = [paste availableTypeFromArray:types];
    NSData *carriedData = [paste dataForType:desiredType];
    
    if (nil == carriedData)
    {
        return NO;
    }
    else
    {
        if ([desiredType isEqualToString:NSTIFFPboardType])
        {
    	    NSImage *newImage = [[NSImage alloc] initWithData:carriedData];
            [[self delegate] dropImageView:self didDropImage:newImage withIdentifier:NSLocalizedString(@"Clipboard Image", nil)];
        }
        else if ([desiredType isEqualToString:NSFilenamesPboardType])
        {
            NSArray *fileArray = [paste propertyListForType:@"NSFilenamesPboardType"];

            NSString *path = [fileArray objectAtIndex:0];
    	    NSString *identifier = [[NSFileManager defaultManager] displayNameAtPath:path];
            NSImage *newImage = [[NSImage alloc] initWithContentsOfFile:path];
    	    
            if (newImage == nil)
            {
                return NO;
            }
            else
            {
                [[self delegate] dropImageView:self didDropImage:newImage withIdentifier:identifier];
            }
        }
    }
    
    return YES;
}

@end
