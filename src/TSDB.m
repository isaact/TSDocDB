//
//  TSDB.m
//  TSDB
//
//  Created by Isaac Tewolde on 10-06-12.
//  Copyright 2010 Ticklespace.com. All rights reserved.
//

#import "TSDB.h"

//DBManager
#import "TSDBManager.h"

#import "TSRowFilter.h"

//TickleSpace Macros
#import "TSMacros.h"

//TokyoCabinet Stuff
#include "tcutil.h"
#include "tctdb.h"
#include "stdlib.h"
#include "stdbool.h"
#include "stdint.h"

@interface TSDB()

-(TCTDB *)getDB;

//Key Formatting Methods
-(NSString *)makePrimaryRowKey:(NSString *)rowType andRowID:(NSString *)rowID;
-(NSString *)makeRowDefinitionKey:(NSString *)rowType;
-(NSString *)makeRowTypeKey;
-(NSString *)makeRowVersionKey;
-(NSString *)makeRowTextColKey;



//MetaData Methods
-(void)loadRowTypes;

//Utility Methods
+(NSString *)getDBError:(int)ecode;
-(dispatch_queue_t)getQueue;
-(void)postNotificationWithNotificationName:(NSString *)notificationName andData:(id)data;
-(void)adjustQuery:(TDBQRY *)qry withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger) resultOffset;
-(NSArray *)fetchRows:(TDBQRY *)qry;
-(BOOL)indexCol:(NSString *)colName indexType:(NSInteger)colType;
-(BOOL)dbPut:(NSString *)key colVals:(NSDictionary *)colVals;
-(NSDictionary *)dbGet:(NSString *)rowID;
-(BOOL)dbDel:(NSString *)rowID;

- (NSString *)directoryForDB:(NSString *)dbName withPathOrNil:(NSString *)path;
-(NSString *)findOrCreateDirectory:(NSSearchPathDirectory)searchPathDirectory inDomain:(NSSearchPathDomainMask)domainMask appendPathComponent:(NSString *)appendComponent error:(NSError **)errorOut;

-(NSString *)joinStringsFromDictionary:(NSDictionary *)dict andTargetCols:(NSArray *)keys glue:(NSString *)glue;
-(NSString *)joinStrings :(NSArray *)strings glue:(NSString *)glue;
@end

@implementation TSDB
@synthesize dbFilePath;
@dynamic delegate;

#pragma mark -
#pragma mark ------Public Methods-------

