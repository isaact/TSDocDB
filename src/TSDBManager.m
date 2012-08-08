//
//  TSDBManager.m
//  TSDB
//
//  Created by Isaac Tewolde on 10-11-07.
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

#import "TSDBManager.h"
#import <Foundation/Foundation.h>
#import "TSMacros.h"
#import "NSString+TSTools.h"

@interface TSDBManager()

-(id)initTSDBManager;

#pragma mark -
#pragma mark Utility Methods
-(TCTDB *)createDB:(NSString *)dbPath;
-(TCTDB *)openDB:(NSString *)dbPath writeMode:(BOOL)writeMode;
-(TCTDB *)getDBFromFile:(NSString *)dbFilePath;
-(void)closeAllDBs;
+(NSString *)getQueueSig;

-(NSString *)directoryForDB:(NSString *)dbName withPathOrNil:(NSString *)path;
-(NSString *)findOrCreateDirectory:(NSSearchPathDirectory)searchPathDirectory inDomain:(NSSearchPathDomainMask)domainMask appendPathComponent:(NSString *)appendComponent error:(NSError **)errorOut;
-(NSString *)backupDirForDB:(NSString *)dbName atPathOrNil:(NSString *)dbPath;
@end

@implementation TSDBManager

static TSDBManager *sharedDBManager = nil;
static TCMAP *tsDBs = NULL;
//static TCMAP *dbQueues;
static dispatch_queue_t tsDBManagerQueue = NULL;
static dispatch_queue_t tsDBMainQueue = NULL;

+(TSDBManager *)sharedDBManager{
  if (tsDBManagerQueue == NULL) {
    tsDBMainQueue = dispatch_queue_create("com.ticklespace.tsdocdb", NULL);
    tsDBManagerQueue = dispatch_queue_create("com.ticklespace.tsdocdbman", NULL);
  }
  dispatch_sync(tsDBManagerQueue, ^{
    if (sharedDBManager == nil) {
      sharedDBManager = [[TSDBManager alloc] initTSDBManager];
    }
  });
  return sharedDBManager;
}

- (id) initTSDBManager
{
  self = [super init];
  if (self != nil) {
    /* create a new map object */
    tsDBs = tcmapnew();
    //dbQueues = tcmapnew();
  }
  return self;
}
#pragma mark -
#pragma mark Public Methods

-(TCTDB *)getDB:(NSString *)dbFilePath{
  __block TCTDB *tdb = NULL;
  dispatch_sync(tsDBManagerQueue, ^{
    int sp;
    tdb = (TCTDB *)tcmapget(tsDBs, [dbFilePath UTF8String], (int)strlen([dbFilePath UTF8String]), &sp);
    if (!tdb) {
      
      //const char *queueKey = [[TSDBManager getQueueSigForDbPath:dbFilePath] UTF8String];
      //dispatch_queue_t dbQueue = dispatch_queue_create(queueKey,NULL);
      tdb = [self getDBFromFile:dbFilePath];
      //tctdboptimize(tdb, 31010000, -1, -1, TDBTLARGE);
      tcmapput(tsDBs, [dbFilePath UTF8String], (int)strlen([dbFilePath UTF8String]), tdb, sizeof(TCTDB));
      //tcmapput(dbQueues, queueKey, strlen(queueKey), dbQueue, sizeof(dispatch_queue_t));
      //tctdbdel(tdb);
      tcfree(tdb);
      tdb = (TCTDB *)tcmapget(tsDBs, [dbFilePath UTF8String], strlen([dbFilePath UTF8String]), &sp);
      //tctdbsetindex(tdb, "_TSDB.TXT", TDBITQGRAM);
      //tctdbsetindex(tdb, "_TSDB.DT", TDBITLEXICAL);
    }else{
      //ALog(@"Reopening DB: %@", dbFilePath);
    }
    
  });
  return tdb;
}
-(void)recyleDBAtPath:(NSString *)dbFilePath{
  dispatch_sync(tsDBManagerQueue, ^{
    TCTDB *tdb = NULL;
    int sp;
    tdb = (TCTDB *)tcmapget(tsDBs, [dbFilePath UTF8String], (int)strlen([dbFilePath UTF8String]), &sp);
    if (tdb) {
      tctdbclose(tdb);
      //if (tdb) {
      //  tctdbdel(tdb);
      //}
      tcmapdel(tsDBs);
      //tcmapdel(dbQueues);
      TCMPOOL *mpool = tcmpoolglobal();
      if (mpool) {
        tcmpoolclear(mpool, 1);
      }      
      //tcmpooldelglobal();
      /* create a new map object */
      tsDBs = tcmapnew();
      //dbQueues = tcmapnew();
      
      tcmapout(tsDBs, [dbFilePath UTF8String], (int)strlen([dbFilePath UTF8String]));
      TCTDB *tdb2 = [self getDBFromFile:dbFilePath];
      tcmapput(tsDBs, [dbFilePath UTF8String], (int)strlen([dbFilePath UTF8String]), tdb2, sizeof(TCTDB));
      //[dbQueues setObject:<#(id)anObject#> forKey:<#(id)aKey#>
      //tctdbdel(tdb);
      //tdb = (TCTDB *)tcmapget(tsDBs, [dbFilePath UTF8String], strlen([dbFilePath UTF8String]), &sp);
    }
    
  });
}

