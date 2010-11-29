//
//  TSDocDB.m
//  TSDocDB
//
//  Created by Isaac Tewolde on 10-06-12.
//  Copyright 2010 Ticklespace.com. All rights reserved.
//

#import "TSDocDB.h"

//DocDBManager
#import "TSDocDBManager.h"

//DocDB Libs
#import "TSDocFilter.h"

//TickleSpace Macros
#import "TSMacros.h"

//TokyoCabinet Stuff
#include "tcutil.h"
#include "tctdb.h"
#include "stdlib.h"
#include "stdbool.h"
#include "stdint.h"

@interface TSDocDB()

-(TCTDB *)getDB;

//Key Formatting Methods
-(NSString *)makePrimaryDocKey:(NSString *)docType andDocID:(NSString *)docID;
-(NSString *)makeDocDefinitionKey:(NSString *)docType;
-(NSString *)makeDocTypeKey;
-(NSString *)makeDocVersionKey;
-(NSString *)makeDocTextColKey;


//MetaData Methods
-(void)loadDocTypes;

//Utility Methods
+(NSString *)getDBError:(int)ecode;
-(char *)getQueueSig;
-(void)postNotificationWithNotificationName:(NSString *)notificationName andData:(id)data;
-(void)adjustQuery:(TDBQRY *)qry withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger) resultOffset;
-(NSArray *)fetchRows:(TDBQRY *)qry;
-(BOOL)indexCol:(NSString *)colName indexType:(NSInteger)colType;
-(BOOL)dbPut:(NSString *)key colVals:(NSDictionary *)colVals;
-(NSDictionary *)dbGet:(NSString *)docID;
-(BOOL)dbDel:(NSString *)docID;

-(NSString *)directoryForDB:(NSString *)dbName;
-(NSString *)findOrCreateDirectory:(NSSearchPathDirectory)searchPathDirectory inDomain:(NSSearchPathDomainMask)domainMask appendPathComponent:(NSString *)appendComponent error:(NSError **)errorOut;

-(NSString *)joinStringsFromDictionary:(NSDictionary *)dict andTargetCols:(NSArray *)keys glue:(NSString *)glue;
-(NSString *)joinStrings :(NSArray *)strings glue:(NSString *)glue;
@end

@implementation TSDocDB
@synthesize dbFilePath;
@dynamic delegate;

#pragma mark -
#pragma mark ------Public Methods-------

#pragma mark Inits & Deallocs
/*
-(id)initWithDB:(NSString *)dbPath{
  self = [super init];
  if (self != nil) {
    TSDocDBManager *dbm = [TSDocDBManager sharedDBManager];
    TCTDB *tdb = [dbm getDB:dbPath];
    if(tdb){
      filterChain = [[TSDocFilterChain alloc] init];
      dbFilePath = dbPath;
    }else {
      return nil;
    }

    
  }
  return self;
}
*/

