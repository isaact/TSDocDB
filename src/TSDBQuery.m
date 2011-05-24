//
//  TSDBQuery.m
//  TSDB
//
//  Created by Isaac Tewolde on 11-05-20.
//  Copyright 2011 Ticklespace.com. All rights reserved.
//

#import "TSDBQuery.h"


@implementation TSDBQuery
@synthesize filterChain, db;
+(TSDBQuery *)TSDBQueryWithFilters:(TSRowFilterChain *)theFilters forDB:(TSDB *)theDB{
  return [[[TSDBQuery alloc] initWithDB:theDB andFilters:theFilters] autorelease];
  
}
-(id)initWithDB:(TSDB *)theDB andFilters:(TSRowFilterChain *)theFilters{
  self = [super init];
  if (self) {
    filterChain = [[theFilters copy] retain];
    db = [theDB retain];
  }
  return self;
}

- (void)dealloc
{
  [filterChain release];
  [db release];
  [super dealloc];
}
#pragma mark -
#pragma mark Fetching methods
-(NSArray *)doSearchWithLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset{
  TDBQRY *qry = [db getQueryObjectForFilterChain:filterChain];
  tctdbqrysetlimit(qry, resultLimit, resultOffset);
  NSArray *rows= [db doPredifinedSearchWithQuery:qry];
  tctdbqrydel(qry);
  return rows;
}
-(void)doSearchWithLimit:(NSUInteger)resultLimit offset:(NSUInteger)resultOffset andProcessingBlock:(BOOL(^)(id))processingBlock{
  TDBQRY *qry = [db getQueryObjectForFilterChain:filterChain];
  tctdbqrysetlimit(qry, resultLimit, resultOffset);
  [db doPredifinedSearchWithQuery:qry andProcessingBlock:processingBlock];
}
-(NSInteger)numRows{
  TDBQRY *qry = [db getQueryObjectForFilterChain:filterChain];
  NSInteger count = [db getRowCountForQuery:qry];
  tctdbqrydel(qry);
  return count;
}
@end
