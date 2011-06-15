TSDocDB
========
A simple, flexible db system built on top of the powerful [Tokyo Cabinet](http://fallabs.com/tokyocabinet/) embedded database system. TSDocDB adds an objective-c wrapper to tokyo cabinet and provides many conveniences to allow rapid deployment in your iOS os OSX application. See the included sample app for a detailed use case.

The Objects
===========

TSDB
----
TSDB is the main object you will be using in you application. Each TSDB object represents a connection to a tokyo cabinet database. Multiple connections to the same db are allowed.

TSDBManager
-----------
TSDBManager is used by TSDB to perform low level db operations such as creation of tokyo cabinet dbs. You can use the class method of this object `[TSDBManager closeAll];` to close down all open databases in your `applicationWillTerminate:` method.

TSDBQuery
---------
A predefined search list object, use this object to create/maintain "Smart List/Folder" style lists in your application.


TSDB
====

DBManagement Methods
--------------------
These methods are used to create/open new DB instances. By default new databases are creted in the ApplicationSupport(iOS & OSX) directory and each DB is in it's own directory. It's also possible to bulde an the db into the application bundle as a zip archive and then extract it out before using it.

    +(id)TSDBWithDBNamed:(NSString *)dbName inDirectoryAtPathOrNil:(NSString*)path delegate:(id<TSDBDefinitionsDelegate>)theDelegate;
    +(BOOL)TSDBExistsWithName:(NSString *)dbName;
    +(BOOL)TSDBExtractDBFromZipArchive:(NSString *)pathToZipFile;
    -(id)initWithDBNamed:(NSString *)dbName inDirectoryAtPathOrNil:(NSString*)path delegate:(id<TSDBDefinitionsDelegate>)theDelegate;

These methods are for DB maintainance and optimization

    -(void)syncDB;
    -(void)reindexDB:(NSString *)rowTypeOrNil;
    -(void)reindexRows:(NSString *)rowType;
    -(void)optimizeDBWithBnum:(NSInteger)bnum;
    -(void)optimizeDB;
    -(void)optimizeIndexes:(NSString *)rowTypeOrNil;

Modification Methods
--------------------
    -(void)resetDB;
    -(void)replaceRow:(NSString *)rowID withRowType:(NSString *)rowType andRowData:(NSDictionary *)rowData;
    -(id)getRowByStringID:(NSString *)rowID forType:(NSString *)rowType;
    -(id)getRowByIntegerID:(NSInteger)rowID forType:(NSString *)rowType;
    -(BOOL)deleteRow:(NSString *)rowID forType:(NSString *)rowType;
    -(BOOL)deleteMatchingRowsForRowTypes:(NSString *)rowType,...  NS_REQUIRES_NIL_TERMINATION;

Ordering Methods
----------------
    -(void)setOrderByStringForColumn:(NSString *)colName isAscending:(BOOL)ascending;
    -(void)setOrderByNumericForColumn:(NSString *)colName isAscending:(BOOL)ascending;

Filtering Methods
-----------------
TSDB uses filter chains to constraint search results. A filter chain a list if expressions(filter) that are resolve to true or false. The filter chain is like the "where" part of an SQL statment, where for a row to match each filter in the chain must resolve to true.

Filter chains are built one at a time and when the search is excecuted the filter chain is cleared. It is also possible to have have the filters remain after the search has executed, see "Predefined query search methods"

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

Search Excecution Methods
--------------
These methods are for excecuting a search or counting the number results found.

    -(NSUInteger)getNumRowsOfType:(NSString *)rowTypeOrNil;
    -(NSUInteger)getNumResultsOfRowType:(NSString *)rowTypeOrNil;
    -(NSArray *)doSearchWithLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forRowTypes:(NSString *)rowType,...  NS_REQUIRES_NIL_TERMINATION;

This method deletes the matching rows. Careful when using this method as running it without adding any conditions or row types will remove all the rows in the database.

    -(BOOL)deleteMatchingRowsForRowTypes:(NSString *)rowType,...  NS_REQUIRES_NIL_TERMINATION;

Asynchronous Search Excecution Methods
---------------------------
Same as above but perform the search asyncronously and receive the results via a NSNotification.
    -(void)getNumRowsWithAsyncNotification:(NSString *)notificationNameOrNil ofRowTypeOrNil:(NSString *)rowType;
    -(void)doSearchWithAsyncNotification:(NSString *)notificationNameOrNil resultLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forRowTypes:(NSString *)rowType,...  NS_REQUIRES_NIL_TERMINATION;

Streaming Search Excecution Methods
--------------------
If you want to process results as they are being fetched from the db use this method. This is very useful for db operations that take a long time and you want to update UI elements as the db operation proceeds.

    -(void)doSearchWithProcessingBlock:(BOOL(^)(id))processingBlock withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forRowTypes:(NSString *)rowType,...  NS_REQUIRES_NIL_TERMINATION;

Convenient Search Methods
-------------------------
Each row type has certain columns that are tracked for full text searches. This is controlled by the TSDBDefinitionsDelegate object. The methods below then allow you to perform full text searches across all these columns for each row type.

    -(NSArray *)searchForPhrase:(NSString *)phrase withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forRowTypes:(NSString *)rowType,... NS_REQUIRES_NIL_TERMINATION;
    -(NSArray *)searchForAllWords:(NSString *)words withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forRowTypes:(NSString *)rowType,... NS_REQUIRES_NIL_TERMINATION;
    -(NSArray *)searchForAnyWord:(NSString *)words withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forRowTypes:(NSString *)rowType,... NS_REQUIRES_NIL_TERMINATION;


Asynchronous & Convenient Search Methods
----------------------------------------
Same as above but perform the search asyncronously and receive the results via an NSNotification.
    -(void)searchForPhraseWithAsyncNotification:(NSString *)notificationNameOrNil forPhrase:(NSString *)phrase withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forRowTypes:(NSString *)rowType,... NS_REQUIRES_NIL_TERMINATION;
    -(void)searchForAllWordsWithAsyncNotification:(NSString *)notificationNameOrNil forWords:(NSString *)words withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forRowTypes:(NSString *)rowType,... NS_REQUIRES_NIL_TERMINATION;
    -(void)searchForAnyWordWithAsyncNotification:(NSString *)notificationNameOrNil forWords:(NSString *)words withLimit:(NSUInteger)resultLimit andOffset:(NSUInteger)resultOffset forRowTypes:(NSString *)rowType,... NS_REQUIRES_NIL_TERMINATION;

Predefined query search methods
-------------------------------
TSDBQuery objects are simillar to "Smart Playlists" in iTunes. They allow you save out the filter chain you have created and reuse them as needed.

    -(TSDBQuery *)getQueryObjectForRowTypes:(NSString *)rowType,... NS_REQUIRES_NIL_TERMINATION;
    -(void)doPredifinedSearchWithQuery:(TDBQRY *)query andProcessingBlock:(BOOL(^)(id))processingBlock;
    -(NSArray *)doPredifinedSearchWithQuery:(TDBQRY *)query;
    -(NSInteger)getRowCountForQuery:(TDBQRY *)query;
    -(TDBQRY *)getQueryObjectForFilterChain:(TSRowFilterChain *)theFilterChain;

