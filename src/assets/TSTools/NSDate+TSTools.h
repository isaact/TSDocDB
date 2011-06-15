//
//  NSDate+TSTools.h
//  TSTools
//
//  Created by Isaac Tewolde on 10-11-11.
//  Copyright 2010 Ticklespace.com All rights reserved.
//

#import <Foundation/Foundation.h>

void useTSDateTools();
@interface NSDate(TSTools)

+(NSString *)friendlyDateFromString:(NSString *)theDate;
+(NSInteger)numberOfWeekdaysBetweenFromThisDate:(NSDate *)date toThisDate:(NSDate *)otherDate;
-(NSInteger)weekdaysToDateOrNil:(NSDate *)theDate;
-(BOOL)isToday;
-(BOOL)isYesterday;
-(NSString *)friendlyDate;

@end
