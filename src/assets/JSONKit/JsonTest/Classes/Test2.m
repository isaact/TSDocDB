// -------------------------------------------------------
// Test2.m
//
// Copyright (c) 2010 Jakub Suder <jakub.suder@gmail.com>
// Licensed under WTFPL license
// -------------------------------------------------------

#import "Test2.h"
#import "JSON.h"

@implementation Test2

+ (NSDictionary *) parseJson: (NSString *) json {
  return [json JSONValue];
}

@end
