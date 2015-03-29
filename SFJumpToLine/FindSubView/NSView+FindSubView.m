//
//  NSView+FindSubView.m
//  SFJumpToLine
//
//  Created by Simone Ferrini on 28/03/15.
//  Copyright (c) 2015 Simone Ferrini. All rights reserved.
//

#import "NSView+FindSubView.h"

@implementation NSView (FindSubView)

- (NSView *)findSubView:(Class)cls
{
  if ([[self subviews] count] > 0) {
    for (NSView *subview in [self subviews]) {
      if ([subview isKindOfClass:cls]) {
        return subview;
      } else {
        NSView *foundView = [subview findSubView:cls];
        if (foundView != nil)
          return foundView;
      }
    }
  }
  
  return nil;
}

@end
