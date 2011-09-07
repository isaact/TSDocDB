// -------------------------------------------------------
// Test3.m
//
// Copyright (c) 2010 Jakub Suder <jakub.suder@gmail.com>
// Licensed under WTFPL license
// -------------------------------------------------------

#import "Test3.h"
#import "CJSONDeserializer.h"

@implementation Test3

+ (NSDictionary *) parseJson: (NSString *) json {
  NSData *jsonData = [json dataUsingEncoding: NSUTF32BigEndianStringEncoding];
  return [[CJSONDeserializer deserializer] deserializeAsDictionary: jsonData error: nil];
}

@end
