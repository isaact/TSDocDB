// -------------------------------------------------------
// Test5.m
//
// Copyright (c) 2010 Jakub Suder <jakub.suder@gmail.com>
// Licensed under WTFPL license
// -------------------------------------------------------

#import "Test5.h"
#import "JSONKit.h"

@implementation Test5

+ (NSDictionary *) parseJson: (NSString *) json {
  return [json objectFromJSONString];
}

@end
