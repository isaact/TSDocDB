//
//  TSFileReader.h
//  TSTools
//
//  Created by Isaac Tewolde on 10-11-11.
//  Copyright 2010 Ticklespace.com All rights reserved.
//

#import <Foundation/Foundation.h>
void useTSTSFileReader();
@interface TSFileReader : NSObject {
  NSString * filePath;
  
  NSFileHandle * fileHandle;
  unsigned long long currentOffset;
  unsigned long long totalFileLength;
  
  NSString * lineDelimiter;
  NSUInteger chunkSize;
}

@property (nonatomic, copy) NSString * lineDelimiter;
@property (nonatomic) NSUInteger chunkSize;

- (id) initWithFilePath:(NSString *)aPath;

- (NSString *) readLine;
- (NSString *) readTrimmedLine;

#if NS_BLOCKS_AVAILABLE
- (void) enumerateLinesUsingBlock:(void(^)(NSString *line, BOOL *stop, float progress))block ;
#endif

@end


