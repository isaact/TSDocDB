//
//  NSString+TSTools.m
//  TSTools
//
//  Created by Isaac Tewolde on 10-11-11.
//  Copyright 2010 Ticklespace.com All rights reserved.
//



#import "NSString+TSTools.h"
#import <CommonCrypto/CommonDigest.h>
#include <sys/utsname.h>

@implementation NSString(TSTools)

#pragma mark -
#pragma mark Class Methods
+(NSString *)cleanValue:(id)rawValue{
	NSMutableString *cleanedVal;
	NSString *finalString = @"";
	if([rawValue isKindOfClass:[NSString class]]){
		cleanedVal = [[[NSMutableString alloc] initWithString:rawValue] autorelease];
		[cleanedVal replaceOccurrencesOfString:@"'" withString:@"''" options:NSLiteralSearch range:NSMakeRange(0, [cleanedVal length])];
		finalString = [[[NSString alloc] initWithFormat:@"'%@'", cleanedVal] autorelease];
	}else if ([rawValue isKindOfClass:[NSNumber class]]) {
		finalString = [rawValue stringValue];
	}else if ([rawValue isKindOfClass:[NSDate class]]) {
		NSTimeInterval timestamp= [rawValue timeIntervalSince1970];
		finalString = [[[NSString alloc] initWithFormat:@"datetime(%f, 'unixepoch')", timestamp] autorelease];
	}
	return finalString;
}

+(NSString *)joinStrings :(NSArray *)strings glue:(NSString *)glue{
	NSMutableString *joinedString = [NSMutableString stringWithString:@""];
	NSInteger count = 0;
	for(id string in strings){
		if(count >0){
			[joinedString appendString:glue];
		}
		if([string isKindOfClass:[NSString class]]){
			[joinedString appendString:string];
			count++;
		}		
	}
	return joinedString;
}
+(NSString *)joinStringsFromDictionary:(NSDictionary *)dict andTargetCols:(NSArray *)keys glue:(NSString *)glue{
  NSArray *strings = [dict objectsForKeys:keys notFoundMarker:@" "];
  return [NSString joinStrings:strings glue:glue];
}
+(NSString *)getDeviceType{
  struct utsname systemInfo;
  uname(&systemInfo);
  NSString *str = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
  return str;
  
}

#pragma mark -
#pragma mark instance methods

- (NSString *) MD5 
{
  const char *cStr = [self UTF8String];
  unsigned char result[16];
  CC_MD5( cStr, strlen(cStr), result );
  return [NSString stringWithFormat:
          @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
          result[0], result[1], result[2], result[3], 
          result[4], result[5], result[6], result[7],
          result[8], result[9], result[10], result[11],
          result[12], result[13], result[14], result[15]
          ];  
}

@end
