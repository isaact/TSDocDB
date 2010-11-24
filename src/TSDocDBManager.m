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
+(const char *)getQueueSig;
@end

@implementation TSDocDBManager

static TSDocDBManager *sharedDBManager = nil;
static TCMAP *docDBs = NULL;
+(TSDocDBManager *)sharedDBManager{
  dispatch_queue_t queue;
  queue = dispatch_queue_create([TSDocDBManager getQueueSig], NULL);
  
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
  }
  return self;
}
#pragma mark -
#pragma mark Public Methods

-(TCTDB *)getDB:(NSString *)dbFilePath{
  dispatch_queue_t queue;
  queue = dispatch_queue_create([TSDocDBManager getQueueSig], NULL);
  __block TCTDB *tdb = NULL;
  dispatch_sync(queue, ^{
    int sp;
    tdb = (TCTDB *)tcmapget(docDBs, [dbFilePath UTF8String], strlen([dbFilePath UTF8String]), &sp);
    if (!tdb) {
      tdb = [self getDBFromFile:dbFilePath];
      tcmapput(docDBs, [dbFilePath UTF8String], strlen([dbFilePath UTF8String]), tdb, sizeof(TCTDB));
      //tctdbdel(tdb);
      //tdb = (TCTDB *)tcmapget(docDBs, [dbFilePath UTF8String], strlen([dbFilePath UTF8String]), &sp);
    }
    
  });
  dispatch_release(queue);
  return tdb;
}
-(void)recyleDBAtPath:(NSString *)dbFilePath{
  dispatch_queue_t queue;
  queue = dispatch_queue_create([TSDocDBManager getQueueSig], NULL);
  __block TCTDB *tdb = NULL;
  dispatch_sync(queue, ^{
    int sp;
    tdb = (TCTDB *)tcmapget(docDBs, [dbFilePath UTF8String], strlen([dbFilePath UTF8String]), &sp);
    if (tdb) {
      tctdbclose(tdb);
      tcmapout(docDBs, [dbFilePath UTF8String], strlen([dbFilePath UTF8String]));
      tdb = [self getDBFromFile:dbFilePath];
      tcmapput(docDBs, [dbFilePath UTF8String], strlen([dbFilePath UTF8String]), tdb, sizeof(TCTDB));
      //tctdbdel(tdb);
      //tdb = (TCTDB *)tcmapget(docDBs, [dbFilePath UTF8String], strlen([dbFilePath UTF8String]), &sp);
    }
    
  });
  dispatch_release(queue);
  
}
#pragma mark -
#pragma mark Utility Methods
+(NSString *)getDBError:(int)ecode{
  return [NSString stringWithUTF8String:tctdberrmsg(ecode)];
}
+(const char *)getQueueSig{
  return [[NSString stringWithString:@"com.ticklespace.tsdocdb"] UTF8String];
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
