//
//  SampleApp_iOSAppDelegate.m
//  SampleApp-iOS
//
//  Created by Din on 11-06-17.
//  Copyright 2011 Ticklespace.com. All rights reserved.
//

#import "SampleApp_iOSAppDelegate.h"
#import "DBImportViewController.h"

@implementation SampleApp_iOSAppDelegate


@synthesize window, navController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  // Override point for customization after application launch.
  [self.window makeKeyAndVisible];
  NSString *nibSuffix = @"";
  if (isIpad()) {
    nibSuffix = @"-iPad";
  }
  //DBImportViewController *dbvc = [[DBImportViewController alloc] initWithNibName:[NSString stringWithFormat:@"DBImportViewController%@", nibSuffix] bundle:nil];
  //
  //[self.window addSubview:rootViewController.view];
  //[dbvc pre
  //[dbvc release];
  // Create and configure the main view controller.
  CountryTableViewController *rootViewController = [[CountryTableViewController alloc] initWithNibName:[NSString stringWithFormat:@"CountryTableViewController%@", nibSuffix] bundle:[NSBundle mainBundle]];
	
	// Add create and configure the navigation controller.
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:rootViewController];
	self.navController = navigationController;
	[rootViewController release];
	[navigationController release];
	
	// Configure and display the window.
	[window addSubview:navController.view];
	[window makeKeyAndVisible];

  //DBImportViewController *dbvc = [[DBImportViewController alloc] initWithNibName:[NSString stringWithFormat:@"DBImportViewController%@", nibSuffix] bundle:nil];
  //[navController presentModalViewController:dbvc animated:YES];
  //[dbvc release];
  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
  /*
   Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
   Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
   */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  /*
   Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
   If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
   */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
  /*
   Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
   */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  /*
   Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
   */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
  /*
   Called when the application is about to terminate.
   Save data if appropriate.
   See also applicationDidEnterBackground:.
   */
}

- (void)dealloc
{
  [window release];
  [navController release];
  [countryTableVC release];
  [super dealloc];
}

@end
