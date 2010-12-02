//
//  TSDBManager.h
//  TSDocDB
//
//  Created by Isaac Tewolde on 10-11-07.
//  Copyright 2010 Ticklespace.com. All rights reserved.
//

#import <Foundation/Foundation.h>

//TokyoCabinet Stuff
#include "tcutil.h"
#include "tctdb.h"


@interface TSDBManager : NSObject {
}
+(TSDBManager *)sharedDBManager;
+(NSString *)getDBError:(int)ecode;
+(NSString *)getQueueSigForDbPath:(NSString *)dbPath;
-(dispatch_queue_t)getQueueForDBPath:(NSString *)dbPath;
-(TCTDB *)getDB:(NSString *)dbFilePath;
-(void)recyleDBAtPath:(NSString *)dbFilePath;
-(void)removeDBFileAtPath:(NSString *)dbFilePath;
@end