+(id)TSDocDBWithDBNamed:(NSString *)dbName inDirectoryAtPathOrNil:(NSString*)path delegate:(id<TSDocDBDefinitionsDelegate>)theDelegate
{
  TSDocDB *docDB = [TSDocDB alloc];
  [docDB initWithDBNamed:dbName inDirectoryAtPathOrNil:path delegate:theDelegate];
  return docDB;
  
}
-(id)initWithDBNamed:(NSString *)dbName inDirectoryAtPathOrNil:(NSString*)path delegate:(id<TSDocDBDefinitionsDelegate>)theDelegate{
  self = [super init];
  if (self != nil) {
    NSString *dbPath;
    if (path == nil) {
      dbPath = [NSString stringWithFormat:@"%@/%@.tct", [self directoryForDB:dbName], dbName];
    }else {
      dbPath = [NSString stringWithFormat:@"%@/%@.tct", path, dbName];
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isNew = YES;
    if([fm fileExistsAtPath:dbPath]){
      isNew = NO;
    }
    TSDocDBManager *dbm = [TSDocDBManager sharedDBManager];
    TCTDB *tdb = [dbm getDB:dbPath];
    if(tdb){
      filterChain = [[TSDocFilterChain alloc] init];
      dbFilePath = [dbPath retain];
      if (isNew) {
        [self reindexDocs:nil];
      }
    }else {
      return nil;
    }
    NSLog(@"%@", dbPath);
    _delegate = theDelegate;
  }
  return self;
}

- (void)setDelegate:(id<TSDocDBDefinitionsDelegate>)aDelegate
{
	_delegate = aDelegate;

}
- (void) dealloc
{
  [orderBy release];
  //[docTypeDefs release];
  [dbFilePath release];
  [filterChain release];
  [super dealloc];
}
-(void)syncDB{
  TCTDB * tdb = [self getDB];
  tctdbsync(tdb);
  //tctdboptimize(tdb, 600000, -1, -1, -1);
}
#pragma mark Doc Management Methods
-(void)reindexDocs:(NSString *)docTypeOrNil{
  NSArray *docTypesToIndex = nil;
  if (docTypeOrNil == nil) {
    docTypesToIndex = [_delegate getDocTypes];
  }else {
    docTypesToIndex = [NSArray arrayWithObject:docTypeOrNil];
  }
  for (NSString *docType in docTypesToIndex) {
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
  [self indexCol:[self makeDocTextColKey] indexType:TDBITQGRAM];
  [self indexCol:[self makeDocTypeKey] indexType:TDBITTOKEN];
  //TCTDB *tdb = [self getDB];
  //tctdbtune(tdb, 6000000, 8, 20, TDBTLARGE);
  //[self optimizeIndexes:nil];
  //[self syncDB];
}
-(void)optimizeDB{
  TCTDB *tdb = [self getDB];
  tctdboptimize(tdb, -1, -1, -1, TDBTLARGE);
}
-(void)optimizeIndexes:(NSString *)docTypeOrNil{
  NSArray *docTypesToIndex = nil;
  if (docTypeOrNil == nil) {
    docTypesToIndex = [_delegate getDocTypes];
  }else {
    docTypesToIndex = [NSArray arrayWithObject:docTypeOrNil];
  }
  for (NSString *docType in docTypesToIndex) {
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
  [self indexCol:[self makeDocTextColKey] indexType:TDBITOPT];
  [self indexCol:[self makeDocTypeKey] indexType:TDBITOPT];
  //TCTDB *tdb = [self getDB];
  //tctdbtune(tdb, 5000000, -1, -1, TDBTLARGE);
}
-(void)reopenDB{
  TSDocDBManager *dbm = [TSDocDBManager sharedDBManager];
  [dbm recyleDBAtPath:dbFilePath];
}
-(void)saveDoc:(NSString *)docID withDocType:(NSString *)docType andDocData:(NSDictionary *)docData{
  NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
  NSString *realDocID = [self makePrimaryDocKey:docType andDocID:docID];
  //NSLog(@"%@", docData);
  NSMutableDictionary *tmpData = [NSMutableDictionary dictionaryWithDictionary:docData];
  [tmpData setObject:docType forKey:[self makeDocTypeKey]];
  NSArray *colKeys = [_delegate TSColumnsFullTextDocumentSearch:docType];
  NSString *joinedString = [[self joinStringsFromDictionary:docData andTargetCols:colKeys glue:@" "] lowercaseString];
  [tmpData setObject:joinedString forKey:[self makeDocTextColKey]];
  //ALog(@"Saving Doc: %@", realDocID);
  [self dbPut:realDocID colVals:tmpData];
  [pool release];
}

-(NSDictionary *)getDocWithStringID:(NSString *)docID forType:(NSString *)docType{
  NSString *realDocID = [self makePrimaryDocKey:docType andDocID:docID];
  NSDictionary *doc = [self dbGet:realDocID];
  return doc;
}
-(NSDictionary *)getDocWithIntegerID:(NSInteger)docID forType:(NSString *)docType{
  NSString *stringDocID = [NSString stringWithFormat:@"%d", docID];
  return [self getDocWithStringID:stringDocID forType:docType];
}
-(BOOL)deleteDoc:(NSString *)docID{
  return [self dbDel:docID];
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
  TSDocFilter *filter = [[TSDocFilter alloc] initStringFilter:colName withOp:beginsWith andVal:string];
  [filterChain addFilter:filter withLabel:[filter getFilterSig]];
  [filter release];
}
-(void)addConditionEndsWithString:(NSString *)string toColumn:(NSString *)colName{
  TSDocFilter *filter = [[TSDocFilter alloc] initStringFilter:colName withOp:endsWith andVal:string];
  [filterChain addFilter:filter withLabel:[filter getFilterSig]];
  [filter release];
}
-(void)addConditionContainsAllWordsInString:(NSString *)words toColumn:(NSString *)colName{
  TSDocFilter *filter = [[TSDocFilter alloc] initStringFilter:colName withOp:contains andVal:words];
  [filterChain addFilter:filter withLabel:[filter getFilterSig]];
  [filter release];
}
-(void)addConditionContainsAnyWordInString:(NSString *)words toColumn:(NSString *)colName{
  TSDocFilter *filter = [[TSDocFilter alloc] initStringFilter:colName withOp:anyword andVal:words];
  [filterChain addFilter:filter withLabel:[filter getFilterSig]];
  [filter release];
}
-(void)addConditionContainsPhrase:(NSString *)thePhrase toColumn:(NSString *)colName{
  TSDocFilter *filter = [[TSDocFilter alloc] initStringFilter:colName withOp:phrase andVal:thePhrase];
  [filterChain addFilter:filter withLabel:[filter getFilterSig]];
  [filter release];
  
}
-(void)addConditionStringEquals:(NSString *)value toColumn:(NSString *)colName{
  TSDocFilter *filter = [[TSDocFilter alloc] initStringFilter:colName withOp:eq andVal:value];
  [filterChain addFilter:filter withLabel:[filter getFilterSig]];
  [filter release];
}
-(void)addConditionStringInSet:(NSArray *)values toColumn:(NSString *)colName{
  if(values != nil){
    TSDocFilter *filter = nil;
    if([[values objectAtIndex:0] isKindOfClass:[NSNumber class]]){
      filter = [[TSDocFilter alloc] initNumericFilter:colName withOp:eq andVal:values];
    } else {
      filter = [[TSDocFilter alloc] initStringFilter:colName withOp:eq andVal:values];
    }
    [filterChain addFilter:filter withLabel:[filter getFilterSig]];
    [filter release];
  }
}

#pragma mark Document Filter
-(void)addConditionDocumentContainsString:(NSString *)text{
  [self addConditionContainsAllWordsInString:text toColumn:@"_DOCDB.TXT"];
}

#pragma mark Numeric Filters
-(void)addConditionNumIsLessThan:(id)colVal toColumn:(NSString *)colName{
  if ([colVal isKindOfClass:[NSString class]] || [colVal isKindOfClass:[NSNumber class]]) {
    TSDocFilter *filter = [[TSDocFilter alloc] initStringFilter:colName withOp:contains andVal:colVal];
    [filterChain addFilter:filter withLabel:[filter getFilterSig]];
    [filter release];
  }
}
-(void)addConditionNumIsLessThanOrEquals:(id)colVal toColumn:(NSString *)colName{
  if ([colVal isKindOfClass:[NSString class]] || [colVal isKindOfClass:[NSNumber class]]) {
    TSDocFilter *filter = [[TSDocFilter alloc] initStringFilter:colName withOp:contains andVal:colVal];
    [filterChain addFilter:filter withLabel:[filter getFilterSig]];
    [filter release];
  }
}
-(void)addConditionNumIsGreaterThan:(id)colVal toColumn:(NSString *)colName{
  if ([colVal isKindOfClass:[NSString class]] || [colVal isKindOfClass:[NSNumber class]]) {
    TSDocFilter *filter = [[TSDocFilter alloc] initStringFilter:colName withOp:contains andVal:colVal];
    [filterChain addFilter:filter withLabel:[filter getFilterSig]];
    [filter release];
  }
}
-(void)addConditionNumIsGreaterThanOrEquals:(id)colVal toColumn:(NSString *)colName{
  if ([colVal isKindOfClass:[NSString class]] || [colVal isKindOfClass:[NSNumber class]]) {
    TSDocFilter *filter = [[TSDocFilter alloc] initStringFilter:colName withOp:contains andVal:colVal];
    [filterChain addFilter:filter withLabel:[filter getFilterSig]];
    [filter release];
  }
}

#pragma mark Convenient Search Methods
-(NSUInteger)getNumDocsOfType:(NSString *)docTypeOrNil{
  TCTDB *tdb = [self getDB];
  if (docTypeOrNil != nil) {
    [self addConditionStringEquals:docTypeOrNil toColumn:[self makeDocTypeKey]];
  }
  TDBQRY *qry = [filterChain getQuery:tdb];
  TCLIST *res = tctdbqrysearch(qry);  
  NSUInteger numRows = tclistnum(res);
  tclistdel(res);
  tctdbqrydel(qry);
  [filterChain removeAllFilters];
  return numRows;
}
-(NSUInteger)getNumResultsOfDocType:(NSString *)docTypeOrNil{
  TCTDB *tdb = [self getDB];
  if (docTypeOrNil != nil) {
    [self addConditionStringEquals:docTypeOrNil toColumn:[self makeDocTypeKey]];
  }
  TDBQRY *qry = [filterChain getQuery:tdb];
  TCLIST *res = tctdbqrysearch(qry);  
  NSUInteger numRows = tclistnum(res);
  tclistdel(res);
  tctdbqrydel(qry);
  [filterChain removeAllFilters];
  return numRows;
}
-(NSArray *)getRowsWithLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forRowTypes:(NSString *)rowType,...{
  TCTDB *tdb = [self getDB];
  NSMutableArray *rowTypes = [NSMutableArray arrayWithCapacity:1];
  GVargs(rowTypes, rowType, NSString);
  [filterChain removeAllFilters];
  if ([rowTypes count]) {
    [self addConditionStringInSet:rowTypes toColumn:[self makeDocTypeKey]];
  }
  TDBQRY *qry = [filterChain getQuery:tdb];
  [self adjustQuery:qry withLimit:resultLimit andOffset:resultOffset];
  NSArray *rows = [self fetchRows:qry];
  tctdbqrydel(qry);
  return rows;
}

-(NSArray *)doSearchWithLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forDocTypes:(NSString *)docType,...{
  TCTDB *tdb = [self getDB];
  NSMutableArray *docTypes = [NSMutableArray arrayWithCapacity:1];
  GVargs(docTypes, docType, NSString);
  if ([docTypes count]) {
    [self addConditionStringInSet:docTypes toColumn:[self makeDocTypeKey]];
  }
  TDBQRY *qry = [filterChain getQuery:tdb];
  [self adjustQuery:qry withLimit:resultLimit andOffset:resultOffset];
  NSArray *rows = [self fetchRows:qry];
  tctdbqrydel(qry);
  return rows;
}
-(NSArray *)searchForPhrase:(NSString *)phrase withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forDocTypes:(NSString *)docType,...{
  NSMutableArray *docTypes = [NSMutableArray arrayWithCapacity:1];
  GVargs(docTypes, docType, NSString);
  return nil;
}
-(NSArray *)searchForAllWords:(NSString *)words withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forDocTypes:(NSString *)docType,...{
  TCTDB *tdb = [self getDB];
  NSMutableArray *docTypes = [NSMutableArray arrayWithCapacity:1];
  GVargs(docTypes, docType, NSString);
  if ([docTypes count]) {
    [self addConditionStringInSet:docTypes toColumn:[self makeDocTypeKey]];
  }
  [self addConditionDocumentContainsString:words];
  TDBQRY *qry = [filterChain getQuery:tdb];
  
  [self adjustQuery:qry withLimit:resultLimit andOffset:resultOffset];
  NSArray *rows = [self fetchRows:qry];
  tctdbqrydel(qry);
  return rows;
}
-(NSArray *)searchForAnyWord:(NSString *)words withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forDocTypes:(NSString *)docType,...{
  TCTDB *tdb = [self getDB];
  NSMutableArray *docTypes = [NSMutableArray arrayWithCapacity:1];
  GVargs(docTypes, docType, NSString);
  if ([docTypes count]) {
    [self addConditionStringInSet:docTypes toColumn:[self makeDocTypeKey]];
  }
  [self addConditionContainsAnyWordInString:words toColumn:@"_DOCDB.TXT"];
  TDBQRY *qry = [filterChain getQuery:tdb];
  
  [self adjustQuery:qry withLimit:resultLimit andOffset:resultOffset];
  NSArray *rows = [self fetchRows:qry];
  tctdbqrydel(qry);
  return rows;
}
#pragma mark Asynchronous Convenient Search Methods
-(void)getNumDocsWithAsyncNotification:(NSString *)notificationNameOrNil ofDocTypeOrNil:(NSString *)docType{
  dispatch_queue_t queue;
  queue = dispatch_queue_create([self getQueueSig], NULL);
  __block NSUInteger ret;
  dispatch_async(queue, ^{
    ret = [self getNumDocsOfType:docType];
    [self postNotificationWithNotificationName:notificationNameOrNil andData:[NSNumber numberWithInt:ret]];
    dispatch_release(queue);
  });
  
}
-(void)doSearchWithAsyncNotification:(NSString *)notificationNameOrNil resultLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forDocTypes:(NSString *)docType,...{
  NSMutableArray *docTypes = [NSMutableArray arrayWithCapacity:1];
  GVargs(docTypes, docType, NSString);
  dispatch_queue_t queue;
  queue = dispatch_queue_create([self getQueueSig], NULL);
  __block NSArray *ret;
  dispatch_async(queue, ^{
    TCTDB *tdb = [self getDB];
    if ([docTypes count]) {
      [self addConditionStringInSet:docTypes toColumn:[self makeDocTypeKey]];
    }
    TDBQRY *qry = [filterChain getQuery:tdb];
    [self adjustQuery:qry withLimit:resultLimit andOffset:resultOffset];
    ret = [self fetchRows:qry];
    [self postNotificationWithNotificationName:notificationNameOrNil andData:ret];
    tctdbqrydel(qry);
    dispatch_release(queue);
  });
}
-(void)searchForPhraseWithAsyncNotification:(NSString *)notificationNameOrNil forPhrase:(NSString *)thePhrase withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forDocTypes:(NSString *)docType,...{
  NSMutableArray *docTypes = [NSMutableArray arrayWithCapacity:1];
  GVargs(docTypes, docType, NSString);
  dispatch_queue_t queue;
  queue = dispatch_queue_create([self getQueueSig], NULL);
  __block NSArray *ret;
  dispatch_async(queue, ^{
    TCTDB *tdb = [self getDB];
    if ([docTypes count]) {
      [self addConditionStringInSet:docTypes toColumn:[self makeDocTypeKey]];
    }
    [self addConditionContainsPhrase:thePhrase toColumn:@"_DOCDB.TXT"];
    TDBQRY *qry = [filterChain getQuery:tdb];
    
    [self adjustQuery:qry withLimit:resultLimit andOffset:resultOffset];
    ret = [self fetchRows:qry];
    [self postNotificationWithNotificationName:notificationNameOrNil andData:ret];
    tctdbqrydel(qry);
    dispatch_release(queue);
  });
}
-(void)searchForAllWordsWithAsyncNotification:(NSString *)notificationNameOrNil forWords:(NSString *)words withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forDocTypes:(NSString *)docType,...{
  NSMutableArray *docTypes = [NSMutableArray arrayWithCapacity:1];
  GVargs(docTypes, docType, NSString);
  dispatch_queue_t queue;
  queue = dispatch_queue_create([self getQueueSig], NULL);
  __block NSArray *ret;
  dispatch_async(queue, ^{
    TCTDB *tdb = [self getDB];
    if ([docTypes count]) {
      [self addConditionStringInSet:docTypes toColumn:[self makeDocTypeKey]];
    }
    [self addConditionDocumentContainsString:words];
    TDBQRY *qry = [filterChain getQuery:tdb];
    
    [self adjustQuery:qry withLimit:resultLimit andOffset:resultOffset];
    ret = [self fetchRows:qry];
    [self postNotificationWithNotificationName:notificationNameOrNil andData:ret];
    tctdbqrydel(qry);
    dispatch_release(queue);
  });
}
-(void)searchForAnyWordWithAsyncNotification:(NSString *)notificationNameOrNil forWords:(NSString *)words withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forDocTypes:(NSString *)docType,...{
  NSMutableArray *docTypes = [NSMutableArray arrayWithCapacity:1];
  GVargs(docTypes, docType, NSString);
  dispatch_queue_t queue;
  queue = dispatch_queue_create([self getQueueSig], NULL);
  __block NSArray *ret;
  dispatch_async(queue, ^{
    TCTDB *tdb = [self getDB];
    if ([docTypes count]) {
      [self addConditionStringInSet:docTypes toColumn:[self makeDocTypeKey]];
    }
    [self addConditionContainsAnyWordInString:words toColumn:@"_DOCDB.TXT"];
    TDBQRY *qry = [filterChain getQuery:tdb];
    
    [self adjustQuery:qry withLimit:resultLimit andOffset:resultOffset];
    ret = [self fetchRows:qry];
    [self postNotificationWithNotificationName:notificationNameOrNil andData:ret];
    tctdbqrydel(qry);
    dispatch_release(queue);
  });
}

#pragma mark -
#pragma mark ------Private Methods-------
#pragma mark Key Formatting Methods
-(NSString *)makePrimaryDocKey:(NSString *)docType andDocID:(NSString *)docID{
  return [NSString stringWithFormat:@"_DOCDB.DT:%@;_DOCDB.DK:%@", docType, docID];
}
-(NSString *)makeDocDefinitionKey:(NSString *)docType{
  return [NSString stringWithFormat:@"_DOCDB.DTD:%@", docType];
}
-(NSString *)makeDocTypeKey{
  return [NSString stringWithFormat:@"_DOCDB.DT"];
}
-(NSString *)makeDocVersionKey{
  return [NSString stringWithFormat:@"_DOCDB.DTVer"];
}
-(NSString *)makeDocTextColKey{
  return [NSString stringWithFormat:@"_DOCDB.TXT"];
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
-(void)loadDocTypes{
}

#pragma mark Utility Methods
-(const char *)getQueueSig{
  return [[NSString stringWithFormat:@"com.ticklespace.tsdocdb.%d", [dbFilePath hash]] UTF8String];
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
  TSDocDBManager *dbm = [TSDocDBManager sharedDBManager];
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
  NSLog(@"########################num res: %d", tclistnum(res));
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
-(BOOL)dbPut:(NSString *)docKey colVals:(NSDictionary *)docData{
  TCTDB *tdb = [self getDB];
  NSInteger docKeySize = strlen([docKey UTF8String]);
  TCMAP *cols = tcmapnew();
  for (NSString *colKey in [docData allKeys]) {
    if([[docData objectForKey:colKey] isKindOfClass:[NSString class]]){
      if (strlen([[docData objectForKey:colKey] UTF8String]) > 0) {
        tcmapput(cols, [colKey UTF8String], strlen([colKey UTF8String]), [[docData objectForKey:colKey] UTF8String], strlen([[docData objectForKey:colKey] UTF8String]));
      }else {
        tcmapput(cols, [colKey UTF8String], strlen([colKey UTF8String]), " ", strlen(" "));
      }
      //tcmapput2(cols, [colKey UTF8String], [[docData objectForKey:colKey] UTF8String]);
    }else if([[docData objectForKey:colKey] isKindOfClass:[NSNumber class]]){
      //tcmapput2(cols, [colKey UTF8String], [[[docData objectForKey:colKey] stringValue] UTF8String]);
      tcmapput(cols, [colKey UTF8String], strlen([colKey UTF8String]), [[[docData objectForKey:colKey] stringValue] UTF8String], strlen([[[docData objectForKey:colKey] stringValue] UTF8String]));
    } else if ([[docData objectForKey:colKey] isKindOfClass:[NSArray class]] || [[docData objectForKey:colKey] isKindOfClass:[NSDictionary class]]) {
      //tcmapput2(cols, [colKey UTF8String], [[[docData objectForKey:colKey] description] UTF8String]);
      tcmapput(cols, [colKey UTF8String], strlen([colKey UTF8String]), [[[docData objectForKey:colKey] description] UTF8String], strlen([[[docData objectForKey:colKey] description] UTF8String]));
    }

  }
  if(!tctdbput(tdb, [docKey UTF8String], docKeySize, cols)){
    int ecode = tctdbecode(tdb);
    ALog(@"DB put error:%@", [TSDocDB getDBError:ecode]);
  }
  tcmapdel(cols);
  
  return NO;
}
-(NSDictionary *)dbGet:(NSString *)docID{
  TCTDB *tdb = [self getDB];
  NSMutableDictionary *docData = nil;
  TCMAP *cols = tctdbget(tdb, [docID UTF8String], strlen([docID UTF8String]));
  const char *name;
  if(cols){
    tcmapiterinit(cols);
    docData = [NSMutableDictionary dictionaryWithCapacity:1];;
    while((name = tcmapiternext2(cols)) != NULL){
      [docData setObject:[NSString stringWithUTF8String:tcmapget2(cols, name)] 
                  forKey:[NSString stringWithUTF8String:name]];
    }
    tcmapdel(cols);
  }  
  return docData;
}
-(BOOL)dbDel:(NSString *)docID{
  TCTDB *tdb = [self getDB];
  return tctdbout(tdb, [docID UTF8String], strlen([docID UTF8String]));
}
+(NSString *)getDBError:(int)ecode{
  return [NSString stringWithUTF8String:tctdberrmsg(ecode)];
}

- (NSString *)directoryForDB:(NSString *)dbName{
  NSString *executableName =
  [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
  NSError *error;
  NSString *result =
  [self
   findOrCreateDirectory:NSApplicationSupportDirectory
   inDomain:NSUserDomainMask
   appendPathComponent:[NSString stringWithFormat:@"%@/%@", executableName, dbName]
   error:&error];
  if (error)
  {
    NSLog(@"Unable to find or create application support directory:\n%@", error);
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
