//
//  CityTableViewController.m
//  TSDocDB
//
//  Created by Isaac Tewolde on 11-06-19.
//  Copyright 2011 Ticklespace.com. All rights reserved.
//

#import "CityTableViewController.h"
#import "CityDBDelegate.h"

@interface CityTableViewController()
  -(void)updateRowsWithSearchString:(NSString *)searchString;
@end

@implementation CityTableViewController
@synthesize countryCode;
- (id)initWithStyle:(UITableViewStyle)style
{
  self = [super initWithStyle:style];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (void)dealloc{
  [countryCode release];
  [cityDBDelegate release];
  [cities release];
  [filteredCities release];
  [numFormatter release];
  [super dealloc];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  if (!isSearching) {
    [filteredCities removeAllObjects];
  }
  // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad{
  [super viewDidLoad];
  cityDBDelegate = [[CityDBDelegate alloc] init];
  cities = [[NSMutableArray alloc] init];
  filteredCities = [[NSMutableArray alloc] init];
  opCount = 0;
  isSearching = NO;
  [self.navigationItem setTitle:@"Cities"];
  [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
  numFormatter = [[NSNumberFormatter alloc] init];
  [numFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
}
-(void)awakeFromNib{
}
- (void)viewDidUnload
{
  [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated{
  [super viewWillAppear:animated];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0ul), ^{
    [self updateRowsWithSearchString:nil];
  });
  
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
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
    return [filteredCities count];
  }
  return [cities count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"Cell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
  }
  NSDictionary *cityData;
  if (tableView == self.searchDisplayController.searchResultsTableView) {
    [cell.textLabel setText:[[filteredCities objectAtIndex:[indexPath row]] objectForKey:@"name"]];
    cityData = [filteredCities objectAtIndex:[indexPath row]];
  }else{
    [cell.textLabel setText:[[cities objectAtIndex:[indexPath row]] objectForKey:@"name"]];
    cityData = [cities objectAtIndex:[indexPath row]];
  }
  NSString *pop = [numFormatter stringFromNumber:[NSNumber numberWithInt:[[cityData objectForKey:@"population"] intValue]]];
  NSString *detailText = [NSString stringWithFormat:@"pop. %@ (%@)", pop, [cityData objectForKey:@"Country"]];
  [cell.detailTextLabel setText:detailText];
  cell.detailTextLabel.hidden = NO;
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  return cell;
}
#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

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
    [filteredCities removeAllObjects];
    NSRange range;
    range.location = 0;
    range.length = 50;
    if ([cities count] < range.length) {
      range.length = [cities count];
    }
    NSIndexSet *topRows = [NSIndexSet indexSetWithIndexesInRange:range];
    [self.tableView indexPathsForVisibleRows];
    [filteredCities addObjectsFromArray:[cities objectsAtIndexes:topRows]];
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
    insertionPoint = 0;
    if (isSearching) {
      currentList = filteredCities;
      [cityDBDelegate.geonamesDB addConditionRowContainsString:searchString];
      currentTableView = self.searchDisplayController.searchResultsTableView;
    }else{
      currentList = cities;
    }
    if (countryCode != nil) {
      [cityDBDelegate.geonamesDB addConditionStringEquals:countryCode toColumn:@"country code"];
    }
    listSize = [currentList count];
    [cityDBDelegate.geonamesDB setOrderByStringForColumn:@"name" isAscending:YES];
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
  } withLimit:100 andOffset:0 forRowTypes:@"city", nil];
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
@end
