//
//  RootViewController.m
//  SampleApp
//
//  Created by Amanuel on 10-11-24.
//  Copyright 2010 Ticklespace.com. All rights reserved.
//

#import "RootViewController.h"
#import "CuteModel.h"

@implementation RootViewController
@synthesize dataSource, addButton, filteredListContent, savedSearchTerm, savedScopeButtonIndex, searchWasActive;

#pragma mark -
#pragma mark View lifecycle


- (void)viewDidLoad {
  [super viewDidLoad];
  dataSource = [[ModelsDataSource alloc] init];
  [dataSource retain];
  if ([dataSource.models count] == 0) {
    [dataSource addDummyData];
  }
  // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
  self.navigationItem.leftBarButtonItem = self.editButtonItem;
  UIBarButtonItem *aButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonPressed:)];
	self.addButton = aButton;
	[aButton release];
	
	addButton.enabled = NO;
  self.navigationItem.rightBarButtonItem = addButton;
  
  // create a filtered list that will contain products for the search results table.
  self.filteredListContent = [NSMutableArray arrayWithCapacity:[[dataSource models] count]];
  
  // restore search settings if they were saved in didReceiveMemoryWarning.
  if (self.savedSearchTerm)
  {
    [self.searchDisplayController setActive:self.searchWasActive];
    [self.searchDisplayController.searchBar setSelectedScopeButtonIndex:self.savedScopeButtonIndex];
    [self.searchDisplayController.searchBar setText:savedSearchTerm];
    
    self.savedSearchTerm = nil;
  }
  
  [self.tableView reloadData];
  self.tableView.scrollEnabled = YES;
}

-(void)addButtonPressed:(id)sender
{
  NSLog(@"Add new row");
}


- (void)viewDidUnload
{
	self.filteredListContent = nil;
}

- (void)viewDidDisappear:(BOOL)animated
{
  // save the state of the search UI so that it can be restored if the view is re-created
  self.searchWasActive = [self.searchDisplayController isActive];
  self.savedSearchTerm = [self.searchDisplayController.searchBar text];
  self.savedScopeButtonIndex = [self.searchDisplayController.searchBar selectedScopeButtonIndex];
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
  [dataSource release], dataSource = nil;
  [addButton release], addButton = nil;
  [filteredListContent release], filteredListContent = nil;
  [savedSearchTerm release], savedSearchTerm = nil;
  
  [super dealloc];
}

#pragma mark -
#pragma mark Table view data source

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

  if (tableView == self.searchDisplayController.searchResultsTableView)
    return [self.filteredListContent count];
  else
    return [dataSource countOfModels];

}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  
  static NSString *CellIdentifier = @"Cell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
  }

  CuteModel *model = nil;
	if (tableView == self.searchDisplayController.searchResultsTableView)
    model = [self.filteredListContent objectAtIndex:indexPath.row];
  else
    model = [dataSource objectInModelsAtIndex:indexPath.row];
  
  cell.textLabel.text = model.Name;
  cell.detailTextLabel.text = model.Bio;
	// Configure the cell.
  
  return cell;
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  // Return NO if you do not want the specified item to be editable.
  return YES;
}




// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    // Delete the row from the data source.
    [dataSource removeObjectFromModelsAtIndex:indexPath.row];
    [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
  }   
  else if (editingStyle == UITableViewCellEditingStyleInsert) {
    // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
  }   
}




// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}



/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  
	/*
	 <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
   // ...
   // Pass the selected object to the new view controller.
	 [self.navigationController pushViewController:detailViewController animated:YES];
	 [detailViewController release];
	 */
}

#pragma mark -
#pragma mark Content Filtering

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
	/*
	 Update the filtered array based on the search text and scope.
	 */
	
	[self.filteredListContent removeAllObjects]; // First clear the filtered array.
	NSArray *results = [dataSource filterModelsForSearchText:searchText scope:scope];
	
  [self.filteredListContent addObjectsFromArray:results];

}


#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
  [self filterContentForSearchText:searchString scope:
   [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
  
  // Return YES to cause the search result table view to be reloaded.
  return YES;
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
  [self filterContentForSearchText:[self.searchDisplayController.searchBar text] scope:
   [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
  
  // Return YES to cause the search result table view to be reloaded.
  return YES;
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  
  // Relinquish ownership any cached data, images, etc that aren't in use.
}




@end

