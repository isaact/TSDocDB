//
//  TSMutableDictionary.h
//  TSDocDB
//
//  Created by Isaac Tewolde on 11-09-08.
//  Copyright 2011 Ticklespace.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TSMutableDictionary: NSMutableDictionary
-(NSUInteger)removeObjectsWithValue:(NSString *)value;
-(NSUInteger)removeObjectsWithNullValue;
@end
