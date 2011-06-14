//
//  DBLoadingPane.h
//  TSDocDB
//
//  Created by Isaac Tewolde on 11-06-13.
//  Copyright 2011 Ticklespace.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CityDBDelegate.h"

@interface DBLoadingPane : NSWindowController {

  IBOutlet NSTextField *operationName;
  IBOutlet NSProgressIndicator *operationProgress;
  IBOutlet NSTextField *operationDetails;
  CityDBDelegate *cityDBDelegate;

}

-(void)importDataModalToWindow:(NSWindow *)mainWindow;
@end
