//
//  TSFileReader.m
//  TSTools
//
//  Created by Isaac Tewolde on 10-11-11.
//  Copyright 2010 Ticklespace.com All rights reserved.
//

#import "TSFileReader.h"

@interface NSData (DDAdditions)

- (NSRange) rangeOfData_dd:(NSData *)dataToFind;

@end

@implementation NSData (DDAdditions)

- (NSRange) rangeOfData_dd:(NSData *)dataToFind {
  
  const void * bytes = [self bytes];
  NSUInteger length = [self length];
  
  const void * searchBytes = [dataToFind bytes];
  NSUInteger searchLength = [dataToFind length];
  NSUInteger searchIndex = 0;
  
  NSRange foundRange = {NSNotFound, searchLength};
  for (NSUInteger index = 0; index < length; index++) {
    if (((char *)bytes)[index] == ((char *)searchBytes)[searchIndex]) {
      //the current character matches
      if (foundRange.location == NSNotFound) {
        foundRange.location = index;
      }
      searchIndex++;
      if (searchIndex >= searchLength) { return foundRange; }
    } else {
      searchIndex = 0;
      foundRange.location = NSNotFound;
    }
  }
  return foundRange;
}

@end

@implementation TSFileReader
@synthesize lineDelimiter, chunkSize;

- (id) initWithFilePath:(NSString *)aPath {
  self = [super init];
  if (self) {
    fileHandle = [NSFileHandle fileHandleForReadingAtPath:aPath];
    if (fileHandle == nil) {
      [self release]; return nil;
    }
    
    lineDelimiter = [[NSString alloc] initWithString:@"\n"];
    [fileHandle retain];
    filePath = [aPath retain];
    currentOffset = 0ULL;
    chunkSize = 10;
    [fileHandle seekToEndOfFile];
    totalFileLength = [fileHandle offsetInFile];
    //we don't need to seek back, since readLine will do that.
  }
  return self;
}

- (void) dealloc {
  [fileHandle closeFile];
  [fileHandle release], fileHandle = nil;
  [filePath release], filePath = nil;
  [lineDelimiter release], lineDelimiter = nil;
  currentOffset = 0ULL;
  [super dealloc];
}

- (NSString *) readLine {
  if (currentOffset >= totalFileLength) { return nil; }
  
  NSData * newLineData = [lineDelimiter dataUsingEncoding:NSUTF8StringEncoding];
  [fileHandle seekToFileOffset:currentOffset];
  NSMutableData * currentData = [[NSMutableData alloc] init];
  BOOL shouldReadMore = YES;
  
  NSAutoreleasePool * readPool = [[NSAutoreleasePool alloc] init];
  while (shouldReadMore) {
    if (currentOffset >= totalFileLength) { break; }
    NSData * chunk = [fileHandle readDataOfLength:chunkSize];
    NSRange newLineRange = [chunk rangeOfData_dd:newLineData];
    if (newLineRange.location != NSNotFound) {
      
      //include the length so we can include the delimiter in the string
      chunk = [chunk subdataWithRange:NSMakeRange(0, newLineRange.location+[newLineData length])];
      shouldReadMore = NO;
    }
    [currentData appendData:chunk];
    currentOffset += [chunk length];
  }
  [readPool drain];
  
  NSString * line = [[[NSString alloc] initWithData:currentData encoding:NSUTF8StringEncoding] autorelease];
  [currentData release];
  return line;
}

- (NSString *) readTrimmedLine {
  return [[self readLine] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

#if NS_BLOCKS_AVAILABLE
- (void) enumerateLinesUsingBlock:(void(^)(NSString *line, BOOL *stop, float progress))block {
  NSString * line = nil;
  BOOL stop = NO;
  line = [self readLine];
  [line retain];
  int currentLine = 0;
  float progress;
  while (stop == NO && (line)) {    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    if(totalFileLength > 0){
      progress = (float)currentOffset/(float)totalFileLength;
    }else{
      progress = 0;
    }
    block(line, &stop, progress);
    [pool drain];
    [line release];
    line = [self readLine];
    [line retain];
    currentLine++;
  }
  [line release];
}
#endif

@end
