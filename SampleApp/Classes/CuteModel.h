//
//  CuteModel.h
//  SampleApp
//
//  Created by Amanuel on 10-11-24.
//  Copyright 2010 Ticklespace.com. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CuteModel : NSObject {
  NSString *Name;
  NSString *Bio;
  NSString *Gender;
}
@property (nonatomic, retain) NSString *Name;
@property (nonatomic, retain) NSString *Bio;
@property (nonatomic, retain) NSString *Gender;
- (id)init;
- (id)initWithName:(NSString*)newName Bio:(NSString*)newBio Gender:(NSString*)newGender;
- (id)initWithDictionary:(NSDictionary*)dictionary;
- (NSArray *)keyPaths;

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey;
-(NSDictionary*)modelInfo;

@end
