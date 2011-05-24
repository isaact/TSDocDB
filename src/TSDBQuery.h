//
//  TSDBQuery.h
//  TSDB
//
//  Created by Isaac Tewolde on 11-05-20.
//  Copyright 2011 Ticklespace.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSDB.h"
@class  TSRowFilterChain;
@interface TSDBQuery : NSObject {
  TSRowFilterChain *filterChain;
  TSDB *db;
}
@property(nonatomic,readonly) TSRowFilterChain *filterChain;
@property(nonatomic,readonly) TSDB *db;
+(TSDBQuery *)TSDBQueryWithFilters:(TSRowFilterChain *)theFilters forDB:(TSDB *)theDB;
-(id)initWithDB:(TSDB *)theDB andFilters:(TSRowFilterChain *)theFilters;
-(NSArray *)doSearchWithLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset;
-(void)doSearchWithLimit:(NSUInteger)resultLimit offset:(NSUInteger)resultOffset andProcessingBlock:(BOOL(^)(id))processingBlock;
-(NSInteger)numRows;
@end
