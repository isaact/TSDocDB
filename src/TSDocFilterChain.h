//
//  TSDocFilterChain.h
//  TSDocDB
//
//  Created by Isaac Tewolde on 10-07-27.
//  Copyright 2010 Ticklespace.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSDocFilter.h"
#include "tcutil.h"
#include "tctdb.h"

@interface TSDocFilterChain : NSObject {
	NSMutableDictionary *filterChain;
}

-(void)addFilter:(TSDocFilter *)filter withLabel:(NSString *)label;
-(void)removeFilter:(NSString *)filterLabel;
-(void)removeAllFilters;
-(NSArray *)getQueryChain;
-(TDBQRY *)getQuery:(TCTDB *)db;
@end