-(void)removeDB:(NSString *)dbName atPathOrNil:(NSString *)dbContainerPathOrNil{
  __block TCTDB *tdb = NULL;
  dispatch_sync(tsDBManagerQueue, ^{
    int sp;
    NSString *dbFilePath, *dbPath;
    dbPath = [self directoryForDB:dbName withPathOrNil:dbContainerPathOrNil];
    dbFilePath = [NSString stringWithFormat:@"%@.tct", dbPath];
    tdb = (TCTDB *)tcmapget(tsDBs, [dbFilePath UTF8String], (int)strlen([dbFilePath UTF8String]), &sp);
    if (tdb) {
      tctdbclose(tdb);
      tcmapout(tsDBs, [dbFilePath UTF8String], (int)strlen([dbFilePath UTF8String]));
    }
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError* error = nil;
    [fm removeItemAtPath:dbPath error:&error];
    //NSLog([error localizedDescription]);
    
  });
}
#pragma mark -
#pragma mark Utility Methods
+(NSString *)getDBError:(int)ecode{
  return [NSString stringWithUTF8String:tctdberrmsg(ecode)];
}
+(NSString *)getQueueSig{
  return @"com.ticklespace.tsdocdb";
}
+(NSString *)getQueueSigForDbPath:(NSString *)dbPath{
  return [NSString stringWithFormat:@"tsqueue-%d", [dbPath hash]];
}

