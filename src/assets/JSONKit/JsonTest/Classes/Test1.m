// -------------------------------------------------------
// Test1.m
//
// Copyright (c) 2010 Jakub Suder <jakub.suder@gmail.com>
// Licensed under WTFPL license
// -------------------------------------------------------

#import "Test1.h"
#import "NSDictionary+BSJSONAdditions.h"

@implementation Test1

+ (NSDictionary *) parseJson: (NSString *) json {
  return [NSDictionary dictionaryWithJSONString: json];
}

@end
