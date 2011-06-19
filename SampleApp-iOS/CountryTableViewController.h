//
//  CountryTableViewController.h
//  TSDocDB
//
//  Created by Isaac Tewolde on 11-06-17.
//  Copyright 2011 Ticklespace.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CityDBDelegate;
@interface CountryTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, UISearchDisplayDelegate, UISearchBarDelegate> {
  NSMutableArray *countries, *filteredCountries;
  CityDBDelegate *cityDBDelegate;
  NSUInteger opCount;
  BOOL isSearching;
}

@end