#pragma mark Inits & Deallocs
+(id)TSDBWithDBNamed:(NSString *)dbName inDirectoryAtPathOrNil:(NSString*)path delegate:(id<TSDBDefinitionsDelegate>)theDelegate
{
  TSDB *tableDB = [[[TSDB alloc] initWithDBNamed:dbName inDirectoryAtPathOrNil:path delegate:theDelegate] autorelease];
  return tableDB;
  
}
-(id)initWithDBNamed:(NSString *)dbName inDirectoryAtPathOrNil:(NSString*)path delegate:(id<TSDBDefinitionsDelegate>)theDelegate{
  self = [super init];
  if (self != nil) {
    NSString *theDBPath, *theDBDir;
    theDBDir = [self directoryForDB:dbName withPathOrNil:path];
    theDBPath = [NSString stringWithFormat:@"%@/%@.tct", theDBDir, dbName];
/*    if (path == nil) {
      theDBDir = [NSString stringWithFormat:@"%@/%@", [self directoryForDB:dbName], dbName];
      theDBPath = [NSString stringWithFormat:@"%@/%@.tct", theDBDir, dbName];
    }else {
      theDBPath = [NSString stringWithFormat:@"%@/%@/%@.tct", path, dbName,dbName];
      theDBDir = [NSString stringWithFormat:@"%@/%@", path, dbName];
    }*/
    
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isNew = YES;
    if([fm fileExistsAtPath:theDBPath]){
      isNew = NO;
    }
    TSDBManager *dbm = [TSDBManager sharedDBManager];
    TCTDB *tdb = [dbm getDB:theDBPath];
    reuseableTCMap = tcmapnew();
    if(tdb){
      filterChain = [[TSRowFilterChain alloc] init];
      dbFilePath = [theDBPath retain];
      dbNamePrefix = [dbName retain];
      rootDBDir = [theDBDir retain];
      dbQueue = [self getQueue];
      dispatch_retain(dbQueue);
    }else {
      return nil;
    }
    //NSLog(@"%@", theDBPath);
    _delegate = theDelegate;
    if (isNew) {
      [self reindexDB:nil];
    }
  }
  return self;
}
- (void)setDelegate:(id<TSDBDefinitionsDelegate>)aDelegate
{
	_delegate = aDelegate;
  
}
- (void) dealloc
{
  tcmapdel(reuseableTCMap);
  [orderBy release];
  dispatch_release(dbQueue);
  [dbDir release];
  [dbNamePrefix release];
  [rootDBDir release];
  [dbFilePath release];
  [filterChain release];
  [super dealloc];
}
-(void)syncDB{
  TCTDB * tdb = [self getDB];
  tctdbsync(tdb);
  //tctdboptimize(tdb, 600000, -1, -1, -1);
}
#pragma mark DB Management Methods
-(void)reindexDB:(NSString *)rowTypeOrNil{
  dispatch_sync(dbQueue, ^{
    NSArray *rowTypesToIndex = nil;
    if (rowTypeOrNil == nil) {
      rowTypesToIndex = [_delegate TSGetRowTypes];
    }else {
      rowTypesToIndex = [NSArray arrayWithObject:rowTypeOrNil];
    }
    for (NSString *rowType in rowTypesToIndex) {
      NSArray *indexCols = [_delegate TSColumnsForIndexType:TSIndexTypeNumeric];
      for (NSString *colName in indexCols) {
        [self indexCol:colName indexType:TDBITDECIMAL];
      }
      indexCols = [_delegate TSColumnsForIndexType:TSIndexTypeString];
      for (NSString *colName in indexCols) {
        [self indexCol:colName indexType:TDBITLEXICAL];
      }
      
      indexCols = [_delegate TSColumnsForIndexType:TSIndexTypeFullTextColumn];
      for (NSString *colName in indexCols) {
        [self indexCol:colName indexType:TDBITQGRAM];
      }
    }
    [self indexCol:[self makeRowTextColKey] indexType:TDBITQGRAM];
    [self indexCol:[self makeRowTypeKey] indexType:TDBITTOKEN];
  });
}
-(void)reindexRows:(NSString *)rowType{
  NSUInteger offset = 0;
  [self clearFilters];
  NSArray *rows = [self doSearchWithLimit:100 andOffset:offset forRowTypes:rowType,nil];
  NSArray *colKeys = [_delegate TSColumnsForFullTextSearch:rowType];
  NSString *rowTextColKey = [self makeRowTextColKey];
  while ([rows count]) {
    dispatch_sync(dbQueue, ^{
      for (NSMutableDictionary *row in rows) {
        NSString *joinedString = [[self joinStringsFromDictionary:row andTargetCols:colKeys glue:@" "] lowercaseString];
        [row setObject:joinedString forKey:rowTextColKey];
        NSString *rowIDKey = [self makePrimaryRowKey:rowType andRowID:[row objectForKey:[_delegate TSPrimaryColumnForRowType:rowType]]];
        [self dbPut:rowIDKey colVals:row];
      }
    });
    offset+=[rows count];
    rows = [self doSearchWithLimit:100 andOffset:offset forRowTypes:rowType,nil];
  }
}
-(void)optimizeDBWithBnum:(NSInteger)bnum{
  dispatch_sync(dbQueue, ^{
    TCTDB *tdb = [self getDB];
    tctdboptimize(tdb, bnum, -1, -1, TDBTLARGE);
  });
}
-(void)optimizeIndexes:(NSString *)rowTypeOrNil{
  dispatch_sync(dbQueue, ^{
    NSArray *rowTypesToIndex = nil;
    if (rowTypeOrNil == nil) {
      rowTypesToIndex = [_delegate TSGetRowTypes];
    }else {
      rowTypesToIndex = [NSArray arrayWithObject:rowTypeOrNil];
    }
    for (NSString *rowType in rowTypesToIndex) {
      NSArray *indexCols = [_delegate TSColumnsForIndexType:TSIndexTypeNumeric];
      for (NSString *colName in indexCols) {
        [self indexCol:colName indexType:TDBITOPT];
      }
      indexCols = [_delegate TSColumnsForIndexType:TSIndexTypeNumeric];
      for (NSString *colName in indexCols) {
        [self indexCol:colName indexType:TDBITOPT];
      }
      indexCols = [_delegate TSColumnsForIndexType:TSIndexTypeFullTextColumn];
      for (NSString *colName in indexCols) {
        [self indexCol:colName indexType:TDBITOPT];
      }
    }
    [self indexCol:[self makeRowTextColKey] indexType:TDBITOPT];
    [self indexCol:[self makeRowTypeKey] indexType:TDBITOPT];
    //TCTDB *tdb = [self getDB];
    //tctdbtune(tdb, 5000000, -1, -1, TDBTLARGE);
  });
}

