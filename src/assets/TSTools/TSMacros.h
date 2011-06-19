//
//  TSMacros.h
//  TSTools
//
//  Created by Isaac Tewolde on 10-11-11.
//  Copyright 2010 Ticklespace.com All rights reserved.
//


#define GVargs(destArray, firstArg, argType) \
va_list args;\
argType *arg;\
va_start(args, firstArg);\
if(firstArg != nil){\
  [destArray addObject: firstArg];\
  while ((arg = va_arg(args, argType *))){\
    [destArray addObject: arg];\
  }\
}\
va_end(args);


// ALog always displays output regardless of the DEBUG setting
#define ALog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

