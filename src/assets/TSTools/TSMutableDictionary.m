//
//  TSMutableDictionary.m
//  TSDocDB
//
//  Created by Isaac Tewolde on 11-09-08.
//  Copyright 2011 Ticklespace.com. All rights reserved.
//

#import "TSMutableDictionary.h"
@implementation TSMutableDictionary

-(NSUInteger)removeObjectsWithValue:(NSString *)value{
  NSUInteger count = 0;
  for (NSString *key in [self allKeys]) {
    if ([[self objectForKey:key] isEqualToString:value]) {
      [self removeObjectForKey:key];
      count++;
    }
  }
  return count;
}
-(NSUInteger)removeObjectsWithNullValue{
  NSUInteger count = 0;
  for (NSString *key in [self allKeys]) {
    if ([self objectForKey:key] == [NSNull null]) {
      [self removeObjectForKey:key];
      count++;
    }
  }
  return count;
}
@end
