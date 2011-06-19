//
//  SampleApp_iOSAppDelegate.h
//  SampleApp-iOS
//
//  Created by Din on 11-06-17.
//  Copyright 2011 Ticklespace.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CountryTableViewController.h"
@interface SampleApp_iOSAppDelegate : NSObject <UIApplicationDelegate> {

  IBOutlet CountryTableViewController *countryTableVC;
  UINavigationController *navController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navController;
@end
