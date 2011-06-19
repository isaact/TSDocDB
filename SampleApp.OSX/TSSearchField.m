//
//  TSSearchField.m
//  TSTools
//
//  Created by Isaac Tewolde on 10-11-11.
//  Copyright 2010 Ticklespace.com All rights reserved.
//


#import "TSSearchField.h"

void useTSSearchField(){
  
}

@implementation TSSearchField

- (BOOL)performKeyEquivalent:(NSEvent *)event {
  if (([event modifierFlags] & NSDeviceIndependentModifierFlagsMask) == NSCommandKeyMask) {
    // The command key is the ONLY modifier key being pressed.
    if ([[event charactersIgnoringModifiers] isEqualToString:@"x"]) {
      return [NSApp sendAction:@selector(cut:) to:[[self window] firstResponder] from:self];
    } else if ([[event charactersIgnoringModifiers] isEqualToString:@"c"]) {
      return [NSApp sendAction:@selector(copy:) to:[[self window] firstResponder] from:self];
    } else if ([[event charactersIgnoringModifiers] isEqualToString:@"v"]) {
      return [NSApp sendAction:@selector(paste:) to:[[self window] firstResponder] from:self];
    } else if ([[event charactersIgnoringModifiers] isEqualToString:@"a"]) {
      return [NSApp sendAction:@selector(selectAll:) to:[[self window] firstResponder] from:self];
    }else if ([[event charactersIgnoringModifiers] isEqualToString:@"z"]) {
      return [NSApp sendAction:@selector(undo:) to:[[self window] firstResponder] from:self];
    }
  }
  return [super performKeyEquivalent:event];
}

@end