-(void)resetDB{
  dispatch_sync(dbQueue, ^{
    TSDBManager *dbm = [TSDBManager sharedDBManager];
    [dbm removeDBFileAtPath:dbFilePath];
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:rootDBDir error:NULL];
    [self directoryForDB:dbNamePrefix withPathOrNil:dbDir];
    [dbm getDB:dbFilePath];
  });
  [self reindexDB:nil];
    //return [dbm getDB:dbFilePath];
}
-(void)reopenDB{
  dispatch_sync(dbQueue, ^{
    TSDBManager *dbm = [TSDBManager sharedDBManager];
    [dbm recyleDBAtPath:dbFilePath];
  });
}
-(void)replaceRow:(NSString *)rowID withRowType:(NSString *)rowType andRowData:(NSDictionary *)rowData{
  dispatch_sync(dbQueue, ^{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    NSString *realRowID = [self makePrimaryRowKey:rowType andRowID:rowID];
    //NSLog(@"%@", rowData);
    NSMutableDictionary *tmpData = [NSMutableDictionary dictionaryWithDictionary:rowData];
    [tmpData setObject:rowType forKey:[self makeRowTypeKey]];
    NSArray *colKeys = [_delegate TSColumnsForFullTextSearch:rowType];
    NSString *joinedString = [[self joinStringsFromDictionary:rowData andTargetCols:colKeys glue:@" "] lowercaseString];
    [tmpData setObject:joinedString forKey:[self makeRowTextColKey]];
    //ALog(@"Saving Doc: %@", realRowID);
    [self dbPut:realRowID colVals:tmpData];
    [pool drain];
  });
}

-(NSDictionary *)getRowByStringID:(NSString *)rowID forType:(NSString *)rowType{
  __block NSDictionary *row;
  dispatch_sync(dbQueue, ^{
    NSString *realRowID = [self makePrimaryRowKey:rowType andRowID:rowID];
    row = [self dbGet:realRowID];
  });
  return row;
}
-(NSDictionary *)getRowByIntegerID:(NSInteger)rowID forType:(NSString *)rowType{
  NSString *stringRowID = [NSString stringWithFormat:@"%d", rowID];
  return [self getRowByStringID:stringRowID forType:rowType];
}
-(BOOL)deleteRow:(NSString *)rowID{
  __block BOOL success;
  dispatch_sync(dbQueue, ^{
    success= [self dbDel:rowID];
  });
  return success;
}

#pragma mark -
#pragma mark Ordering Methods
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

#pragma mark -
#pragma mark Filtering Methods
//Filtering Methods
-(void)clearFilters{
}


#pragma mark String Filters
-(void)addConditionBeginsWithString:(NSString *)string toColumn:(NSString *)colName{
  TSRowFilter *filter = [[TSRowFilter alloc] initStringFilter:colName withOp:beginsWith andVal:string];
  [filterChain addFilter:filter withLabel:[filter getFilterSig]];
  [filter release];
}
-(void)addConditionEndsWithString:(NSString *)string toColumn:(NSString *)colName{
  TSRowFilter *filter = [[TSRowFilter alloc] initStringFilter:colName withOp:endsWith andVal:string];
  [filterChain addFilter:filter withLabel:[filter getFilterSig]];
  [filter release];
}
-(void)addConditionContainsAllWordsInString:(NSString *)words toColumn:(NSString *)colName{
  TSRowFilter *filter = [[TSRowFilter alloc] initStringFilter:colName withOp:contains andVal:words];
  [filterChain addFilter:filter withLabel:[filter getFilterSig]];
  [filter release];
}
-(void)addConditionContainsAnyWordInString:(NSString *)words toColumn:(NSString *)colName{
  TSRowFilter *filter = [[TSRowFilter alloc] initStringFilter:colName withOp:anyword andVal:words];
  [filterChain addFilter:filter withLabel:[filter getFilterSig]];
  [filter release];
}
-(void)addConditionContainsPhrase:(NSString *)thePhrase toColumn:(NSString *)colName{
  TSRowFilter *filter = [[TSRowFilter alloc] initStringFilter:colName withOp:phrase andVal:thePhrase];
  [filterChain addFilter:filter withLabel:[filter getFilterSig]];
  [filter release];
  
}
-(void)addConditionStringEquals:(NSString *)value toColumn:(NSString *)colName{
  TSRowFilter *filter = [[TSRowFilter alloc] initStringFilter:colName withOp:eq andVal:value];
  [filterChain addFilter:filter withLabel:[filter getFilterSig]];
  [filter release];
}
-(void)addConditionStringInSet:(NSArray *)values toColumn:(NSString *)colName{
  if(values != nil){
    TSRowFilter *filter = nil;
    if([[values objectAtIndex:0] isKindOfClass:[NSNumber class]]){
      filter = [[TSRowFilter alloc] initNumericFilter:colName withOp:eq andVal:values];
    } else {
      filter = [[TSRowFilter alloc] initStringFilter:colName withOp:eq andVal:values];
    }
    [filterChain addFilter:filter withLabel:[filter getFilterSig]];
    [filter release];
  }
}

