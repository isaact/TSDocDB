//
//  CityDBDelegate.h
//  TSDocDB
//
//  Created by Isaac Tewolde on 11-06-12.
//  Copyright 2011 Ticklespace.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TSDB.h"

@interface CityDBDelegate : NSObject<TSDBDefinitionsDelegate> {
  TSDB *geonamesDB;
}
@property(nonatomic, readonly) TSDB *geonamesDB;


-(NSArray *)TSGetRowTypes;
-(NSArray *)TSColumnsForIndexType:(TSIndexType)indexType;
-(NSArray *)TSColumnsForFullTextSearch:(NSString *)rowType;
-(NSString *)TSPrimaryColumnForRowType:(NSString *)rowType;

-(void)importCountriesWithProgressBlock:(void(^)(NSDictionary *country, BOOL *stop, float progress))block;
-(void)importCitiesWithProgressBlock:(void(^)(NSDictionary *city, BOOL *stop, float progress))block;

@end
