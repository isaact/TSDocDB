//
//  TSDocDB.h
//  TSDocDB
//
//  Created by Isaac Tewolde on 10-06-12.
//  Copyright 2010 Ticklespace.com. All rights reserved.
//

#import <Foundation/Foundation.h>

//TokyoCabinet Stuff
#include <tcutil.h>
#include <tctdb.h>

#import "TSDocFilterChain.h"

@protocol TSDocDBDefinitionsDelegate <NSObject>

typedef enum {
  TSIndexTypeString,
  TSIndexTypeNumeric,
  TSIndexTypeFullTextColumn
} TSIndexType;

@required
-(NSArray *)getDocTypes;
-(NSArray *)TSColumnsForIndexType:(TSIndexType)indexType;
-(NSArray *)TSColumnsFullTextDocumentSearch:(NSString *)docType;

@optional

@end

@interface TSDocDB : NSObject {
  TSDocFilterChain *filterChain;
  NSString *selectedDocType;
  
  NSMutableString *orderBy;
  NSInteger direction;
  
  NSString *dbFilePath;
  
  id <TSDocDBDefinitionsDelegate> _delegate;		//Used to store the publicly visible delegate
}
@property(nonatomic,readonly) NSString *dbFilePath;

@property (assign) id<TSDocDBDefinitionsDelegate> delegate;

//DBManagement Methods
//-(id)initWithDB:(NSString *)dbPath;
+(id)TSDocDBWithDBNamed:(NSString *)dbName inDirectoryAtPathOrNil:(NSString*)path delegate:(id<TSDocDBDefinitionsDelegate>)theDelegate;
-(id)initWithDBNamed:(NSString *)dbName inDirectoryAtPathOrNil:(NSString*)path delegate:(id<TSDocDBDefinitionsDelegate>)theDelegate;
-(void)syncDB;
-(void)reopenDB;


//Doc Management Methods
-(void)reindexDocs:(NSString *)docTypeOrNil;
-(void)optimizeDB;
-(void)optimizeIndexes:(NSString *)docTypeOrNil;

-(void)saveDoc:(NSString *)docID withDocType:(NSString *)docType andDocData:(NSDictionary *)docData;
-(NSDictionary *)getDocWithStringID:(NSString *)docID forType:(NSString *)docType;
-(NSDictionary *)getDocWithIntegerID:(NSInteger)docID forType:(NSString *)docType;
-(BOOL)deleteDoc:(NSString *)docID;

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
-(void)addConditionDocumentContainsString:(NSString *)text;

-(void)addConditionNumIsLessThan:(id)colVal toColumn:(NSString *)colName;
-(void)addConditionNumIsLessThanOrEquals:(id)colVal toColumn:(NSString *)colName;
-(void)addConditionNumIsGreaterThan:(id)colVal toColumn:(NSString *)colName;
-(void)addConditionNumIsGreaterThanOrEquals:(id)colVal toColumn:(NSString *)colName;

//Search Methods
-(NSUInteger)getNumDocsOfType:(NSString *)docTypeOrNil;
-(NSUInteger)getNumResultsOfDocType:(NSString *)docTypeOrNil;
-(NSArray *)doSearchWithLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forDocTypes:(NSString *)docType,...  NS_REQUIRES_NIL_TERMINATION;

//Convenient Search Methods
-(NSArray *)searchForPhrase:(NSString *)phrase withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forDocTypes:(NSString *)docType,... NS_REQUIRES_NIL_TERMINATION;
-(NSArray *)searchForAllWords:(NSString *)words withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forDocTypes:(NSString *)docType,... NS_REQUIRES_NIL_TERMINATION;
-(NSArray *)searchForAnyWord:(NSString *)words withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forDocTypes:(NSString *)docType,... NS_REQUIRES_NIL_TERMINATION;

//Asynchronous Search Methods
-(void)getNumDocsWithAsyncNotification:(NSString *)notificationNameOrNil ofDocTypeOrNil:(NSString *)docType;
-(void)doSearchWithAsyncNotification:(NSString *)notificationNameOrNil resultLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forDocTypes:(NSString *)docType,...  NS_REQUIRES_NIL_TERMINATION;

//Asynchronous & Convenient Search Methods!
-(void)searchForPhraseWithAsyncNotification:(NSString *)notificationNameOrNil forPhrase:(NSString *)phrase withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forDocTypes:(NSString *)docType,... NS_REQUIRES_NIL_TERMINATION;
-(void)searchForAllWordsWithAsyncNotification:(NSString *)notificationNameOrNil forWords:(NSString *)words withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forDocTypes:(NSString *)docType,... NS_REQUIRES_NIL_TERMINATION;
-(void)searchForAnyWordWithAsyncNotification:(NSString *)notificationNameOrNil forWords:(NSString *)words withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forDocTypes:(NSString *)docType,... NS_REQUIRES_NIL_TERMINATION;

@end


