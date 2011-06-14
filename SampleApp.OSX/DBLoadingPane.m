//
//  DBLoadingPane.m
//  TSDocDB
//
//  Created by Isaac Tewolde on 11-06-13.
//  Copyright 2011 Ticklespace.com. All rights reserved.
//

#import "DBLoadingPane.h"

@interface DBLoadingPane()
-(void)importCities;
-(void)importCountries;
@end
@implementation DBLoadingPane

-(NSString *)windowNibName{
  return @"DBLoadingPane";
}
-(id)initWithWindow:(NSWindow *)window{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)dealloc{
  [cityDBDelegate release];
    [super dealloc];
}

-(void)windowDidLoad{
    [super windowDidLoad];
}
-(void)awakeFromNib{
}

-(void)importDataModalToWindow:(NSWindow *)mainWindow{
  [NSApp beginSheet:self.window modalForWindow:mainWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [self importCountries];
    [self importCities];
  });

	[NSApp runModalForWindow:self.window];

}
-(void)importCities{
  NSWindow *window = self.window;
  if (cityDBDelegate == nil) {
    cityDBDelegate = [[CityDBDelegate alloc] init];
  }
  [operationName setStringValue:@"Importing Cities"];
  __block int count = 0;
  [cityDBDelegate importCitiesWithProgressBlock:^(NSDictionary *city, BOOL *stop, float progress) {
    dispatch_sync(dispatch_get_main_queue(), ^{
      [operationProgress setDoubleValue:progress];
      [operationDetails setStringValue:[NSString stringWithFormat:@"Imported %d cities so far", count]];
      count++;
      if (progress == 1.0) {
        [operationProgress setIndeterminate:YES];
        [operationDetails setStringValue:@"Finishing up..."];
      }
    });
  }];
  [NSApp stopModal];
  [NSApp endSheet:window];
	[window orderOut:nil];
}
-(void)importCountries{
  if (cityDBDelegate == nil) {
    cityDBDelegate = [[CityDBDelegate alloc] init];
  }
  [operationName setStringValue:@"Importing Countries"];
  __block int count = 0;
  [cityDBDelegate importCountriesWithProgressBlock:^(NSDictionary *country, BOOL *stop, float progress) {
    dispatch_sync(dispatch_get_main_queue(), ^{
      [operationProgress setDoubleValue:progress];
      [operationDetails setStringValue:[NSString stringWithFormat:@"Imported %d countries so far", count]];
      count++;
    });
  }];
}

@end