#pragma mark Row Filter
-(void)addConditionRowContainsString:(NSString *)text{
  [self addConditionContainsAllWordsInString:text toColumn:@"_TSDB.TXT"];
}

#pragma mark Numeric Filters
-(void)addConditionNumIsLessThan:(id)colVal toColumn:(NSString *)colName{
  if ([colVal isKindOfClass:[NSString class]] || [colVal isKindOfClass:[NSNumber class]]) {
    TSRowFilter *filter = [[TSRowFilter alloc] initNumericFilter:colName withOp:lt andVal:colVal];
    [filterChain addFilter:filter withLabel:[filter getFilterSig]];
    [filter release];
  }
}
-(void)addConditionNumIsLessThanOrEquals:(id)colVal toColumn:(NSString *)colName{
  if ([colVal isKindOfClass:[NSString class]] || [colVal isKindOfClass:[NSNumber class]]) {
    TSRowFilter *filter = [[TSRowFilter alloc] initNumericFilter:colName withOp:lte andVal:colVal];
    [filterChain addFilter:filter withLabel:[filter getFilterSig]];
    [filter release];
  }
}
-(void)addConditionNumEquals:(id)colVal toColumn:(NSString *)colName{
  if ([colVal isKindOfClass:[NSString class]] || [colVal isKindOfClass:[NSNumber class]]) {
    TSRowFilter *filter = [[TSRowFilter alloc] initNumericFilter:colName withOp:eq andVal:colVal];
    [filterChain addFilter:filter withLabel:[filter getFilterSig]];
    [filter release];
  }
}
-(void)addConditionNumIsGreaterThan:(id)colVal toColumn:(NSString *)colName{
  if ([colVal isKindOfClass:[NSString class]] || [colVal isKindOfClass:[NSNumber class]]) {
    TSRowFilter *filter = [[TSRowFilter alloc] initNumericFilter:colName withOp:gt andVal:colVal];
    [filterChain addFilter:filter withLabel:[filter getFilterSig]];
    [filter release];
  }
}
-(void)addConditionNumIsGreaterThanOrEquals:(id)colVal toColumn:(NSString *)colName{
  if ([colVal isKindOfClass:[NSString class]] || [colVal isKindOfClass:[NSNumber class]]) {
    TSRowFilter *filter = [[TSRowFilter alloc] initNumericFilter:colName withOp:gte andVal:colVal];
    [filterChain addFilter:filter withLabel:[filter getFilterSig]];
    [filter release];
  }
}

#pragma mark Convenient Search Methods
-(NSUInteger)getNumRowsOfType:(NSString *)rowTypeOrNil{
  __block NSUInteger numRows;
  dispatch_sync(dbQueue, ^{
    TCTDB *tdb = [self getDB];
    if (rowTypeOrNil != nil) {
      [self addConditionStringEquals:rowTypeOrNil toColumn:[self makeRowTypeKey]];
    }
    TDBQRY *qry = [filterChain getQuery:tdb];
    TCLIST *res = tctdbqrysearch(qry);  
    numRows = tclistnum(res);
    tclistdel(res);
    tctdbqrydel(qry);
    [filterChain removeAllFilters];
  });
  return numRows;
}
-(NSUInteger)getNumResultsOfRowType:(NSString *)rowTypeOrNil{
  __block NSUInteger numRows;
  dispatch_sync(dbQueue, ^{
    TCTDB *tdb = [self getDB];
    if (rowTypeOrNil != nil) {
      [self addConditionStringEquals:rowTypeOrNil toColumn:[self makeRowTypeKey]];
    }
    TDBQRY *qry = [filterChain getQuery:tdb];
    TCLIST *res = tctdbqrysearch(qry);  
    numRows = tclistnum(res);
    tclistdel(res);
    tctdbqrydel(qry);
    [filterChain removeAllFilters];
  });
  return numRows;
}

