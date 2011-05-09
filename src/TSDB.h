//
//  TSDB.h
//  TSDB
//
//  Created by Isaac Tewolde on 10-06-12.
//  Copyright 2010 Ticklespace.com. All rights reserved.
//

#import <Foundation/Foundation.h>

//TokyoCabinet Stuff
#include <tcutil.h>
#include <tctdb.h>

#import "TSRowFilterChain.h"

@protocol TSDBDefinitionsDelegate <NSObject>

typedef enum {
  TSIndexTypeString,
  TSIndexTypeNumeric,
  TSIndexTypeFullTextColumn
} TSIndexType;

@required
-(NSArray *)TSGetRowTypes;
-(NSArray *)TSColumnsForIndexType:(TSIndexType)indexType;
-(NSArray *)TSColumnsForFullTextSearch:(NSString *)rowType;
-(NSString *)TSPrimaryColumnForRowType:(NSString *)rowType;
@optional

@end

@interface TSDB : NSObject {
  TSRowFilterChain *filterChain;
  NSString *selectedRowType;
  
  NSMutableString *orderBy;
  NSInteger direction;
  
  NSString *dbFilePath;
  NSString *dbDir;
  NSString *dbNamePrefix;
  NSString *rootDBDir;
  id <TSDBDefinitionsDelegate> _delegate;		//Used to store the publicly visible delegate
  dispatch_queue_t dbQueue;
  TCMAP *reuseableTCMap;
}
@property(nonatomic,readonly) NSString *dbFilePath;

@property (assign) id<TSDBDefinitionsDelegate> delegate;

//DBManagement Methods
//-(id)initWithDB:(NSString *)dbPath;
+(id)TSDBWithDBNamed:(NSString *)dbName inDirectoryAtPathOrNil:(NSString*)path delegate:(id<TSDBDefinitionsDelegate>)theDelegate;
+(BOOL)TSDBExistsWithName:(NSString *)dbName;
+(BOOL)TSDBExtractDBFromZipArchive:(NSString *)pathToZipFile;
-(id)initWithDBNamed:(NSString *)dbName inDirectoryAtPathOrNil:(NSString*)path delegate:(id<TSDBDefinitionsDelegate>)theDelegate;
-(void)syncDB;
-(void)reopenDB;


//Table Management Methods
-(void)reindexDB:(NSString *)rowTypeOrNil;
-(void)reindexRows:(NSString *)rowType;
-(void)optimizeDBWithBnum:(NSInteger)bnum;
-(void)optimizeDB;
-(void)optimizeIndexes:(NSString *)rowTypeOrNil;
-(void)resetDB;

-(void)replaceRow:(NSString *)rowID withRowType:(NSString *)rowType andRowData:(NSDictionary *)rowData;
-(NSDictionary *)getRowByStringID:(NSString *)rowID forType:(NSString *)rowType;
-(NSDictionary *)getRowByIntegerID:(NSInteger)rowID forType:(NSString *)rowType;
-(BOOL)deleteRow:(NSString *)rowID forType:(NSString *)rowType;

//Ordering Methods
-(void)setOrderByStringForColumn:(NSString *)colName isAscending:(BOOL)ascending;
-(void)setOrderByNumericForColumn:(NSString *)colName isAscending:(BOOL)ascending;

//Filtering Methods
-(void)clearFilters;
-(void)addConditionBeginsWithString:(NSString *)string toColumn:(NSString *)colName;
-(void)addConditionEndsWithString:(NSString *)string toColumn:(NSString *)colName;
-(void)addConditionContainsAllWordsInString:(NSString *)words toColumn:(NSString *)colName;
-(void)addConditionContainsAnyWordInString:(NSString *)words toColumn:(NSString *)colName;
-(void)addConditionContainsPhrase:(NSString *)thePhrase toColumn:(NSString *)colName;
-(void)addConditionStringEquals:(NSString *)value toColumn:(NSString *)colName;
-(void)addConditionStringInSet:(NSArray *)values toColumn:(NSString *)colName;
-(void)addConditionRowContainsString:(NSString *)text;

-(void)addConditionNumIsLessThan:(id)colVal toColumn:(NSString *)colName;
-(void)addConditionNumIsLessThanOrEquals:(id)colVal toColumn:(NSString *)colName;
-(void)addConditionNumEquals:(id)colVal toColumn:(NSString *)colName;
-(void)addConditionNumIsGreaterThan:(id)colVal toColumn:(NSString *)colName;
-(void)addConditionNumIsGreaterThanOrEquals:(id)colVal toColumn:(NSString *)colName;

//Search Methods
-(NSUInteger)getNumRowsOfType:(NSString *)rowTypeOrNil;
-(NSUInteger)getNumResultsOfRowType:(NSString *)rowTypeOrNil;
-(NSArray *)doSearchWithLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forRowTypes:(NSString *)rowType,...  NS_REQUIRES_NIL_TERMINATION;
-(BOOL)deleteMatchingRowsForRowTypes:(NSString *)rowType,...  NS_REQUIRES_NIL_TERMINATION;

//Convenient Search Methods
-(NSArray *)searchForPhrase:(NSString *)phrase withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forRowTypes:(NSString *)rowType,... NS_REQUIRES_NIL_TERMINATION;
-(NSArray *)searchForAllWords:(NSString *)words withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forRowTypes:(NSString *)rowType,... NS_REQUIRES_NIL_TERMINATION;
-(NSArray *)searchForAnyWord:(NSString *)words withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forRowTypes:(NSString *)rowType,... NS_REQUIRES_NIL_TERMINATION;

//Asynchronous Search Methods
-(void)getNumRowsWithAsyncNotification:(NSString *)notificationNameOrNil ofRowTypeOrNil:(NSString *)rowType;
-(void)doSearchWithAsyncNotification:(NSString *)notificationNameOrNil resultLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forRowTypes:(NSString *)rowType,...  NS_REQUIRES_NIL_TERMINATION;

//Asynchronous & Convenient Search Methods!
-(void)searchForPhraseWithAsyncNotification:(NSString *)notificationNameOrNil forPhrase:(NSString *)phrase withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forRowTypes:(NSString *)rowType,... NS_REQUIRES_NIL_TERMINATION;
-(void)searchForAllWordsWithAsyncNotification:(NSString *)notificationNameOrNil forWords:(NSString *)words withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forRowTypes:(NSString *)rowType,... NS_REQUIRES_NIL_TERMINATION;
-(void)searchForAnyWordWithAsyncNotification:(NSString *)notificationNameOrNil forWords:(NSString *)words withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forRowTypes:(NSString *)rowType,... NS_REQUIRES_NIL_TERMINATION;

@end


