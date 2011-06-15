//
//  TSRowFilterChain.m
//  TSDB
//
//  Created by Isaac Tewolde on 10-07-27.
//  Copyright 2010-2011 Ticklespace.com. All rights reserved.
//

#import "TSRowFilterChain.h"

@implementation TSRowFilterChain

-(id)initWithFilterChain:(NSMutableDictionary *)theFilterChain {
  self = [super init];
  if (self) {
    filterChain = [[NSMutableDictionary alloc] initWithDictionary:theFilterChain];
  }
  return self;
}
-(void) addFilter:(TSRowFilter *)filter withLabel:(NSString *)label{
  if(filterChain == nil)
    filterChain = [[NSMutableDictionary alloc] init];
	[filterChain setObject:filter forKey:label];
}
-(void) removeFilter:(NSString *)filterLabel{
	[filterChain removeObjectForKey:filterLabel];
}
-(void)removeAllFilters{
  [filterChain removeAllObjects];
}
-(TDBQRY *)getQuery:(TCTDB *)db{
  TDBQRY *qry = tctdbqrynew(db);
  for (TSRowFilter *filter in [filterChain allValues]) {
    [filter addToQuery:qry];
  }
  return qry;
}
-(NSArray *)getQueryChain{
  return [filterChain allValues];
}

- (void)dealloc {
	[filterChain release];
	[super dealloc];
}
- (id)copyWithZone:(NSZone *)zone{
  TSRowFilterChain *copy = [[[self class] allocWithZone:zone] initWithFilterChain:filterChain];
  //TSRowFilterChain *copy = [[TSRowFilterChain alloc] initWithFilterChain:filterChain];
  return copy;
}
@end