-(NSString *)directoryForDB:(NSString *)dbName withPathOrNil:(NSString *)path{
  NSString *result = nil;
  if (path == nil) {
    NSString *executableName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
    NSError *error;
    result =
    [self
     findOrCreateDirectory:DB_STORAGE_AREA
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
-(dispatch_queue_t)getQueueForDBPath:(NSString *)dbPath{
  //const char *queueKey = [[TSDBManager getQueueSigForDbPath:dbPath] UTF8String];
  //int sp;
  //return (dispatch_queue_t)tcmapget(dbQueues, queueKey, strlen(queueKey), &sp);
  return tsDBMainQueue;
}

-(TCTDB *)createDB:(NSString *)dbPath{
  TCTDB *tdb;
  int ecode;
  
  /* create the object */
  tdb = tctdbnew();
  //tctdbsetcache(tdb, -1, 10, 10);
  tctdbsetxmsiz(tdb, TSDB_XMSIZ);
  tctdbtune(tdb, TSDB_BNUM, -1, -1, TDBTLARGE);
  //tctdbsetdfunit(tdb, 1);
  /* open the database */
  if(!tctdbopen(tdb, [dbPath UTF8String], TDBOWRITER|TDBOCREAT|TDBOTSYNC|TDBOLCKNB)){
    ecode = tctdbecode(tdb);
    ALog(@"DB create error:%@", [TSDBManager getDBError:ecode]);
    return NULL;
  }
  return tdb;
}

-(TCTDB *)openDB:(NSString *)dbPath writeMode:(BOOL)writeMode{
  TCTDB *tdb;
  int ecode;
  int flags;
  
  /* create the object */
  tdb = tctdbnew();
  //tctdbsetcache(tdb, -1, 10, 10);
  tctdbsetxmsiz(tdb, TSDB_XMSIZ);
  //tctdbsetdfunit(tdb, 1);
  if (writeMode) {
    flags = TDBOWRITER|TDBOTSYNC|TDBOLCKNB;
  }else {
    flags = TDBOREADER|TDBOTSYNC;
  }
  
  /* open the database */
  if(!tctdbopen(tdb, [dbPath UTF8String], flags )){
    ecode = tctdbecode(tdb);
    ALog(@"DB open error:%@", [TSDBManager getDBError:ecode]);
    return NULL;
  }
  return tdb;
}
+(void)closeAll{
  TSDBManager *dbm = [TSDBManager sharedDBManager];
  [dbm closeAllDBs];
}
-(void)closeAllDBs{
  const char *key;
  int sp;
  TCTDB *db;
  tcmapiterinit(tsDBs);
  while((key = tcmapiternext2(tsDBs)) != NULL){
    //NSLog(@"Closing : %s", key);
    db = (TCTDB *)tcmapget(tsDBs, key, (int)strlen(key), &sp);
    //tctdbsync(db);
    tctdbclose(db);
    tcmapout(tsDBs, key, (int)strlen(key));
  }
  //NSLog(@"Done");
  tcmapdel(tsDBs);
}
-(TCTDB *)getDBFromFile:(NSString *)dbFilePath{
  NSFileManager *fileManager = [NSFileManager defaultManager];
  TCTDB *tdb;
  if ([fileManager fileExistsAtPath:dbFilePath]) {
    tdb = [self openDB:dbFilePath writeMode:YES];
  }else {
    tdb = [self createDB:dbFilePath];
  }
  return tdb;
}

- (void) dealloc{
  [self closeAllDBs];
  [sharedDBManager release];
  [super dealloc];
}

#pragma mark -
#pragma mark Backup methods
-(BOOL)restoreDB:(NSString *)dbName atPathOrNil:(NSString *)dbPath fromBackup:(NSString *)backupID{ 
  dispatch_sync(tsDBManagerQueue, ^{
    NSString *backupPath = [NSString stringWithFormat:@"%@/%@", [self backupDirForDB:dbName atPathOrNil:dbPath], backupID];
    NSString *backupFilePath = [NSString stringWithFormat:@"%@/%@.tct", backupPath, dbName];
    
    NSString *destPath = [self directoryForDB:dbName withPathOrNil:dbPath];
    NSString *destDBFilePath = [NSString stringWithFormat:@"%@/%@.tct", destPath, dbName];
    NSString *tcDestPath = [NSString stringWithFormat:@"%@/%@.tct", destPath, dbName];
    
    int sp;
    TCTDB *tdb = NULL;
    tdb = (TCTDB *)tcmapget(tsDBs, [destDBFilePath UTF8String], (int)strlen([destDBFilePath UTF8String]), &sp);
    if (tdb) {
      tctdbclose(tdb);
      tcmapout(tsDBs, [destDBFilePath UTF8String], (int)strlen([destDBFilePath UTF8String]));
    }
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:destPath error:NULL];
    
    BOOL success = [fm createDirectoryAtPath:destPath withIntermediateDirectories:YES attributes:nil error:NULL];
    if (success) {
      //dbPath = [self directoryForDB:dbName withPathOrNil:dbPath];
      //dbPath = [NSString stringWithFormat:@"%@/%@.tct", dbPath, dbName];
      TCTDB *db = [self openDB:backupFilePath writeMode:YES];
      tctdbcopy(db, [tcDestPath UTF8String]);
      tctdbclose(db);
      tcfree(db);
    }  
  });
  return YES;
}
-(void)restoreDB:(NSString *)dbName atPathOrNil:(NSString *)dbPath fromBackup:(NSString *)backupID andCompletionBlock:(void(^)(BOOL success))completionBlock{
  if (completionBlock != NULL) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      BOOL success = [self restoreDB:dbName atPathOrNil:dbPath fromBackup:backupID];
      if (completionBlock != NULL) {
        completionBlock(success);
      }
    });
    
  }
}
-(BOOL)backupDB:(NSString *)dbName atPathOrNil:(NSString *)dbPath{
  NSString *dbSig = [[self directoryForDB:dbName withPathOrNil:dbPath] MD5];
  NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
  
  [dateFormatter setDateFormat:@"yyyy-MM-dd HH.mm"];
  NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
  [dateFormatter release];
  
  NSString *backupPath = [NSString stringWithFormat:@"%@/%@-%@/%@", TSDB_BACKUP_DIR, dbName, dbSig, dateString];
  NSString *tcBackupPath = [NSString stringWithFormat:@"%@/%@.tct", backupPath, dbName];
  BOOL success = [[NSFileManager defaultManager]
                  createDirectoryAtPath:backupPath
                  withIntermediateDirectories:YES
                  attributes:nil
                  error:NULL];
  if (success) {
    dbPath = [self directoryForDB:dbName withPathOrNil:dbPath];
    dbPath = [NSString stringWithFormat:@"%@/%@.tct", dbPath, dbName];
    TCTDB *db = [self getDB:dbPath];
    tctdbcopy(db, [tcBackupPath UTF8String]);
    return YES;
  }
  return NO;
}
-(void)backupDB:(NSString *)dbName atPathOrNil:(NSString *)dbPath withCompletionBlock:(void(^)(BOOL success))completionBlock{
  BOOL success = [self backupDB:dbName atPathOrNil:dbPath];
  if (completionBlock != NULL) {
    completionBlock(success);
  }
}

