//
//  TSDBQuery.h
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

#import <Foundation/Foundation.h>
#import "TSDB.h"
@class  TSRowFilterChain;
@interface TSDBQuery : NSObject {
  TSRowFilterChain *filterChain;
  TSDB *db;
  NSMutableString *orderBy;
  NSInteger direction;
}
@property(nonatomic,readonly) TSRowFilterChain *filterChain;
@property(nonatomic,readonly) TSDB *db;
+(TSDBQuery *)TSDBQueryWithFilters:(TSRowFilterChain *)theFilters forDB:(TSDB *)theDB;
-(id)initWithDB:(TSDB *)theDB andFilters:(TSRowFilterChain *)theFilters;
-(NSArray *)doSearchWithLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset;
-(void)doSearchWithLimit:(NSUInteger)resultLimit offset:(NSUInteger)resultOffset andProcessingBlock:(BOOL(^)(id))processingBlock;
-(void)searchForAllWords:(NSString *)words withLimit:(NSUInteger)resultLimit offset:(NSUInteger)resultOffset andProcessingBlock:(BOOL(^)(id))processingBlock;
-(NSInteger)numRows;
-(void)setOrderByStringForColumn:(NSString *)colName isAscending:(BOOL)ascending;
-(void)setOrderByNumericForColumn:(NSString *)colName isAscending:(BOOL)ascending;
@end
