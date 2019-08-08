//
//  NSArray_Extensions.h
//  Media Converter
//
//  Created by Maarten Foukhar on 22-02-11.
//  Copyright 2011 Kiwi Fruitware. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 *  Methods to work with dictionaries in arrays
 */
@interface NSArray (MyExtensions)


/**
 *  Object for key
 *
 *  @param aKey A key
 *
 *  @return An object
 */
- (id)objectForKey:(id)aKey;

/**
 *  Objects for key
 *
 *  @param aKey A key
 *
 *  @return An array of objects
 */
- (id)objectsForKey:(id)aKey;

/**
 *  Index of object
 
 *  @param anObject An object
 *  @param aKey A key
 */
- (NSInteger)indexOfObject:(id)aObject forKey:(id)aKey;

@end

/**
 *  Methods to work with dictionaries in arrays
 */
@interface NSMutableArray (MyExtensions)

/**
 *  Set object
 
 *  @param anObject An object
 *  @param aKey A key
 */
- (void)setObject:(id)anObject forKey:(id)aKey;

@end