-(NSArray *)listOfBackupsForDB:(NSString *)dbName newerThanDateOrNil:(NSDate *)date atPathOrNil:(NSString *)dbPath{
  NSFileManager *fm = [NSFileManager defaultManager];
  NSString *dbSig = [[self directoryForDB:dbName withPathOrNil:dbPath] MD5];
  NSString *backupPath = [NSString stringWithFormat:@"%@/%@-%@", TSDB_BACKUP_DIR, dbName, dbSig];
  NSArray *dirs = [fm contentsOfDirectoryAtPath:backupPath error:NULL];
  NSMutableArray *paths = [NSMutableArray array];
  BOOL exists;
  BOOL isDirectory;
  [fm changeCurrentDirectoryPath:backupPath];
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZZ"];

  for (NSString *dir in dirs) {
    NSDate *dirDate = [dateFormatter dateFromString:dir];
    exists = [fm fileExistsAtPath:dir isDirectory:&isDirectory];
    //NSLog(@"%@ d: %f z: %f", dir, [dirDate timeIntervalSince1970], [date timeIntervalSince1970]);
    if (exists && isDirectory && (date == nil || [dirDate timeIntervalSince1970] > [date timeIntervalSince1970])) {
      [paths addObject:dir];
    }
  }
  [dateFormatter release];
  if ([paths count]) {
    return paths;
  }
  return nil;
}
-(void)removeOlderBackupsForDB:(NSString *)dbName atPathOrNil:(NSString *)dbPath{
  NSFileManager *fm = [NSFileManager defaultManager];
  NSString *dbSig = [[self directoryForDB:dbName withPathOrNil:dbPath] MD5];
  NSString *backupPath = [NSString stringWithFormat:@"%@/%@-%@", TSDB_BACKUP_DIR, dbName, dbSig];
  NSArray *dirs = [self listOfBackupsForDB:dbName newerThanDateOrNil:nil atPathOrNil:nil];
  int numToDelete = [dirs count] - 10;
  NSString *dirPath = nil;
  for (int i=0; i < numToDelete; i++) {
    dirPath = [backupPath stringByAppendingPathComponent:[dirs objectAtIndex:i]];
    [fm removeItemAtPath:dirPath error:NULL];
  }
}
-(NSString *)backupDirForDB:(NSString *)dbName atPathOrNil:(NSString *)dbPath{
  NSString *dbSig = [[self directoryForDB:dbName withPathOrNil:dbPath] MD5];
  return [NSString stringWithFormat:@"%@/%@-%@", TSDB_BACKUP_DIR, dbName, dbSig];
}

@end
