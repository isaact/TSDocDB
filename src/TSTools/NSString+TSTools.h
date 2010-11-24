//
//  NSString+TSTools.h
//  TSTools
//
//  Created by Isaac Tewolde on 10-11-11.
//  Copyright 2010 Ticklespace.com All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString(TSTools)

+(NSString *)cleanValue:(id)rawValue;
+(NSString *)joinStrings :(NSArray *)strings glue:(NSString *)glue;
+(NSString *)joinStringsFromDictionary:(NSDictionary *)dict andTargetCols:(NSArray *)keys glue:(NSString *)glue;
+(NSString *)getDeviceType;

- (NSString *) MD5;

@end
