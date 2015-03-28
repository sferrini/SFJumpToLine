//
//  SFJumpToLine.h
//  SFJumpToLine
//
//  Created by Simone Ferrini on 28/03/15.
//  Copyright (c) 2015 Simone Ferrini. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface SFJumpToLine : NSObject

+ (instancetype)sharedPlugin;

@property (nonatomic, strong, readonly) NSBundle *bundle;

@end
