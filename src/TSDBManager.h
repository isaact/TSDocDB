//
//  TSDBManager.h
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

#import <Foundation/Foundation.h>

//TokyoCabinet Stuff

#include "tcutil.h"
#include "tctdb.h"


@interface TSDBManager : NSObject {
}
+(TSDBManager *)sharedDBManager;
+(NSString *)getDBError:(int)ecode;
+(NSString *)getQueueSigForDbPath:(NSString *)dbPath;
+(void)closeAll;
-(dispatch_queue_t)getQueueForDBPath:(NSString *)dbPath;
-(TCTDB *)getDB:(NSString *)dbFilePath;
-(void)recyleDBAtPath:(NSString *)dbFilePath;
-(void)removeDB:(NSString *)dbName atPathOrNil:(NSString *)dbContainerPathOrNil;

//Backup methods
-(BOOL)restoreDB:(NSString *)dbName atPathOrNil:(NSString *)dbPath fromBackup:(NSString *)backupID;
-(void)restoreDB:(NSString *)dbName atPathOrNil:(NSString *)dbPath fromBackup:(NSString *)backupID andCompletionBlock:(void(^)(BOOL success))completionBlock;
-(BOOL)backupDB:(NSString *)dbName atPathOrNil:(NSString *)dbPath;
-(void)backupDB:(NSString *)dbName atPathOrNil:(NSString *)dbPath withCompletionBlock:(void(^)(BOOL success))completionBlock;
-(NSArray *)listOfBackupsForDB:(NSString *)dbName newerThanDateOrNil:(NSDate *)date atPathOrNil:(NSString *)dbPath;

@end