-(NSArray *)doSearchWithLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forRowTypes:(NSString *)rowType,...{
  NSMutableArray *rowTypes = [NSMutableArray arrayWithCapacity:1];
  GVargs(rowTypes, rowType, NSString);
  __block NSArray *rows;
  dispatch_sync(dbQueue, ^{
    TCTDB *tdb = [self getDB];
    if ([rowTypes count]) {
      [self addConditionStringInSet:rowTypes toColumn:[self makeRowTypeKey]];
    }
    TDBQRY *qry = [filterChain getQuery:tdb];
    [self adjustQuery:qry withLimit:resultLimit andOffset:resultOffset];
    rows = [self fetchRows:qry];
    tctdbqrydel(qry);
  });
  return rows;
}
-(NSArray *)searchForPhrase:(NSString *)phrase withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forRowTypes:(NSString *)rowType,...{
  NSMutableArray *rowTypes = [NSMutableArray arrayWithCapacity:1];
  GVargs(rowTypes, rowType, NSString);
  return nil;
}
-(NSArray *)searchForAllWords:(NSString *)words withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forRowTypes:(NSString *)rowType,...{
  NSMutableArray *rowTypes = [NSMutableArray arrayWithCapacity:1];
  GVargs(rowTypes, rowType, NSString);
  __block NSArray *rows;
  dispatch_sync(dbQueue, ^{
    TCTDB *tdb = [self getDB];
    if ([rowTypes count]) {
      [self addConditionStringInSet:rowTypes toColumn:[self makeRowTypeKey]];
    }
    [self addConditionRowContainsString:words];
    TDBQRY *qry = [filterChain getQuery:tdb];
    
    [self adjustQuery:qry withLimit:resultLimit andOffset:resultOffset];
    rows = [self fetchRows:qry];
    tctdbqrydel(qry);
  });
  return rows;
}
-(NSArray *)searchForAnyWord:(NSString *)words withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forRowTypes:(NSString *)rowType,...{
  NSMutableArray *rowTypes = [NSMutableArray arrayWithCapacity:1];
  GVargs(rowTypes, rowType, NSString);
  __block NSArray *rows;
  dispatch_sync(dbQueue, ^{
    TCTDB *tdb = [self getDB];
    if ([rowTypes count]) {
      [self addConditionStringInSet:rowTypes toColumn:[self makeRowTypeKey]];
    }
    [self addConditionContainsAnyWordInString:words toColumn:@"_TSDB.TXT"];
    TDBQRY *qry = [filterChain getQuery:tdb];
    
    [self adjustQuery:qry withLimit:resultLimit andOffset:resultOffset];
    rows = [self fetchRows:qry];
    tctdbqrydel(qry);
  });
  return rows;
}
#pragma mark Asynchronous Convenient Search Methods
-(void)getNumRowsWithAsyncNotification:(NSString *)notificationNameOrNil ofRowTypeOrNil:(NSString *)rowType{
  dispatch_queue_t queue;
  queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  __block NSUInteger ret;
  dispatch_async(queue, ^{
    ret = [self getNumRowsOfType:rowType];
    [self postNotificationWithNotificationName:notificationNameOrNil andData:[NSNumber numberWithInt:ret]];
  });
  
}
-(void)doSearchWithAsyncNotification:(NSString *)notificationNameOrNil resultLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forRowTypes:(NSString *)rowType,...{
  NSMutableArray *rowTypes = [NSMutableArray arrayWithCapacity:1];
  GVargs(rowTypes, rowType, NSString);
  dispatch_queue_t queue;
  queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  __block NSArray *ret;
  dispatch_async(queue, ^{
    dispatch_sync(dbQueue, ^{
      TCTDB *tdb = [self getDB];
      if ([rowTypes count]) {
        [self addConditionStringInSet:rowTypes toColumn:[self makeRowTypeKey]];
      }
      TDBQRY *qry = [filterChain getQuery:tdb];
      [self adjustQuery:qry withLimit:resultLimit andOffset:resultOffset];
      ret = [self fetchRows:qry];
      [self postNotificationWithNotificationName:notificationNameOrNil andData:ret];
      tctdbqrydel(qry);
    });
  });
}
-(void)searchForPhraseWithAsyncNotification:(NSString *)notificationNameOrNil forPhrase:(NSString *)thePhrase withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forRowTypes:(NSString *)rowType,...{
  NSMutableArray *rowTypes = [NSMutableArray arrayWithCapacity:1];
  GVargs(rowTypes, rowType, NSString);
  dispatch_queue_t queue;
  queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  __block NSArray *ret;
  dispatch_async(queue, ^{
    dispatch_sync(dbQueue, ^{
      TCTDB *tdb = [self getDB];
      if ([rowTypes count]) {
        [self addConditionStringInSet:rowTypes toColumn:[self makeRowTypeKey]];
      }
      [self addConditionContainsPhrase:thePhrase toColumn:@"_TSDB.TXT"];
      TDBQRY *qry = [filterChain getQuery:tdb];
      
      [self adjustQuery:qry withLimit:resultLimit andOffset:resultOffset];
      ret = [self fetchRows:qry];
      [self postNotificationWithNotificationName:notificationNameOrNil andData:ret];
      tctdbqrydel(qry);
    });
  });
}
-(void)searchForAllWordsWithAsyncNotification:(NSString *)notificationNameOrNil forWords:(NSString *)words withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forRowTypes:(NSString *)rowType,...{
  NSMutableArray *rowTypes = [NSMutableArray arrayWithCapacity:1];
  GVargs(rowTypes, rowType, NSString);
  dispatch_queue_t queue;
  queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  __block NSArray *ret;
  dispatch_async(queue, ^{
    dispatch_sync(dbQueue, ^{
      TCTDB *tdb = [self getDB];
      if ([rowTypes count]) {
        [self addConditionStringInSet:rowTypes toColumn:[self makeRowTypeKey]];
      }
      [self addConditionRowContainsString:words];
      TDBQRY *qry = [filterChain getQuery:tdb];
      
      [self adjustQuery:qry withLimit:resultLimit andOffset:resultOffset];
      ret = [self fetchRows:qry];
      [self postNotificationWithNotificationName:notificationNameOrNil andData:ret];
      tctdbqrydel(qry);
    });
  });
}
-(void)searchForAnyWordWithAsyncNotification:(NSString *)notificationNameOrNil forWords:(NSString *)words withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forRowTypes:(NSString *)rowType,...{
  NSMutableArray *rowTypes = [NSMutableArray arrayWithCapacity:1];
  GVargs(rowTypes, rowType, NSString);
  dispatch_queue_t queue;
  queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  __block NSArray *ret;
  dispatch_async(queue, ^{
    dispatch_sync(dbQueue, ^{
      TCTDB *tdb = [self getDB];
      if ([rowTypes count]) {
        [self addConditionStringInSet:rowTypes toColumn:[self makeRowTypeKey]];
      }
      [self addConditionContainsAnyWordInString:words toColumn:@"_TSDB.TXT"];
      TDBQRY *qry = [filterChain getQuery:tdb];
      
      [self adjustQuery:qry withLimit:resultLimit andOffset:resultOffset];
      ret = [self fetchRows:qry];
      [self postNotificationWithNotificationName:notificationNameOrNil andData:ret];
      tctdbqrydel(qry);
    });
  });
}

