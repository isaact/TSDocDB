//
//  ModelsDataSource.h
//  SampleApp
//
//  Created by Amanuel on 10-11-24.
//  Copyright 2010 Ticklespace.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSDocDB.h"

#define TSDocDBDIR @"TSDB" // Created in the Documents Folder
#define TSDocDBName @"MyModels" // Name of the DB
#define TSDocDBTYPE @"CuteModel" // Name of my Doc Type
#define TSDocDBCOLS [NSArray arrayWithObjects:@"Name", @"Bio",@"Gender",nil] // Columns I Plan to Search on

@interface ModelsDataSource : NSObject <TSDocDBDefinitionsDelegate> {
  NSMutableArray *models;
  TSDocDB *modelsDB;
}

@property (nonatomic, retain) NSMutableArray *models;
@property (nonatomic, retain) TSDocDB *modelsDB;

- (id)init;
- (id)initWithModels:(NSMutableArray*)newModels;
-(BOOL)prepareFolderAtPath:(NSString*)filePath;

- (NSArray*)filterModelsForSearchText:(NSString*)searchText scope:(NSString*)scope;

-(void)addDummyData;

- (NSArray *)keyPaths;
+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey;

- (void)addModel:(id)newModel;
- (void)removeModel:(id)newModel;

///////  models  ///////
- (NSUInteger)countOfModels;
- (void)getModels:(id *)buffer range:(NSRange)inRange;
- (id)objectInModelsAtIndex:(NSUInteger)idx;
- (void)insertObject:(id)anObject inModelsAtIndex:(NSUInteger)idx;
- (void)insertModels:(NSArray *)modelArray atIndexes:(NSIndexSet *)indexes;
- (void)removeObjectFromModelsAtIndex:(NSUInteger)idx;
- (void)removeModelsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInModelsAtIndex:(NSUInteger)idx withObject:(id)anObject;
- (void)replaceModelsAtIndexes:(NSIndexSet *)indexes withModels:(NSArray *)modelArray;

@end
