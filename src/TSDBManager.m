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

@interface TSDBManager()

-(id)initTSDBManager;

#pragma mark -
#pragma mark Utility Methods
-(TCTDB *)createDB:(NSString *)dbPath;
-(TCTDB *)openDB:(NSString *)dbPath writeMode:(BOOL)writeMode;
-(TCTDB *)getDBFromFile:(NSString *)dbFilePath;
-(void)closeAllDBs;
+(NSString *)getQueueSig;
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
      //tctdboptimize(tdb, 1310710, -1, -1, TDBTLARGE);
      tctdbsetindex(tdb, "_TSDB.TXT", TDBITQGRAM);
      tctdbsetindex(tdb, "_TSDB.DT", TDBITLEXICAL);
      tcmapput(tsDBs, [dbFilePath UTF8String], (int)strlen([dbFilePath UTF8String]), tdb, sizeof(TCTDB));
      //tcmapput(dbQueues, queueKey, strlen(queueKey), dbQueue, sizeof(dispatch_queue_t));
      //tctdbdel(tdb);
      //tdb = (TCTDB *)tcmapget(tsDBs, [dbFilePath UTF8String], strlen([dbFilePath UTF8String]), &sp);
    }
    
  });
  //tctdbsetcache(tdb, -1, 10, 10);
  //tctdbsetxmsiz(tdb, 6710886);
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

-(void)removeDBFileAtPath:(NSString *)dbFilePath{
  __block TCTDB *tdb = NULL;
  dispatch_sync(tsDBManagerQueue, ^{
    int sp;
    tdb = (TCTDB *)tcmapget(tsDBs, [dbFilePath UTF8String], (int)strlen([dbFilePath UTF8String]), &sp);
    if (tdb) {
      tctdbclose(tdb);
      tcmapout(tsDBs, [dbFilePath UTF8String], (int)strlen([dbFilePath UTF8String]));
    }
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:dbFilePath error:NULL];
  });
}
#pragma mark -
#pragma mark Utility Methods
+(NSString *)getDBError:(int)ecode{
  return [NSString stringWithUTF8String:tctdberrmsg(ecode)];
}
+(NSString *)getQueueSig{
  return [NSString stringWithString:@"com.ticklespace.tsdocdb"];
}
+(NSString *)getQueueSigForDbPath:(NSString *)dbPath{
  return [NSString stringWithFormat:@"tsqueue-%d", [dbPath hash]];
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
  
  /* open the database */
  if(!tctdbopen(tdb, [dbPath UTF8String], TDBOWRITER | TDBOCREAT|TDBOTSYNC)){
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
  if (writeMode) {
    flags = TDBOWRITER|TDBOTSYNC;
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
    tctdbsync(db);
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
  //tctdbtune(tdb, 13107100, -1, -1, TDBTLARGE);
  return tdb;
}

- (void) dealloc{
  [self closeAllDBs];
  [sharedDBManager release];
  [super dealloc];
}
@end
