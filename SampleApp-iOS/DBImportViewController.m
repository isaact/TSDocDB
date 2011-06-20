//
//  DBImportViewController.m
//  TSDocDB
//
//  Created by Din on 11-06-17.
//  Copyright 2011 Ticklespace.com. All rights reserved.
//

#import "DBImportViewController.h"

@interface DBImportViewController()
-(void)importCities;
-(void)importCountries;
@end
@implementation DBImportViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (void)dealloc {
  [lblTaskTitle release];
  [taskProgress release];
  [lblTaskDetails release];
  [super dealloc];
}

- (void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  
  // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad{
  [super viewDidLoad];
  // Do any additional setup after loading the view from its nib.
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul), ^{
    [self importData];
  });
  
}

- (void)viewDidUnload{
  [lblTaskTitle release];
  lblTaskTitle = nil;
  [taskProgress release];
  taskProgress = nil;
  [lblTaskDetails release];
  lblTaskDetails = nil;
  [super viewDidUnload];
  // Release any retained subviews of the main view.
  // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  // Return YES for supported orientations
  return YES;
}
-(void)importData{
  [self importCountries];
  [self importCities];
  [[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) 
            withObject:[NSNotification notificationWithName:@"DBImportComplete" object:nil userInfo:nil] waitUntilDone:YES];
  [self dismissModalViewControllerAnimated:YES];
}

#pragma mark Private Methods
-(void)importCities{
  if (cityDBDelegate == nil) {
    cityDBDelegate = [[CityDBDelegate alloc] init];
  }
  __block int count = 0;
  [cityDBDelegate importCitiesWithProgressBlock:^(NSDictionary *city, BOOL *stop, float progress) {
    dispatch_sync(dispatch_get_main_queue(), ^{
      if (!(count % 27)) {
        [lblTaskTitle setText:@"Importing Cities"];
        [taskProgress setProgress:progress];
        [lblTaskDetails setText:[NSString stringWithFormat:@"Imported %d cities so far", count]];
      }
      count++;
      if (progress == 1.0) {
        [lblTaskDetails setText:@"Finishing up..."];
      }
    });
  }];
}
-(void)importCountries{
  if (cityDBDelegate == nil) {
    cityDBDelegate = [[CityDBDelegate alloc] init];
  }
  __block int count = 0;
  [cityDBDelegate importCountriesWithProgressBlock:^(NSDictionary *country, BOOL *stop, float progress) {
    dispatch_sync(dispatch_get_main_queue(), ^{
      [lblTaskTitle setText:@"Importing Countries"];
      [taskProgress setProgress:progress];
      [taskProgress setHidden:NO];
      [lblTaskDetails setText:[NSString stringWithFormat:@"Imported %d countries so far", count]];
      count++;
    });
  }];
}
@end