#pragma mark -
#pragma mark ------Private Methods-------
#pragma mark Key Formatting Methods
-(NSString *)makePrimaryRowKey:(NSString *)rowType andRowID:(NSString *)rowID{
  return [NSString stringWithFormat:@"_TSDB.DT:%@;_TSDB.DK:%@", rowType, rowID];
}
-(NSString *)makeRowDefinitionKey:(NSString *)rowType{
  return [NSString stringWithFormat:@"_TSDB.DTD:%@", rowType];
}
-(NSString *)makeRowTypeKey{
  return [NSString stringWithFormat:@"_TSDB.DT"];
}
-(NSString *)makeRowVersionKey{
  return [NSString stringWithFormat:@"_TSDB.DTVer"];
}
-(NSString *)makeRowTextColKey{
  return [NSString stringWithFormat:@"_TSDB.TXT"];
}
-(NSString *)joinStringsFromDictionary:(NSDictionary *)dict andTargetCols:(NSArray *)keys glue:(NSString *)glue{
  NSArray *strings = [dict objectsForKeys:keys notFoundMarker:@" "];
  return [self joinStrings:strings glue:glue];
}
-(NSString *)joinStrings :(NSArray *)strings glue:(NSString *)glue{
	NSMutableString *joinedString = [NSMutableString stringWithString:@""];
	NSInteger count = 0;
	for(id string in strings){
		if(count >0){
			[joinedString appendString:glue];
		}
		if([string isKindOfClass:[NSString class]]){
			[joinedString appendString:string];
			count++;
		}		
	}
	return joinedString;
}
#pragma mark MetaData Methods
-(void)loadRowTypes{
}

