//
//  SampleApp_OSXAppDelegate.m
//  SampleApp.OSX
//
//  Created by Isaac Tewolde on 11-06-11.
//  Copyright 2011 Ticklespace.com. All rights reserved.
//

#import "SampleApp_OSXAppDelegate.h"
#import "DBLoadingPane.h"
#import "TSDBManager.h"
#import "TSSearchField.h"

@implementation SampleApp_OSXAppDelegate

@synthesize window;

-(void)applicationDidFinishLaunching:(NSNotification *)aNotification{
  useTSSearchField();
  cityDBDelegate = [[CityDBDelegate alloc] init];
  lastCountry = -1;
  if ([cityDBDelegate.geonamesDB getNumRowsOfType:@"city"] == 0) {
    DBLoadingPane *loadingWindow = [[DBLoadingPane alloc] init];
    [loadingWindow importDataModalToWindow:self.window];
    [loadingWindow release];
  }
  [cityDBDelegate.geonamesDB setOrderByStringForColumn:@"Country" isAscending:YES];
  [cityDBDelegate.geonamesDB doSearchWithProcessingBlock:^BOOL(id row) {
    [countryArrayController addObject:row];
    return NO;
  } withLimit:300 andOffset:0 forRowTypes:@"country", nil];
  [countryArrayController rearrangeObjects];
  
  [cityDBDelegate.geonamesDB setOrderByStringForColumn:@"Country" isAscending:YES];
  [cityDBDelegate.geonamesDB doSearchWithProcessingBlock:^BOOL(id row) {
    [cityArrayController addObject:row];
    return NO;
  } withLimit:50 andOffset:0 forRowTypes:@"city", nil];
  [cityArrayController rearrangeObjects];
  
  [countryArrayController addObserver: self
                   forKeyPath: @"selectionIndexes"
                      options: NSKeyValueObservingOptionNew
                      context: NULL];
}
-(void)applicationWillTerminate:(NSNotification *)notification{
  [TSDBManager closeAll];
}
-(void)dealloc {
  [cityDBDelegate release];
  [super dealloc];
}
#pragma mark -
#pragma mark KVO methods
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
  if ([[object selectedObjects] count]) {
    selectedCountry = [[object selectedObjects] objectAtIndex:0];
    if ([[selectedCountry objectForKey:@"geonameid"] intValue] != lastCountry) {
      lastCountry = [[selectedCountry objectForKey:@"geonameid"] intValue];
      [self filterCityList:nil];
    }
  }else{
    selectedCountry = nil;
    if(lastCountry != -1){
      [self filterCityList:nil];
      lastCountry = -1;
    }
  }
}
-(IBAction)filterCityList:(id)sender{
  opCount++;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSInteger op= opCount;
    [cityDBDelegate.geonamesDB clearFilters];
    if ([[citySearchField stringValue] length] > 0) {
      [cityDBDelegate.geonamesDB addConditionRowContainsString:[citySearchField stringValue]];
    }else if (selectedCountry != nil) {
      [cityDBDelegate.geonamesDB addConditionStringEquals:[selectedCountry objectForKey:@"ISO"] toColumn:@"country code"];
    }
    NSInteger currentListSize = [[cityArrayController content] count];
    __block NSInteger count = 0;
    __block BOOL stop;
    [cityDBDelegate.geonamesDB setOrderByStringForColumn:@"Country" isAscending:YES];
    [cityDBDelegate.geonamesDB doSearchWithProcessingBlock:^BOOL(id row) {
      dispatch_sync(dispatch_get_main_queue(), ^{
        if(op == opCount){
          stop=NO;
          if (count < currentListSize) {
            [[cityArrayController content] replaceObjectAtIndex:count withObject:row];
          }else{
            [cityArrayController addObject:row];
          }
          count++;
        }else{
          stop=YES;
        }
      });
      return stop;
    } withLimit:50 andOffset:0 forRowTypes:@"city", nil];
    dispatch_sync(dispatch_get_main_queue(), ^{
      if (op == opCount && count < currentListSize) {
        NSRange range;
        range.location = count;
        range.length = currentListSize - count;
        [[cityArrayController content] removeObjectsInRange:range];
      }
      [cityArrayController rearrangeObjects];
    });
  });
}
-(IBAction)filterCountryList:(id)sender{
  opCount2++;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    NSInteger op= opCount2;
    [cityDBDelegate.geonamesDB clearFilters];
    if ([[countrySearchField stringValue] length] > 0) {
      [cityDBDelegate.geonamesDB addConditionRowContainsString:[countrySearchField stringValue]];
    }
    NSInteger currentListSize = [[countryArrayController content] count];
    __block NSInteger count = 0;
    __block BOOL stop;
    [cityDBDelegate.geonamesDB setOrderByStringForColumn:@"Country" isAscending:YES];
    [cityDBDelegate.geonamesDB doSearchWithProcessingBlock:^BOOL(id row) {
      dispatch_sync(dispatch_get_main_queue(), ^{
        if(op == opCount2){
          stop=NO;
          if (count < currentListSize) {
            [[countryArrayController content] replaceObjectAtIndex:count withObject:row];
          }else{
            [countryArrayController addObject:row];
          }
          count++;
        }else{
          stop=YES;
        }
      });
      return stop;
    } withLimit:300 andOffset:0 forRowTypes:@"country", nil];
    dispatch_sync(dispatch_get_main_queue(), ^{
      if (op == opCount2 && count < currentListSize) {
        NSRange range;
        range.location = count;
        range.length = currentListSize - count;
        [[countryArrayController content] removeObjectsInRange:range];
      }
      [countryArrayController rearrangeObjects];
    });
  });
}
@end
