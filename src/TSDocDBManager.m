//
//  TSDocDBManager.m
//  TSDocDB
//
//  Created by Isaac Tewolde on 10-11-07.
//  Copyright 2010 Ticklespace.com. All rights reserved.
//

#import "TSDocDBManager.h"
#import <Foundation/Foundation.h>

@interface TSDocDBManager()

-(id)initDocDBManager;

#pragma mark -
#pragma mark Utility Methods
-(TCTDB *)createDB:(NSString *)dbPath;
-(TCTDB *)openDB:(NSString *)dbPath writeMode:(BOOL)writeMode;
-(TCTDB *)getDBFromFile:(NSString *)dbFilePath;
-(void)closeAllDBs;
+(NSString *)getQueueSig;
@end

@implementation TSDocDBManager

static TSDocDBManager *sharedDBManager = nil;
static TCMAP *docDBs = NULL;
static TCMAP *dbQueues;
static dispatch_queue_t tsDocDBMainQueue;

+(TSDocDBManager *)sharedDBManager{
  dispatch_queue_t queue;
  queue = dispatch_queue_create([[TSDocDBManager getQueueSig] UTF8String], NULL);
  
  dispatch_sync(queue, ^{
    if (sharedDBManager == nil) {
      sharedDBManager = [[TSDocDBManager alloc] initDocDBManager];
    }
  });
  dispatch_release(queue);
  return sharedDBManager;
}

- (id) initDocDBManager
{
  self = [super init];
  if (self != nil) {
    /* create a new map object */
    docDBs = tcmapnew();
    dbQueues = tcmapnew();
    tsDocDBMainQueue = dispatch_queue_create("com.ticklespace.tsdocdb", NULL);
  }
  return self;
}
#pragma mark -
#pragma mark Public Methods

-(TCTDB *)getDB:(NSString *)dbFilePath{
  __block TCTDB *tdb = NULL;
  dispatch_sync(tsDocDBMainQueue, ^{
    int sp;
    tdb = (TCTDB *)tcmapget(docDBs, [dbFilePath UTF8String], strlen([dbFilePath UTF8String]), &sp);
    if (!tdb) {
      
      const char *queueKey = [[TSDocDBManager getQueueSigForDbPath:dbFilePath] UTF8String];
      dispatch_queue_t dbQueue = dispatch_queue_create(queueKey,NULL);
      tdb = [self getDBFromFile:dbFilePath];
      tcmapput(docDBs, [dbFilePath UTF8String], strlen([dbFilePath UTF8String]), tdb, sizeof(TCTDB));
      tcmapput(dbQueues, queueKey, strlen(queueKey), dbQueue, sizeof(dispatch_queue_t));
      //tctdbdel(tdb);
      //tdb = (TCTDB *)tcmapget(docDBs, [dbFilePath UTF8String], strlen([dbFilePath UTF8String]), &sp);
    }
    
  });
  return tdb;
}
-(void)recyleDBAtPath:(NSString *)dbFilePath{
  __block TCTDB *tdb = NULL;
  dispatch_sync(tsDocDBMainQueue, ^{
    int sp;
    tdb = (TCTDB *)tcmapget(docDBs, [dbFilePath UTF8String], strlen([dbFilePath UTF8String]), &sp);
    if (tdb) {
      tctdbclose(tdb);
      tcmapout(docDBs, [dbFilePath UTF8String], strlen([dbFilePath UTF8String]));
      tdb = [self getDBFromFile:dbFilePath];
      tcmapput(docDBs, [dbFilePath UTF8String], strlen([dbFilePath UTF8String]), tdb, sizeof(TCTDB));
      //[dbQueues setObject:<#(id)anObject#> forKey:<#(id)aKey#>
      //tctdbdel(tdb);
      //tdb = (TCTDB *)tcmapget(docDBs, [dbFilePath UTF8String], strlen([dbFilePath UTF8String]), &sp);
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
  const char *queueKey = [[TSDocDBManager getQueueSigForDbPath:dbPath] UTF8String];
  int sp;
  //return (dispatch_queue_t)tcmapget(dbQueues, queueKey, strlen(queueKey), &sp);
  return tsDocDBMainQueue;
}

-(TCTDB *)createDB:(NSString *)dbPath{
  TCTDB *tdb;
  int ecode;
  
  /* create the object */
  tdb = tctdbnew();
  
  /* open the database */
  if(!tctdbopen(tdb, [dbPath UTF8String], HDBOWRITER | HDBOCREAT)){
    ecode = tctdbecode(tdb);
    ALog(@"DB create error:%@", [TSDocDBManager getDBError:ecode]);
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
    ALog(@"DB open error:%@", [TSDocDBManager getDBError:ecode]);
    return NULL;
  }
  return tdb;
}

-(void)closeAllDBs{
  const char *key;
  int sp;
  TCTDB *db;
  tcmapiterinit(docDBs);
  while((key = tcmapiternext2(docDBs)) != NULL){
    db = (TCTDB *)tcmapget(docDBs, key, strlen(key), &sp);
    tctdbclose(db);
    tcmapout(docDBs, key, strlen(key));
  }
  tcmapdel(docDBs);
  
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
