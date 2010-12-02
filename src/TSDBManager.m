//
//  TSDBManager.m
//  TSDocDB
//
//  Created by Isaac Tewolde on 10-11-07.
//  Copyright 2010 Ticklespace.com. All rights reserved.
//

#import "TSDBManager.h"
#import <Foundation/Foundation.h>

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
static TCMAP *dbQueues;
static dispatch_queue_t tsDBMainQueue;

+(TSDBManager *)sharedDBManager{
  dispatch_queue_t queue;
  queue = dispatch_queue_create([[TSDBManager getQueueSig] UTF8String], NULL);
  
  dispatch_sync(queue, ^{
    if (sharedDBManager == nil) {
      sharedDBManager = [[TSDBManager alloc] initTSDBManager];
    }
  });
  dispatch_release(queue);
  return sharedDBManager;
}

- (id) initTSDBManager
{
  self = [super init];
  if (self != nil) {
    /* create a new map object */
    tsDBs = tcmapnew();
    dbQueues = tcmapnew();
    tsDBMainQueue = dispatch_queue_create("com.ticklespace.tsdocdb", NULL);
  }
  return self;
}
#pragma mark -
#pragma mark Public Methods

-(TCTDB *)getDB:(NSString *)dbFilePath{
  __block TCTDB *tdb = NULL;
  dispatch_sync(tsDBMainQueue, ^{
    int sp;
    tdb = (TCTDB *)tcmapget(tsDBs, [dbFilePath UTF8String], strlen([dbFilePath UTF8String]), &sp);
    if (!tdb) {
      
      const char *queueKey = [[TSDBManager getQueueSigForDbPath:dbFilePath] UTF8String];
      dispatch_queue_t dbQueue = dispatch_queue_create(queueKey,NULL);
      tdb = [self getDBFromFile:dbFilePath];
      tcmapput(tsDBs, [dbFilePath UTF8String], strlen([dbFilePath UTF8String]), tdb, sizeof(TCTDB));
      tcmapput(dbQueues, queueKey, strlen(queueKey), dbQueue, sizeof(dispatch_queue_t));
      //tctdbdel(tdb);
      //tdb = (TCTDB *)tcmapget(tsDBs, [dbFilePath UTF8String], strlen([dbFilePath UTF8String]), &sp);
    }
    
  });
  return tdb;
}
-(void)recyleDBAtPath:(NSString *)dbFilePath{
  __block TCTDB *tdb = NULL;
  dispatch_sync(tsDBMainQueue, ^{
    int sp;
    tdb = (TCTDB *)tcmapget(tsDBs, [dbFilePath UTF8String], strlen([dbFilePath UTF8String]), &sp);
    if (tdb) {
      tctdbclose(tdb);
      tcmapout(tsDBs, [dbFilePath UTF8String], strlen([dbFilePath UTF8String]));
      tdb = [self getDBFromFile:dbFilePath];
      tcmapput(tsDBs, [dbFilePath UTF8String], strlen([dbFilePath UTF8String]), tdb, sizeof(TCTDB));
      //[dbQueues setObject:<#(id)anObject#> forKey:<#(id)aKey#>
      //tctdbdel(tdb);
      //tdb = (TCTDB *)tcmapget(tsDBs, [dbFilePath UTF8String], strlen([dbFilePath UTF8String]), &sp);
    }
    
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
  if(!tctdbopen(tdb, [dbPath UTF8String], HDBOWRITER | HDBOCREAT)){
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
    flags = TDBOWRITER;
  }else {
    flags = TDBOREADER;
  }
  
  /* open the database */
  if(!tctdbopen(tdb, [dbPath UTF8String], flags )){
    ecode = tctdbecode(tdb);
    ALog(@"DB open error:%@", [TSDBManager getDBError:ecode]);
    return NULL;
  }
  return tdb;
}

-(void)closeAllDBs{
  const char *key;
  int sp;
  TCTDB *db;
  tcmapiterinit(tsDBs);
  while((key = tcmapiternext2(tsDBs)) != NULL){
    db = (TCTDB *)tcmapget(tsDBs, key, strlen(key), &sp);
    tctdbclose(db);
    tcmapout(tsDBs, key, strlen(key));
  }
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
@end
