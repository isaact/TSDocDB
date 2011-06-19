//
//  TSRowFilter.m
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

#import "TSRowFilter.h"


@implementation TSRowFilter
@synthesize colName, op, matchType, filterType;
#pragma mark Class methods
+(NSString *)makePrimaryRowKey:(NSString *)rowType andRowID:(NSString *)rowID{
  return [NSString stringWithFormat:@"_TSDB.DT:%@;_TSDB.DK:%@", rowType, rowID];
}
+(NSString *)makeRowDefinitionKey:(NSString *)rowType{
  return [NSString stringWithFormat:@"_TSDB.DTD:%@", rowType];
}
+(NSString *)makeRowTypeKey{
  return [NSString stringWithFormat:@"_TSDB.DT"];
}
+(NSString *)makeRowVersionKey{
  return [NSString stringWithFormat:@"_TSDB.DTVer"];
}
+(NSString *)makeRowTextColKey{
  return [NSString stringWithFormat:@"_TSDB.TXT"];
}

- (id)initWithColname:(NSString *)theColName op:(OpType)theOpType valueSet:(NSSet *)theValSet matchType:(MatchType)theMatchType andFilterType:(FilterType)theFilterType{
  self = [super init];
  if (self) {
    colName = [theColName copy];
    op = theOpType;
    valSet = [theValSet copy];
    matchType = theMatchType;
    filterType = theFilterType;
  }
  return self;
}
- (id)copyWithZone:(NSZone *)zone{
  TSRowFilter *copy = [[[self class] allocWithZone:zone] initWithColname:colName op:op valueSet:valSet matchType:matchType andFilterType:filterType];
  //TSRowFilterChain *copy = [[TSRowFilterChain alloc] initWithFilterChain:filterChain];
  return copy;
}
-(id)initStringFilter:(NSString *)columName withOp:(OpType)opType andVal:(id)val{
  self = [super init];
  if (self != nil) {
    matchType = matchAll;
    filterType = stringFilter;
    valSet = [[NSMutableSet alloc] init];
    colName = [columName copy];
    op = opType;
    [self setVal:val];
  }
  return self;
}

-(id)initNumericFilter:(NSString *)columName withOp:(OpType)opType andVal:(id)val{
  self = [super init];
  if (self != nil) {
    matchType = matchAll;
    filterType = numericFilter;
    valSet = [[NSMutableSet alloc] init];
    colName = [columName copy];
    op = opType;
    [self setVal:val];
  }
  return self;
}
- (id)initWithAllWordsFilter:(NSString *)words{
  self = [super init];
  if (self != nil) {
    matchType = matchAll;
    filterType = stringFilter;
    valSet = [[NSMutableSet alloc] init];
    colName = [[TSRowFilter makeRowTextColKey] retain];
    op = contains;
    [self setVal:words];
  }
  return self;
}
- (id)initWithPhraseFilter:(NSString *)words{
  return nil;
}
- (id)initWithAnyWordsFilter:(NSString *)words{
  return nil;
}

- (void) dealloc
{
  [colName release];
  [valSet release];
  [super dealloc];
}

-(NSString *)getVal{
  if([valSet count])
    return [valSet anyObject];
  return nil;
}
-(NSArray *)getVals{
  if([valSet count])
    return [valSet allObjects];
  return nil;
}
-(void)setVal:(id)val{
  [valSet removeAllObjects];
  if ([val isKindOfClass:[NSArray class]]) {
    [valSet addObjectsFromArray:val];
  }else if ([val isKindOfClass:[NSNumber class]]) {
    [valSet addObject:[val stringValue]];
  }else {
    [valSet addObject:val];
  }
  
  
}
-(void)addToQuery:(TDBQRY *)qry{
  int qop;
  if(filterType == numericFilter){
    switch (op) {
      case ne:
        qop = TDBQCNEGATE|TDBQCNUMEQ;
        break;
      case lte:
        qop = TDBQCNUMLE;
        break;
      case lt:
        qop = TDBQCNUMLT;
        break;
      case gte:
        qop = TDBQCNUMGE;
        break;
      case gt:
        qop = TDBQCNUMGT;
        break;
      default:
        if([valSet count] > 1){
          qop = TDBQCNUMOREQ;
        }else {
          qop = TDBQCNUMEQ;
        }
    }
  }else {
    switch (op) {
      case ne:
        qop = TDBQCNEGATE|TDBQCSTREQ;
        break;
      case beginsWith:
        qop = TDBQCSTRBW;
        break;
      case endsWith:
        qop = TDBQCSTREW;
        break;
      case contains:
        qop = TDBQCFTSAND;
        break;
      case anyword:
        qop = TDBQCFTSOR;
        break;
      case phrase:
        qop = TDBQCFTSPH;
        break;
      default:
        if([valSet count] > 1){
          qop = TDBQCSTROREQ;
        }else {
          qop = TDBQCSTREQ;
        }
    }
  }
  NSMutableString *str = [[NSMutableString alloc] init];
  NSInteger count = 0;
  NSString *strVal;
  for (id val in [valSet allObjects]) {
    if(![val isKindOfClass:[NSString class]]){
      strVal = [val stringValue];
    }else{
      strVal = val;
    }
    if(!count){
      [str appendString:strVal];
    }else{
      [str appendFormat:@",%@", strVal];
    }
    count++;
  }
  //NSLog(@"#######Looking for %@: %@", colName, str);
  tctdbqryaddcond(qry, [colName UTF8String], qop, [str UTF8String]);
  [str release];
}
-(NSString *)getFilterSig{
  NSUInteger hashVal = [[NSString stringWithFormat:@"_tcf:%@_tcf:%d_tcf:%@",colName, op, [valSet description]] hash];
  return [NSString stringWithFormat:@"%d", hashVal];
}
@end
