//
//  ModelsDataSource.m
//  SampleApp
//
//  Created by Amanuel on 10-11-24.
//  Copyright 2010 Ticklespace.com. All rights reserved.
//

#import "ModelsDataSource.h"
#import "CuteModel.h"

@implementation ModelsDataSource
@synthesize models, modelsDB;
//---------------------------------------------------------- 
// - (id)init
//
//---------------------------------------------------------- 
- (id)init
{
  if ((self = [super init])) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *dbDirectoryName = [documentsDirectory stringByAppendingPathComponent:TSDBDIR];
    [self prepareFolderAtPath:dbDirectoryName];
    
    modelsDB = [[TSDB alloc] initWithDBNamed:TSDBName inDirectoryAtPathOrNil:dbDirectoryName delegate:self];
    [modelsDB retain];
    [modelsDB reindexDB:nil];
    
    NSArray * savedModels = [modelsDB doSearchWithLimit:100 andOffset:0 forRowTypes:TSDBTYPE, nil];
    models = [[NSMutableArray alloc] initWithCapacity:1];
    [models retain];
    
    for (NSDictionary* modelInfo in savedModels) {
      [models addObject:[[[CuteModel alloc] initWithDictionary:modelInfo] autorelease]];
    }
  }
  return self;
}
//---------------------------------------------------------- 
// - (id)initWith:
//
//---------------------------------------------------------- 
- (id)initWithModels:(NSMutableArray*)newModels  
{
  if ((self = [super init])) {
    models = [newModels retain];
  }
  return self;
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
  [models release], models = nil;
  [modelsDB release], modelsDB = nil;
  
  [super dealloc];
}


-(BOOL)prepareFolderAtPath:(NSString*)filePath
{
  NSFileManager *fileManager = [NSFileManager defaultManager];
  BOOL isDirectory = NO;
  BOOL folderExists = [fileManager fileExistsAtPath:filePath isDirectory:&isDirectory] && isDirectory;
  
  NSError *error = nil;
  if (!folderExists)
  {
    [fileManager createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:&error];
  }
  if (error){ 
    [error release];
    return NO;
  }
  else {
    [error release];
    return YES;
  }
  
}


#pragma mark DummyData
-(void)addDummyData
{
  [self addModel:[[[CuteModel alloc] initWithName:@"Jane Smith" Bio:@"She is married" Gender:@"Female"] autorelease]];
  [self addModel:[[[CuteModel alloc] initWithName:@"Tina Fay" Bio:@"She is funny" Gender:@"Female"] autorelease]];
  [self addModel:[[[CuteModel alloc] initWithName:@"John Doe" Bio:@"He is a survivor" Gender:@"Male"] autorelease]];
}

- (NSArray*)filterModelsForSearchText:(NSString*)searchText scope:(NSString*)scope
{
  NSMutableArray* foundModels = [[NSMutableArray alloc] initWithCapacity:10];

  if ([scope isEqualToString:@"All"]) {
    [modelsDB clearFilters];
  }
  else {
    [modelsDB addConditionContainsAnyWordInString:[scope lowercaseString] toColumn:@"Gender"];

  }

  NSArray* results = [modelsDB searchForAllWords:[searchText lowercaseString] withLimit:50 andOffset:0 forRowTypes:TSDBTYPE,nil];
  for (NSDictionary* modelInfo in results) {
    [foundModels addObject:[[[CuteModel alloc] initWithDictionary:modelInfo] autorelease]];
  }
  [foundModels autorelease];
  return [NSArray arrayWithArray:foundModels];

}


#pragma mark TSDBDefinitionsDelegate
-(NSArray *)TSGetRowTypes
{
  return [NSArray arrayWithObject:TSDBTYPE];
}
-(NSArray *)TSColumnsForIndexType:(TSIndexType)indexType
{
  if (indexType == TSIndexTypeFullTextColumn) {
    return [NSArray arrayWithObjects:@"Name",@"Bio",nil];
  }else if (indexType == TSIndexTypeString) {
    return [NSArray arrayWithObjects:@"Gender",nil];
  }
  return nil;
}
-(NSArray *)TSColumnsForFullTextSearch:(NSString *)rowType
{
  return TSDBCOLS;
}

#pragma mark KVO related
//---------------------------------------------------------- 
// - (NSArray *)keyPaths
//
//---------------------------------------------------------- 
- (NSArray *)keyPaths
{
  NSArray *result = [NSArray arrayWithObjects:
                     @"models",
                     nil];
  
  return result;
}


//---------------------------------------------------------- 
// + (BOOL)automaticallyNotifiesObserversForKey:
//
//---------------------------------------------------------- 
+ (BOOL)automaticallyNotifiesObserversForKey: (NSString *)theKey 
{
  BOOL automatic;
  
  if ([theKey isEqualToString:@"models"])
    automatic = NO;
  else
    automatic = [super automaticallyNotifiesObserversForKey:theKey];
  
  return automatic;
}

#pragma mark Add/Remove Models
- (void)addModel:(id)newModel
{
  [modelsDB replaceRow:[newModel Name] withRowType:TSDBTYPE andRowData:[newModel modelInfo]];
  [[self models] addObject:newModel];
}
- (void)removeModel:(id)newModel
{
  [modelsDB deleteRow:[newModel Name]];
  [[self models] removeObject:newModel];
}

#pragma mark Collection Accessors
///////  models  ///////
- (NSUInteger)countOfModels 
{
  return [[self models] count];
}

- (void)getModels:(id *)buffer range:(NSRange)inRange 
{
  [[self models] getObjects:buffer range:inRange];
}

- (id)objectInModelsAtIndex:(NSUInteger)idx 
{
  id myModels = [self models];
  NSUInteger modelsCount = [myModels count];
  if ( modelsCount == 0 || idx > (modelsCount - 1) ) return nil;
  
  return [[[myModels objectAtIndex:idx] retain] autorelease];
}

- (void)insertObject:(id)anObject inModelsAtIndex:(NSUInteger)idx 
{
  id myModels = [self models];
  NSUInteger modelsCount = [myModels count];
  if (idx > modelsCount) return;
  
  if (anObject) [myModels insertObject:anObject atIndex:idx];
}

- (void)insertModels:(NSArray *)modelArray atIndexes:(NSIndexSet *)indexes 
{
  [[self models] insertObjects:modelArray atIndexes:indexes];
}

- (void)removeObjectFromModelsAtIndex:(NSUInteger)idx 
{
  id myModels = [self models];
  NSUInteger modelsCount = [myModels count];
  if ( modelsCount == 0 || idx > (modelsCount - 1) ) return;
  
  [myModels removeObjectAtIndex:idx];
}

- (void)removeModelsAtIndexes:(NSIndexSet *)indexes 
{
  [[self models] removeObjectsAtIndexes:indexes];
}

- (void)replaceObjectInModelsAtIndex:(NSUInteger)idx withObject:(id)anObject 
{
  id myModels = [self models];
  NSUInteger modelsCount = [myModels count];
  if ( modelsCount == 0 || idx > (modelsCount - 1) ) return;
  
  [myModels replaceObjectAtIndex:idx withObject:anObject];
}

- (void)replaceModelsAtIndexes:(NSIndexSet *)indexes withModels:(NSArray *)modelArray 
{
  [[self models] replaceObjectsAtIndexes:indexes withObjects:modelArray];
}



@end
