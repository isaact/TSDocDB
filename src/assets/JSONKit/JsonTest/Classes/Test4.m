// -------------------------------------------------------
// Test4.m
//
// Copyright (c) 2010 Jakub Suder <jakub.suder@gmail.com>
// Licensed under WTFPL license
// -------------------------------------------------------

#import "Test4.h"
#import "YAJL/YAJL.h"

@implementation Test4

+ (NSDictionary *) parseJson: (NSString *) json {
  return [json yajl_JSON];
}

@end