#pragma mark Utility Methods
-(dispatch_queue_t)getQueue{
  TSDBManager *dbm = [TSDBManager sharedDBManager];
  //return [[NSString stringWithFormat:@"com.ticklespace.tsdocdb.%d", [dbFilePath hash]] UTF8String];
  return [dbm getQueueForDBPath:dbFilePath];
}
-(void)postNotificationWithNotificationName:(NSString *)notificationName andData:(id)data{
  if (notificationName != nil) {
    if (data != nil) {
      NSDictionary *notificationData = [NSDictionary dictionaryWithObject:data forKey:@"data"];
      [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:[NSNotification notificationWithName:notificationName object:nil userInfo:notificationData] waitUntilDone:NO];
    }else {
      [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:[NSNotification notificationWithName:notificationName object:nil userInfo:nil] waitUntilDone:NO];
    }  
    
  }
}
-(TCTDB *)getDB{
  TSDBManager *dbm = [TSDBManager sharedDBManager];
  return [dbm getDB:dbFilePath];
}
-(void)adjustQuery:(TDBQRY *)qry withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger) resultOffset{
  if(orderBy != nil){
    tctdbqrysetorder(qry, [orderBy UTF8String], direction);
    [orderBy release];
    orderBy = nil;
  }
  tctdbqrysetlimit(qry, resultLimit, resultOffset);
}
-(NSArray *)fetchRows:(TDBQRY *)qry{
  NSMutableArray *rows = [NSMutableArray arrayWithCapacity:1];
  TCLIST *res = tctdbqrysearch(qry);  
  const char *rbuf;
  int rsiz, i;
  //NSLog(@"########################num res: %d", tclistnum(res));
  for(i = 0; i < tclistnum(res); i++){
    rbuf = tclistval(res, i, &rsiz);
    [rows addObject:[self dbGet:[NSString stringWithUTF8String:rbuf]]];
  }  
  tclistdel(res);
  [filterChain removeAllFilters];
  return rows;
}
-(BOOL)indexCol:(NSString *)colName indexType:(NSInteger)colType{
  TCTDB *tdb = [self getDB];
  return tctdbsetindex(tdb, [colName UTF8String], colType);
}
-(BOOL)dbPut:(NSString *)rowKey colVals:(NSDictionary *)rowData{
  TCTDB *tdb = [self getDB];
  NSInteger rowKeySize = strlen([rowKey UTF8String]);
  //TCMAP *reuseableTCMap = tcmapnew();
  tcmapclear(reuseableTCMap);
  for (NSString *colKey in [rowData allKeys]) {
    if([[rowData objectForKey:colKey] isKindOfClass:[NSString class]]){
      const char *val = [[rowData objectForKey:colKey] UTF8String];
      if (strlen(val) <= 0) {
        val = " ";
//        tcmapput(cols, [colKey UTF8String], strlen([colKey UTF8String]), [[rowData objectForKey:colKey] UTF8String], strlen([[rowData objectForKey:colKey] UTF8String]));
//      }else {
//        tcmapput(cols, [colKey UTF8String], strlen([colKey UTF8String]), " ", strlen(" "));
      }
      tcmapput2(reuseableTCMap, [colKey UTF8String], val);
    }else if([[rowData objectForKey:colKey] isKindOfClass:[NSNumber class]]){
      tcmapput2(reuseableTCMap, [colKey UTF8String], [[[rowData objectForKey:colKey] stringValue] UTF8String]);
      //tcmapput(cols, [colKey UTF8String], strlen([colKey UTF8String]), [[[rowData objectForKey:colKey] stringValue] UTF8String], strlen([[[rowData objectForKey:colKey] stringValue] UTF8String]));
    } else if ([[rowData objectForKey:colKey] isKindOfClass:[NSArray class]] || [[rowData objectForKey:colKey] isKindOfClass:[NSDictionary class]]) {
      tcmapput2(reuseableTCMap, [colKey UTF8String], [[[rowData objectForKey:colKey] description] UTF8String]);
      //tcmapput(cols, [colKey UTF8String], strlen([colKey UTF8String]), [[[rowData objectForKey:colKey] description] UTF8String], strlen([[[rowData objectForKey:colKey] description] UTF8String]));
    }
    
  }
  //[self dbDel:rowKey];
  if(!tctdbput(tdb, [rowKey UTF8String], rowKeySize, reuseableTCMap)){
    int ecode = tctdbecode(tdb);
    ALog(@"DB put error:%@", [TSDB getDBError:ecode]);
  }
  tcmapclear(reuseableTCMap);
  //tcmapdel(cols);
  
  return NO;
}
-(NSDictionary *)dbGet:(NSString *)rowID{
  TCTDB *tdb = [self getDB];
  NSMutableDictionary *rowData = nil;
  TCMAP *cols = tctdbget(tdb, [rowID UTF8String], strlen([rowID UTF8String]));
  const char *name;
  if(cols){
    tcmapiterinit(cols);
    rowData = [NSMutableDictionary dictionaryWithCapacity:1];;
    while((name = tcmapiternext2(cols)) != NULL){
      [rowData setObject:[NSString stringWithUTF8String:tcmapget2(cols, name)] 
                  forKey:[NSString stringWithUTF8String:name]];
    }
    tcmapdel(cols);
  }  
  return rowData;
}
-(BOOL)dbDel:(NSString *)rowID{
  TCTDB *tdb = [self getDB];
  return tctdbout(tdb, [rowID UTF8String], strlen([rowID UTF8String]));
}
+(NSString *)getDBError:(int)ecode{
  return [NSString stringWithUTF8String:tctdberrmsg(ecode)];
}

