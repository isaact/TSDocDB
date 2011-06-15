//
//  NSDate+TSTools.h
//  TSTools
//
//  Created by Isaac Tewolde on 10-11-11.
//  Copyright 2010 Ticklespace.com All rights reserved.
//

#import "NSDate+TSTools.h"

void useTSDateTools(){
  
}
@implementation NSDate(TSTools)
+(NSString *)friendlyDateFromString:(NSString *)theDate{
  NSDate *date = [NSDate dateWithString:theDate];
  NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
  [dateFormatter setDateStyle:NSDateFormatterNoStyle];
  [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
  //NSLog(@">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>%@", theDate);
  if ([date isToday]) {
    return [NSString stringWithFormat:@"Today\n%@", [dateFormatter stringFromDate:date]];
  }else if ([date isYesterday]) {
    return [NSString stringWithFormat:@"Yesterday\n%@", [dateFormatter stringFromDate:date]];
  }else if ([date timeIntervalSince1970] > 0) {
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    //return [NSString stringWithFormat:@"Shipped: %@\n(%d business days)", [dateFormatter stringFromDate:shippedDate], [date weekdaysToDateOrNil:nil]]];
    return [dateFormatter stringFromDate:date];
  }
  return @"Invalid date";
}

+(NSInteger)numberOfWeekdaysBetweenFromThisDate:(NSDate *)date toThisDate:(NSDate *)otherDate{
  
  NSDate *startDate, *endDate;
  if ([date timeIntervalSince1970] < [otherDate timeIntervalSince1970]) {
    startDate = date;
    endDate = otherDate;
  } else {
    startDate = otherDate;
    endDate = date;
  }
  NSInteger weeksBetween = [[[NSCalendar currentCalendar] components: NSWeekCalendarUnit
                                                            fromDate: startDate
                                                              toDate: endDate
                                                             options: 0] week];
  
  NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
  NSDateComponents *startWeekdayComponents = [gregorian components:(NSDayCalendarUnit | NSWeekdayCalendarUnit) fromDate:startDate];
  NSDateComponents *endWeekdayComponents = [gregorian components:(NSDayCalendarUnit | NSWeekdayCalendarUnit) fromDate:endDate];
  
  NSInteger startWeekDay = [startWeekdayComponents weekday];
  NSInteger endWeekDay = [endWeekdayComponents weekday];
  NSInteger adjust = 0;
  if (startWeekDay == endWeekDay) {
    adjust = 0;
  } else if (startWeekDay == 1 && endWeekDay == 7) {
    adjust = 5;
  } else if (startWeekDay == 7 && endWeekDay == 1) {
    adjust = 0;
  } else if (endWeekDay == 7 || endWeekDay == 1) {
    adjust = 5-startWeekDay;
  } else if (startWeekDay == 1 || startWeekDay == 7) {
    adjust = endWeekDay;
  } else if (endWeekDay > startWeekDay ) {
    adjust = endWeekDay-startWeekDay;
  } else {
    adjust = 5+endWeekDay-startWeekDay;
  }
  [gregorian release];
  return (weeksBetween * 5) + adjust;
}

-(BOOL)isToday{
  NSDate *today = [NSDate date];
  NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
  [dateFormatter setDateFormat:@"yyyy-MM-dd"];
  return ([[dateFormatter stringFromDate:today] isEqualToString:[dateFormatter stringFromDate:self]]);
  
}

-(BOOL)isYesterday{
  NSDate *today = [NSDate date];
  NSDate *yesterday = [today dateByAddingTimeInterval:-86400.0];
  NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
  [dateFormatter setDateFormat:@"yyyy-MM-dd"];
  return ([[dateFormatter stringFromDate:yesterday] isEqualToString:[dateFormatter stringFromDate:self]]);
}

-(NSString *)friendlyDate{
  //NSDate *date = [NSDate dateWithString:[NSString stringWithFormat:@"%@ -0600", theDate]];
  NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
  [dateFormatter setDateStyle:NSDateFormatterNoStyle];
  [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
  if ([self isToday]) {
    return [NSString stringWithFormat:@"Today %@", [dateFormatter stringFromDate:self]];
  }else if ([self isYesterday]) {
    return [NSString stringWithFormat:@"Yesterday %@", [dateFormatter stringFromDate:self]];
  }else if ([self timeIntervalSince1970] > 0) {
    [dateFormatter setDateStyle:NSDateFormatterLongStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    //return [NSString stringWithFormat:@"Shipped: %@\n(%d business days)", [dateFormatter stringFromDate:shippedDate], [date weekdaysToDateOrNil:nil]]];
    return [dateFormatter stringFromDate:self];
  }
  return @"Invalid date";
}

-(NSInteger)weekdaysToDateOrNil:(NSDate *)theDate{
  if (theDate == nil) {
    theDate = [NSDate date];
  }
  return [NSDate numberOfWeekdaysBetweenFromThisDate:self toThisDate:theDate];
}


@end
