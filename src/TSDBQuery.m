//
//  TSDBQuery.m
//  TSDB
//
//  Created by Isaac Tewolde on 11-05-20.
//  Copyright 2011 Ticklespace.com. All rights reserved.
//

/************************************************************************ 
 * This file is part of TSDocDB.
 * 
 * TSDocDB is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * TSDocDB is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
 ***********************************************************************/

#import "TSDBQuery.h"

@interface TSDBQuery()
-(void)adjustQuery:(TDBQRY *)qry withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger) resultOffset;
@end

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
  [orderBy release];
  [filterChain release];
  [db release];
  [super dealloc];
}
#pragma mark -
#pragma mark Fetching methods
-(NSArray *)doSearchWithLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset{
  TDBQRY *qry = [db getQueryObjectForFilterChain:filterChain];
  [self adjustQuery:qry withLimit:resultLimit andOffset:resultOffset];
  NSArray *rows= [db doPredifinedSearchWithQuery:qry];
  tctdbqrydel(qry);
  return rows;
}
-(void)doSearchWithLimit:(NSUInteger)resultLimit offset:(NSUInteger)resultOffset andProcessingBlock:(BOOL(^)(id))processingBlock{
  TDBQRY *qry = [db getQueryObjectForFilterChain:filterChain];
  [self adjustQuery:qry withLimit:resultLimit andOffset:resultOffset];
  [db doPredifinedSearchWithQuery:qry andProcessingBlock:processingBlock];
}
-(void)searchForAllWords:(NSString *)words withLimit:(NSUInteger)resultLimit offset:(NSUInteger)resultOffset andProcessingBlock:(BOOL(^)(id))processingBlock{
  TSRowFilterChain *newChain = [filterChain copy];
  TSRowFilter *newFilter = [[[TSRowFilter alloc] initWithAllWordsFilter:words] autorelease];
  [newChain addFilter:newFilter withLabel:@"searchText"];
  TDBQRY *qry = [db getQueryObjectForFilterChain:newChain];
  [newChain release];
  //tctdbqrysetlimit(qry, resultLimit, resultOffset);
  [self adjustQuery:qry withLimit:resultLimit andOffset:resultOffset];
  [db doPredifinedSearchWithQuery:qry andProcessingBlock:processingBlock];
}
-(NSInteger)numRows{
  TDBQRY *qry = [db getQueryObjectForFilterChain:filterChain];
  NSInteger count = [db getRowCountForQuery:qry];
  tctdbqrydel(qry);
  return count;
}

#pragma mark -
#pragma mark Ordering methods
-(void)setOrderByStringForColumn:(NSString *)colName isAscending:(BOOL)ascending{
  if(orderBy == nil)
    orderBy = [[NSMutableString alloc] init];
  [orderBy setString:colName];
  if(ascending){
    direction = TDBQOSTRASC;
  }else {
    direction = TDBQOSTRDESC;
  }
}
-(void)setOrderByNumericForColumn:(NSString *)colName isAscending:(BOOL)ascending{
  if(orderBy == nil)
    orderBy = [[NSMutableString alloc] init];
  [orderBy setString:colName];
  if(ascending){
    direction = TDBQONUMASC;
  }else {
    direction = TDBQONUMDESC;
  }
}
-(void)adjustQuery:(TDBQRY *)qry withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger) resultOffset{
  //NSLog(@"Yoyuoyoyoy %@", orderBy);
  if(orderBy != nil){
    tctdbqrysetorder(qry, [orderBy UTF8String], (int)direction);
    [orderBy release];
    orderBy = nil;
  }
  tctdbqrysetlimit(qry, (int)resultLimit, (int)resultOffset);
}
@end