- (NSString *)directoryForDB:(NSString *)dbName withPathOrNil:(NSString *)path{
  NSString *result = nil;
  if (path == nil) {
    NSString *executableName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
    NSError *error;
    result =
    [self
     findOrCreateDirectory:NSApplicationSupportDirectory
     inDomain:NSUserDomainMask
     appendPathComponent:[NSString stringWithFormat:@"%@/%@", executableName, dbName]
     error:&error];
    if (error)
    {
      NSLog(@"Unable to find or create application support directory:\n%@", error);
    } 
  }else{
    BOOL success = [[NSFileManager defaultManager]
     createDirectoryAtPath:[NSString stringWithFormat:@"%@/%@", path, dbName]
     withIntermediateDirectories:YES
     attributes:nil
     error:NULL];
    if (success) {
      return [NSString stringWithFormat:@"%@/%@", path, dbName];
    }
  }
  
  return result;
}

- (NSString *)findOrCreateDirectory:(NSSearchPathDirectory)searchPathDirectory inDomain:(NSSearchPathDomainMask)domainMask appendPathComponent:(NSString *)appendComponent error:(NSError **)errorOut{
  // Search for the path
  NSArray* paths = NSSearchPathForDirectoriesInDomains(
                                                       searchPathDirectory,
                                                       domainMask,
                                                       YES);
  if ([paths count] == 0)
  {
    // *** creation and return of error object omitted for space
    return nil;
  }
  
  // Normally only need the first path
  NSString *resolvedPath = [paths objectAtIndex:0];
  
  if (appendComponent)
  {
    resolvedPath = [resolvedPath
                    stringByAppendingPathComponent:appendComponent];
  }
  
  // Check if the path exists
  BOOL exists;
  BOOL isDirectory;
  exists = [[NSFileManager defaultManager]
            fileExistsAtPath:resolvedPath
            isDirectory:&isDirectory];
  if (!exists || !isDirectory)
  {
    if (exists)
    {
      // *** creation and return of error object omitted for space
      return nil;
    }
    
    // Create the path if it doesn't exist
    NSError *error;
    BOOL success = [[NSFileManager defaultManager]
                    createDirectoryAtPath:resolvedPath
                    withIntermediateDirectories:YES
                    attributes:nil
                    error:&error];
    if (!success) 
    {
      if (errorOut)
      {
        *errorOut = error;
      }
      return nil;
    }
  }
  
  if (errorOut)
  {
    *errorOut = nil;
  }
  return resolvedPath;
}


@end
