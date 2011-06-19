//
//  SampleApp_OSXAppDelegate.h
//  SampleApp.OSX
//
//  Created by Isaac Tewolde on 11-06-11.
//  Copyright 2011 Ticklespace.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CityDBDelegate.h"
@interface SampleApp_OSXAppDelegate : NSObject <NSApplicationDelegate, NSTableViewDelegate> {
  
  IBOutlet NSSearchField *countrySearchField;
  IBOutlet NSSearchField *citySearchField;
  IBOutlet NSArrayController *cityArrayController;
  IBOutlet NSArrayController *countryArrayController;
  
  IBOutlet NSTableView *countryTable;
  IBOutlet NSTableView *cityTable;
  CityDBDelegate *cityDBDelegate;
  NSDictionary *selectedCountry;
  NSInteger opCount, opCount2, lastCountry;
@private
  NSWindow *window;

}

@property (assign) IBOutlet NSWindow *window;
- (IBAction)filterCityList:(id)sender;
- (IBAction)filterCountryList:(id)sender;
@end
