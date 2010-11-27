//
//  RootViewController.h
//  SampleApp
//
//  Created by Amanuel on 10-11-24.
//  Copyright 2010 Ticklespace.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ModelsDataSource.h"

@interface RootViewController : UITableViewController {
  ModelsDataSource *dataSource;
  UIBarButtonItem *addButton;

  NSMutableArray	*filteredListContent;	// The content filtered as a result of a search.
  NSString		*savedSearchTerm;
  NSInteger		savedScopeButtonIndex;
  BOOL			searchWasActive;
}

@property (nonatomic, retain) NSMutableArray *filteredListContent;

@property (nonatomic, copy) NSString *savedSearchTerm;
@property (nonatomic) NSInteger savedScopeButtonIndex;
@property (nonatomic) BOOL searchWasActive;

@property (nonatomic, retain) ModelsDataSource *dataSource;
@property (nonatomic, retain) UIBarButtonItem *addButton;

-(void)addButtonPressed:(id)sender;


@end
