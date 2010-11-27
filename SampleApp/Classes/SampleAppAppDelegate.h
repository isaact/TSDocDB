//
//  SampleAppAppDelegate.h
//  SampleApp
//
//  Created by Amanuel on 10-11-24.
//  Copyright 2010 Ticklespace.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SampleAppAppDelegate : NSObject <UIApplicationDelegate> {
    
    UIWindow *window;
    UINavigationController *navigationController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;

@end

