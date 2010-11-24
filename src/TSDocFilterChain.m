//
//  TSDocFilterChain.m
//  Get2Human
//
//  Created by Isaac Tewolde on 10-07-27.
//  Copyright 2010 Ticklespace.com. All rights reserved.
//

#import "TSDocFilterChain.h"

@implementation TSDocFilterChain

-(void) addFilter:(TSDocFilter *)filter withLabel:(NSString *)label{
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
  for (TSDocFilter *filter in [filterChain allValues]) {
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

@end
