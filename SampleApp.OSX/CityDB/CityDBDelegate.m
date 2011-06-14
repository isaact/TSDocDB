//
//  CityDBDelegate.m
//  TSDocDB
//
//  Created by Isaac Tewolde on 11-06-12.
//  Copyright 2011 Ticklespace.com. All rights reserved.
//

#import "CityDBDelegate.h"
#import "NSString+TSTools.h"
#import "TSFileReader.h"

@interface CityDBDelegate()
@end

@implementation CityDBDelegate
@synthesize geonamesDB;

- (id)init {
  self = [super init];
  if (self) {
    geonamesDB = [[TSDB TSDBWithDBNamed:@"geonamesDB" inDirectoryAtPathOrNil:nil delegate:self] retain];
    //geonamesDB = [[TSDB alloc] initWithDBNamed:@"geonamesDB" inDirectoryAtPathOrNil:nil delegate:self];
  }
  return self;
}
- (void)dealloc {
  [geonamesDB release];
  [super dealloc];
}
#pragma mark -
#pragma mark TSDBDefinitionsDelegate methods
-(NSArray *)TSGetRowTypes{
  return [NSArray arrayWithObjects:@"city",@"country", nil];
}
-(NSArray *)TSColumnsForIndexType:(TSIndexType)indexType{
  if (indexType == TSIndexTypeFullTextColumn) {
    return nil;
  }else if (indexType == TSIndexTypeString) {
    return [NSArray arrayWithObjects:@"country code", @"ISO", nil];
  }else if (indexType == TSIndexTypeNumeric) {
    return [NSArray arrayWithObjects:@"geonameid",nil];
  }
  return nil;
}
-(NSArray *)TSColumnsForFullTextSearch:(NSString *)rowType{
  if ([rowType isEqualToString:@"city"]) {
    return [NSArray arrayWithObjects:@"asciiname",@"Country", nil];
  }else if([rowType isEqualToString:@"country"]) {
    return [NSArray arrayWithObjects:@"Country", nil];
  }
  return nil;
}
-(NSString *)TSPrimaryColumnForRowType:(NSString *)rowType{
  if ([rowType isEqualToString:@"city"]) {
    return @"geonameid";
  }else if ([rowType isEqualToString:@"country"]) {
    return @"geonameid";
  }
  return nil;
}
#pragma mark -
#pragma mark Private methods
-(void)importCountriesWithProgressBlock:(void(^)(NSDictionary *country, BOOL *stop, float progress))block{
  TSFileReader *reader = [[TSFileReader alloc] initWithFilePath:[[NSBundle mainBundle] pathForResource:@"countryInfo" ofType:@"txt"]];
  NSArray *colNames = [NSArray arrayWithObjects:@"ISO",@"ISO3",@"ISO-Numeric",@"fips",@"Country",@"Capital",@"Area(in sq km)",@"Population",@"Continent",@"tld",@"CurrencyCode",@"CurrencyName",@"Phone",@"Postal Code Format",@"Postal Code Regex",@"Languages",@"geonameid",@"neighbours",@"EquivalentFipsCode",nil];
  [geonamesDB reindexDB:nil];
  [reader enumerateLinesUsingBlock:^(NSString *line, BOOL *stop, float progress){
    NSMutableDictionary *row = nil;
    if (![line hasPrefix:@"#"]) {
      row = [NSMutableDictionary dictionary];
      NSArray *colValues = [line componentsSeparatedByString:@"\t"];
      for (int i=0; i < [colNames count]; i++) {
        if (i< [colValues count]) {
          [row setObject:[colValues objectAtIndex:i] forKey:[colNames objectAtIndex:i]];
        }else
          break;
      }
      [geonamesDB replaceRow:[row objectForKey:@"geonameid"] withRowType:@"country" andRowData:row];
      if(block != NULL){
        block(row, stop, progress);
      }
    }
  }];
  [geonamesDB syncDB];
}
-(void)importCitiesWithProgressBlock:(void(^)(NSDictionary *city, BOOL *stop, float progress))block{
  TSFileReader *reader = [[TSFileReader alloc] initWithFilePath:[[NSBundle mainBundle] pathForResource:@"cities15000" ofType:@"txt"]];
  NSArray *colNames = [NSArray arrayWithObjects:@"geonameid",@"name",@"asciiname",@"alternatenames",@"latitude",@"longitude",@"feature class",@"feature code",@"country code",@"cc2",@"admin1 code",@"admin2 code",@"admin3 code",@"admin4 code",@"population",@"elevation",@"gtopo30",@"timezone",@"modification date",nil];
  NSMutableDictionary *countries = [NSMutableDictionary dictionary];
  NSArray *countryList = [geonamesDB doSearchWithLimit:300 andOffset:0 forRowTypes:@"country", nil];
  for (NSDictionary *country in countryList) {
    [countries setObject:country forKey:[country objectForKey:@"ISO"]];
  }
  __block int count = 0;
  [reader enumerateLinesUsingBlock:^(NSString *line, BOOL *stop, float progress){
    NSMutableDictionary *row = nil;
    if (![line hasPrefix:@"#"]) {
      row = [[NSMutableDictionary alloc] init];
      NSArray *colValues = [line componentsSeparatedByString:@"\t"];
      for (int i=0; i < [colNames count]; i++) {
        if (i< [colValues count]) {
          [row setObject:[colValues objectAtIndex:i] forKey:[colNames objectAtIndex:i]];
        }else
          break;
      }
      NSString *countryCode = [row objectForKey:@"country code"];
      NSString *countryName = [[countries objectForKey:countryCode] objectForKey:@"Country"];
      [row setObject:countryName forKey:@"Country"];
      [geonamesDB replaceRow:[row objectForKey:@"geonameid"] withRowType:@"city" andRowData:row];
      count++;
      if(block != NULL){
        block(row, stop, progress);
      }
      [row release];
    }
  }];
  [geonamesDB syncDB];
}

@end
