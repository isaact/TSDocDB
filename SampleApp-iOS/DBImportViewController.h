//
//  DBImportViewController.h
//  TSDocDB
//
//  Created by Din on 11-06-17.
//  Copyright 2011 Ticklespace.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CityDBDelegate.h"

@interface DBImportViewController : UIViewController {
    
    IBOutlet UILabel *lblTaskTitle;
    IBOutlet UIProgressView *taskProgress;
    IBOutlet UILabel *lblTaskDetails;
    
    CityDBDelegate *cityDBDelegate;
}
-(void)importData;
@end
