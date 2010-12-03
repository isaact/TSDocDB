//
//  ModelsDataSource.h
//  SampleApp
//
//  Created by Amanuel on 10-11-24.
//  Copyright 2010 Ticklespace.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSDB.h"

#define TSDBDIR @"TSDB" // Created in the Documents Folder
#define TSDBName @"MyModels" // Name of the DB
#define TSDBTYPE @"CuteModel" // Name of my Doc Type
#define TSDBCOLSFULLTEXT [NSArray arrayWithObjects:@"Name", @"Bio",nil] // Columns I Plan to Search on
#define TSDBCOLSSTRING [NSArray arrayWithObjects:@"Gender",nil] // Columns I Plan to Search on

@interface ModelsDataSource : NSObject <TSDBDefinitionsDelegate> {
  NSMutableArray *models;
  TSDB *modelsDB;
}

@property (nonatomic, retain) NSMutableArray *models;
@property (nonatomic, retain) TSDB *modelsDB;

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
