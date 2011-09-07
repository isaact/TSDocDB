//
//  TSRowFilter.h
//  TSDB
//
//  Created by Isaac Tewolde on 10-07-27.
//  Copyright 2010-2011 Ticklespace.com. All rights reserved.
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
#include "tcutil.h"
#include "tctdb.h"

typedef enum {
  eq,gt,lt,gte,lte,ne,beginsWith,endsWith,contains,anyword,phrase
} OpType;

typedef enum {
  matchAll, matchAny
} MatchType;

typedef enum {
  numericFilter, stringFilter
} FilterType;

@interface TSRowFilter : NSObject<NSCopying> {
  NSString *colName;
  OpType op;
  NSMutableSet *valSet;
  MatchType matchType;
  FilterType filterType;
}

@property(nonatomic,retain) NSString *colName;
@property(nonatomic,readwrite) OpType op;
@property(nonatomic,readwrite) FilterType filterType;
@property(nonatomic,readwrite) MatchType matchType;

+(NSString *)makePrimaryRowKey:(NSString *)rowType andRowID:(NSString *)rowID;
+(NSString *)makeRowDefinitionKey:(NSString *)rowType;
+(NSString *)makeRowTypeKey;
+(NSString *)makeOriginalDataKey;
+(NSString *)makeRowVersionKey;
+(NSString *)makeRowTextColKey;



- (id)initWithColname:(NSString *)theColName op:(OpType)theOpType valueSet:(NSSet *)theValSet matchType:(MatchType)theMatchType andFilterType:(FilterType)theFilterType;
- (id)initStringFilter:(NSString *)columName withOp:(OpType)opType andVal:(id)val;
- (id)initWithAllWordsFilter:(NSString *)words;
- (id)initWithPhraseFilter:(NSString *)words;
- (id)initWithAnyWordsFilter:(NSString *)words;

-(id)initNumericFilter:(NSString *)columName withOp:(OpType)opType andVal:(id)val;
-(NSString *)getVal;
-(NSArray *)getVals;
-(void)setVal:(id)val;
-(void)addToQuery:(TDBQRY *)qry;
-(NSString *)getFilterSig;
@end
