//
//  TSDB.h
//  TSDB
//
//  Created by Isaac Tewolde on 10-06-12.
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
-(id)TSModelObjectForData:(NSDictionary *)rowData andRowType:(NSString *)rowType;

@end
@class TSDBQuery;
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
  //TCMAP *reuseableTCMap;
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


//Modification Methods
-(void)reindexDB:(NSString *)rowTypeOrNil;
-(void)reindexRows:(NSString *)rowType;
-(void)optimizeDBWithBnum:(NSInteger)bnum;
-(void)optimizeDB;
-(void)optimizeIndexes:(NSString *)rowTypeOrNil;
-(void)resetDB;
-(void)replaceRow:(NSString *)rowID withRowType:(NSString *)rowType andRowData:(NSDictionary *)rowData;
-(id)getRowByStringID:(NSString *)rowID forType:(NSString *)rowType;
-(id)getRowByIntegerID:(NSInteger)rowID forType:(NSString *)rowType;
-(BOOL)deleteRow:(NSString *)rowID forType:(NSString *)rowType;
-(BOOL)deleteMatchingRowsForRowTypes:(NSString *)rowType,...  NS_REQUIRES_NIL_TERMINATION;

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


//Convenient Search Methods
-(NSArray *)searchForPhrase:(NSString *)phrase withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forRowTypes:(NSString *)rowType,... NS_REQUIRES_NIL_TERMINATION;
-(NSArray *)searchForAllWords:(NSString *)words withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forRowTypes:(NSString *)rowType,... NS_REQUIRES_NIL_TERMINATION;
-(NSArray *)searchForAnyWord:(NSString *)words withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forRowTypes:(NSString *)rowType,... NS_REQUIRES_NIL_TERMINATION;

//DB streaming methods
-(void)doSearchWithProcessingBlock:(BOOL(^)(id))processingBlock withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forRowTypes:(NSString *)rowType,...  NS_REQUIRES_NIL_TERMINATION;

//Asynchronous Search Methods
-(void)getNumRowsWithAsyncNotification:(NSString *)notificationNameOrNil ofRowTypeOrNil:(NSString *)rowType;
-(void)doSearchWithAsyncNotification:(NSString *)notificationNameOrNil resultLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forRowTypes:(NSString *)rowType,...  NS_REQUIRES_NIL_TERMINATION;

//Asynchronous & Convenient Search Methods!
-(void)searchForPhraseWithAsyncNotification:(NSString *)notificationNameOrNil forPhrase:(NSString *)phrase withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forRowTypes:(NSString *)rowType,... NS_REQUIRES_NIL_TERMINATION;
-(void)searchForAllWordsWithAsyncNotification:(NSString *)notificationNameOrNil forWords:(NSString *)words withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forRowTypes:(NSString *)rowType,... NS_REQUIRES_NIL_TERMINATION;
-(void)searchForAnyWordWithAsyncNotification:(NSString *)notificationNameOrNil forWords:(NSString *)words withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forRowTypes:(NSString *)rowType,... NS_REQUIRES_NIL_TERMINATION;

//Predefined query search methods
-(TSDBQuery *)getQueryObjectForRowTypes:(NSString *)rowType,... NS_REQUIRES_NIL_TERMINATION;
-(TDBQRY *)getQueryObjectForFilterChain:(TSRowFilterChain *)theFilterChain;
-(void)doPredifinedSearchWithQuery:(TDBQRY *)query andProcessingBlock:(BOOL(^)(id))processingBlock;
-(NSArray *)doPredifinedSearchWithQuery:(TDBQRY *)query;
-(NSInteger)getRowCountForQuery:(TDBQRY *)query;
@end


