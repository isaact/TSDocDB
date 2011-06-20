//
//  CityTableViewController.h
//  TSDocDB
//
//  Created by Isaac Tewolde on 11-06-19.
//  Copyright 2011 Ticklespace.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CityDBDelegate;
@interface CityTableViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, UISearchDisplayDelegate, UISearchBarDelegate> {
  NSMutableArray *cities, *filteredCities;
  CityDBDelegate *cityDBDelegate;
  NSUInteger opCount;
  NSString *countryCode;
  BOOL isSearching;
  NSNumberFormatter *numFormatter;
}
@property(nonatomic,retain) NSString *countryCode;
@end
