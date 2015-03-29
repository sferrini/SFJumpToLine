//
//  NSView+FindSubView.h
//  SFJumpToLine
//
//  Created by Simone Ferrini on 28/03/15.
//  Copyright (c) 2015 Simone Ferrini. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSView (FindSubView)

- (NSView *)findSubView:(Class)cls;

@end
