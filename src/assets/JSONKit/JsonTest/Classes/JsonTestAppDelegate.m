// -------------------------------------------------------
// JsonTestAppDelegate.m
//
// Copyright (c) 2010 Jakub Suder <jakub.suder@gmail.com>
// Licensed under WTFPL license
// -------------------------------------------------------

#import "JsonTestAppDelegate.h"
#import "JsonTestViewController.h"

#import "Test1.h"
#import "Test2.h"
#import "Test3.h"
#import "Test4.h"
#import "Test5.h"

@implementation JsonTestAppDelegate

@synthesize window;
@synthesize viewController;

- (void) applicationDidFinishLaunching: (UIApplication *) application {
  [window addSubview:viewController.view];
  [window makeKeyAndVisible];

  NSString *jsonPath = [[NSBundle mainBundle] pathForResource: @"sample_json" ofType: @"txt"];
  NSString *json = [NSString stringWithContentsOfFile: jsonPath encoding: NSUTF8StringEncoding error: nil];

  // test 1
  NSDate *start1 = [NSDate date];
  NSDictionary *bsjson = [Test1 parseJson: json];
  NSDate *end1 = [NSDate date];
  if ([[bsjson objectForKey: @"foobars"] count] == 3000) {
    NSLog(@"BSJSONAdditions parsing OK");
    NSLog(@"-> Time = %f", [end1 timeIntervalSinceDate: start1]);
  } else {
    NSLog(@"BSJSONAdditions parsing ERROR");
  }

  // test 2
  NSDate *start2 = [NSDate date];
  NSDictionary *jsonframework = [Test2 parseJson: json];
  NSDate *end2 = [NSDate date];
  if ([[jsonframework objectForKey: @"foobars"] count] == 3000) {
    NSLog(@"JSONFramework parsing OK");
    NSLog(@"-> Time = %f", [end2 timeIntervalSinceDate: start2]);
  } else {
    NSLog(@"JSONFramework parsing ERROR");
  }

  // test 3
  NSDate *start3 = [NSDate date];
  NSDictionary *touchJson = [Test3 parseJson: json];
  NSDate *end3 = [NSDate date];
  if ([[touchJson objectForKey: @"foobars"] count] == 3000) {
    NSLog(@"TouchJSON parsing OK");
    NSLog(@"-> Time = %f", [end3 timeIntervalSinceDate: start3]);
  } else {
    NSLog(@"TouchJSON parsing ERROR");
  }

  // test 4
  NSDate *start4 = [NSDate date];
  NSDictionary *yajl = [Test4 parseJson: json];
  NSDate *end4 = [NSDate date];
  if ([[yajl objectForKey: @"foobars"] count] == 3000) {
    NSLog(@"YAJL parsing OK");
    NSLog(@"-> Time = %f", [end4 timeIntervalSinceDate: start4]);
  } else {
    NSLog(@"YAJL parsing ERROR");
  }

  // test 5
  NSDate *start5 = [NSDate date];
  NSDictionary *jsonkit = [Test5 parseJson: json];
  NSDate *end5 = [NSDate date];
  if ([[jsonkit objectForKey: @"foobars"] count] == 3000) {
    NSLog(@"JSONKit parsing OK");
    NSLog(@"-> Time = %f", [end5 timeIntervalSinceDate: start5]);
  } else {
    NSLog(@"JSONKit parsing ERROR");
  }
}

- (void) dealloc {
  [viewController release];
  [window release];
  [super dealloc];
}

@end
