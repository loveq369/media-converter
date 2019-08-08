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
- (nullable id)objectForKey:(nonnull id)aKey;

/**
 *  Object for key (subscript version)
 *
 *  @param aKey A key
 *
 *  @return An object
 */
- (nullable id)objectForKeyedSubscript:(nonnull id)key;

/**
 *  Objects for key
 *
 *  @param aKey A key
 *
 *  @return An array of objects
 */
- (nonnull id)objectsForKey:(nonnull id)aKey;

/**
 *  Index of object
 
 *  @param anObject An object
 *  @param aKey A key
 */
- (NSInteger)indexOfObject:(nonnull id)aObject forKey:(nonnull id)aKey;

@end

/**
 *  Methods to work with dictionaries in arrays
 */
@interface NSMutableArray (MyExtensions)

/**
 *  Set object
 *
 *  @param anObject An object
 *  @param aKey A key
 */
- (void)setObject:(nullable id)anObject forKey:(nonnull id)aKey;

/**
 *  Set object (subscript version)
 *
 *  @param anObject An object
 *  @param aKey A key
 */
- (void)setObject:(nullable id)obj forKeyedSubscript:(nonnull id <NSCopying>)key;

@end
