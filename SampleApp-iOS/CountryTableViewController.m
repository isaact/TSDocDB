//
//  CountryTableViewController.m
//  TSDocDB
//
//  Created by Isaac Tewolde on 11-06-17.
//  Copyright 2011 Ticklespace.com. All rights reserved.
//

#import "CountryTableViewController.h"
#import "CityDBDelegate.h"
#import "CityTableViewController.h"
#import "DBImportViewController.h"

@interface CountryTableViewController()
-(void)updateRowsWithSearchString:(NSString *)searchString;
-(void)addRows:(NSNotification *)notificationInfo;
@end
@implementation CountryTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
  self = [super initWithStyle:style];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (void)dealloc{
  [cityDBDelegate release];
  [countries release];
  [filteredCountries release];
  [super dealloc];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  if (!isSearching) {
    [filteredCountries removeAllObjects];
  }
  // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad{
  [super viewDidLoad];
  cityDBDelegate = [[CityDBDelegate alloc] init];
  countries = [[NSMutableArray alloc] init];
  filteredCountries = [[NSMutableArray alloc] init];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addRows:) name:@"DBImportComplete" object:nil];
  opCount = 0;
  isSearching = NO;
  [self.navigationItem setTitle:@"Countries"];
  [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0ul), ^{
    [self updateRowsWithSearchString:nil];
  });
  
}
-(void)awakeFromNib{
}
- (void)viewDidUnload{
  [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated{
  [super viewWillAppear:animated];  
}

- (void)viewDidAppear:(BOOL)animated{
  [super viewDidAppear:animated];
  if ([cityDBDelegate.geonamesDB getNumRowsOfType:@"country"] == 0) {
    NSString *nibSuffix = @"";
    if (isIpad()) {
      nibSuffix = @"-iPad";
    }
    DBImportViewController *dbvc = [[DBImportViewController alloc] initWithNibName:[NSString stringWithFormat:@"DBImportViewController%@", nibSuffix] bundle:nil];
    [self.navigationController presentModalViewController:dbvc animated:YES];
    [dbvc release];
  }
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
  if (isSearching) {
    return [filteredCountries count];
  }
  return [countries count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"Cell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
  }
  if (tableView == self.searchDisplayController.searchResultsTableView) {
    [cell.textLabel setText:[[filteredCountries objectAtIndex:[indexPath row]] objectForKey:@"Country"]];
  }else{
    [cell.textLabel setText:[[countries objectAtIndex:[indexPath row]] objectForKey:@"Country"]];
  }
  return cell;
}
#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
  CityTableViewController *cityTableVC = [[CityTableViewController alloc] initWithNibName:@"CityTableViewController" bundle:nil];
  if (isSearching) {
    cityTableVC.countryCode = [[filteredCountries objectAtIndex:indexPath.row] objectForKey:@"ISO"];
  }else{
    cityTableVC.countryCode = [[countries objectAtIndex:indexPath.row] objectForKey:@"ISO"];
  }
  
  [self.navigationController pushViewController:cityTableVC animated:YES];
  [cityTableVC release];
}
#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0ul), ^{
    [self updateRowsWithSearchString:searchString];
  });
  
  // Return YES to cause the search result table view to be reloaded.
  return NO;
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
  isSearching = NO;
  [self.tableView reloadData];
}
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
  isSearching = YES;
}
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar{
  if ([searchBar.text length] == 0) {
    isSearching = NO;
    [self.tableView reloadData];
  }
  
}
- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar{
  if ([searchBar.text length] == 0) {
    isSearching = YES;
    [filteredCountries removeAllObjects];
    NSRange range;
    range.location = 0;
    range.length = 50;
    if ([countries count] > range.length) {
      range.length = [countries count];
    }
    NSIndexSet *topRows = [NSIndexSet indexSetWithIndexesInRange:range];
    [self.tableView indexPathsForVisibleRows];
    [filteredCountries addObjectsFromArray:[countries objectsAtIndexes:topRows]];
    [self.searchDisplayController.searchResultsTableView reloadData];
  }
  return YES;
}
#pragma mark -
#pragma mark Private Methods
-(void)updateRowsWithSearchString:(NSString *)searchString{
  __block NSInteger currentOp, listSize, insertionPoint;
  __block UITableView *currentTableView = self.tableView;
  __block NSMutableArray *currentList;
  dispatch_sync(dispatch_get_main_queue(), ^{
    opCount++;
    currentOp = opCount;
    insertionPoint = 1;
    if (isSearching) {
      currentList = filteredCountries;
      [cityDBDelegate.geonamesDB addConditionRowContainsString:searchString];
      currentTableView = self.searchDisplayController.searchResultsTableView;
    }else{
      if (![countries count]) {
        [countries addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"~~~ All Countries ~~~", @"Country", nil]];
        [self.tableView reloadData];
      }
      currentList = countries;
    }
    listSize = [currentList count];
    [cityDBDelegate.geonamesDB setOrderByStringForColumn:@"Country" isAscending:YES];
  });
  [cityDBDelegate.geonamesDB doSearchWithProcessingBlock:^(id row){
    __block BOOL stop = NO;
    dispatch_sync(dispatch_get_main_queue(), ^{
      if(currentOp == opCount){
        if (insertionPoint < listSize) {
          [currentList replaceObjectAtIndex:insertionPoint withObject:row];
          [currentTableView beginUpdates];
          [currentTableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:insertionPoint inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
          [currentTableView endUpdates];
        }else{
          [currentList addObject:row];
          [currentTableView beginUpdates];
          [currentTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:insertionPoint inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
          [currentTableView endUpdates];
        }
        insertionPoint++;
        stop =  NO;
      }else{
        stop =  YES;
      }
    });
    return stop;
  } withLimit:300 andOffset:0 forRowTypes:@"country", nil];
  dispatch_sync(dispatch_get_main_queue(), ^{
    if (currentOp == opCount && insertionPoint < listSize) {
      NSRange range;
      range.location = insertionPoint;
      range.length = listSize - insertionPoint;
      [currentList removeObjectsInRange:range];
      [currentTableView beginUpdates];
      for (NSInteger i = listSize - 1; i >= insertionPoint; i--) {
        //NSLog(@"Removing %d %d", i);
        [currentTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
      }
      [currentTableView endUpdates];
    }
  });
}
-(void)addRows:(NSNotification *)notificationInfo{
  [self.tableView reloadData];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0ul), ^{
    [self updateRowsWithSearchString:nil];
  });
}
@end
