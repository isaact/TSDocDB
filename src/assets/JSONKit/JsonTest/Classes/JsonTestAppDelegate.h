// -------------------------------------------------------
// JsonTestAppDelegate.h
//
// Copyright (c) 2010 Jakub Suder <jakub.suder@gmail.com>
// Licensed under WTFPL license
// -------------------------------------------------------

#import <UIKit/UIKit.h>

@class JsonTestViewController;

@interface JsonTestAppDelegate : NSObject <UIApplicationDelegate> {
  UIWindow *window;
  JsonTestViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet JsonTestViewController *viewController;

@end

