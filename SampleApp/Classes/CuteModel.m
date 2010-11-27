//
//  CuteModel.m
//  SampleApp
//
//  Created by Amanuel on 10-11-24.
//  Copyright 2010 Ticklespace.com. All rights reserved.
//

#import "CuteModel.h"


@implementation CuteModel
@synthesize Name, Bio, Gender;
//---------------------------------------------------------- 
// - (id)init
//
//---------------------------------------------------------- 
- (id)init
{
  if ((self = [super init])) {
    Name = [[NSString stringWithString:@"<Name>"] retain];
    Bio = [[NSString stringWithString:@"<Bio>"] retain];
    Gender = [[NSString stringWithString:@"<Gender>"] retain];
  }
  return self;
}


//---------------------------------------------------------- 
// - (id)initWith:
//
//---------------------------------------------------------- 
- (id)initWithName:(NSString*)newName Bio:(NSString*)newBio Gender:(NSString*)newGender 
{
  if ((self = [super init])) {
    Name = [newName retain];
    Bio = [newBio retain];
    Gender = [newGender retain];
  }
  return self;
}

//---------------------------------------------------------- 
// - (id)initWith:
//
//---------------------------------------------------------- 
- (id)initWithDictionary:(NSDictionary*)dictionary
{
  if ((self = [super init])) {
    Name = [[dictionary objectForKey:@"Name"] retain];
    Bio = [[dictionary objectForKey:@"Bio"] retain];
    Gender = [[dictionary objectForKey:@"Gender"] retain];
  }
  return self;
}

//---------------------------------------------------------- 
// - (NSArray *)keyPaths
//
//---------------------------------------------------------- 
- (NSArray *)keyPaths
{
  NSArray *result = [NSArray arrayWithObjects:
                     @"Name",
                     @"Bio",
                     @"Gender",
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
  
  if ([theKey isEqualToString:@"Name"])
    automatic = NO;
  else if ([theKey isEqualToString:@"Bio"])
    automatic = NO;
  else if ([theKey isEqualToString:@"Gender"])
    automatic = NO;
  else 
    automatic = [super automaticallyNotifiesObserversForKey:theKey];
  
  return automatic;
}

//---------------------------------------------------------- 
// dealloc
//---------------------------------------------------------- 
- (void)dealloc
{
  [Name release], Name = nil;
  [Bio release], Bio = nil;
  [Gender release], Gender = nil;
  
  [super dealloc];
}

-(NSDictionary*)modelInfo
{
  return [NSDictionary dictionaryWithObjectsAndKeys:Name, @"Name", Bio, @"Bio", Gender, @"Gender",nil];
}


@end
