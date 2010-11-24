//
//  TSDocFilter.m
//  TSDocDB
//
//  Created by Isaac Tewolde on 10-07-27.
//  Copyright 2010 Ticklespace.com. All rights reserved.
//

#import "TSDocFilter.h"


@implementation TSDocFilter
@synthesize colName, op, matchType, filterType;


-(id)initStringFilter:(NSString *)columName withOp:(OpType)opType andVal:(id)val{
  self = [super init];
  if (self != nil) {
    matchType = matchAll;
    filterType = stringFilter;
    valSet = [[NSMutableSet alloc] init];
    colName = columName;
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
    colName = columName;
    op = opType;
    [self setVal:val];
  }
  return self;
}

- (void) dealloc
{
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
  NSLog(@"%@", str);
  tctdbqryaddcond(qry, [colName UTF8String], qop, [str UTF8String]);
  [str release];
}
-(NSString *)getFilterSig{
  NSUInteger hashVal = [[NSString stringWithFormat:@"_tcf:%@_tcf:%d_tcf:%@",colName, op, [valSet description]] hash];
  return [NSString stringWithFormat:@"%d", hashVal];
}
@end
