//
//  SFJumpToLine.m
//  SFJumpToLine
//
//  Created by Simone Ferrini on 28/03/15.
//  Copyright (c) 2015 Simone Ferrini. All rights reserved.
//

#import "SFJumpToLine.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "DTXcodeUtils.h"
#import "DTXcodeHeaders.h"
#import "NSView+FindSubView.h"

static SFJumpToLine *sharedPlugin;
static NSRulerView *rulerView;

@interface NSRulerView (DVTTextSidebarView)

- (NSUInteger)lineNumberForPoint:(CGPoint)point;
- (NSUInteger)lineNumberForRect:(NSRect)rect;

- (id)annotationAtSidebarPoint:(CGPoint)p0;
- (id)jumpToLine_annotationAtSidebarPoint:(CGPoint)p0;

@end

@implementation NSRulerView (SFJumpToLine)

- (NSUInteger)lineNumberForRect:(NSRect)rect;
{
    CGPoint point = {0, rect.origin.y};
    return [self lineNumberForPoint:point];
}

- (id)jumpToLine_annotationAtSidebarPoint:(CGPoint)p0
{
    id annotation = [self jumpToLine_annotationAtSidebarPoint:p0];
    if (!rulerView) {
        rulerView = self;
    }
    return annotation;
}

@end

@interface SFJumpToLine()

@property (nonatomic, strong, readwrite) NSBundle *bundle;

@end

@implementation SFJumpToLine

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            
            sharedPlugin = [[self alloc] initWithBundle:plugin];
            
            [self swizzleClass:NSClassFromString(@"DVTTextSidebarView")
                      exchange:@selector(annotationAtSidebarPoint:)
                          with:@selector(jumpToLine_annotationAtSidebarPoint:)];
        });
    }
}

+ (void)swizzleClass:(Class)aClass exchange:(SEL)origMethod with:(SEL)altMethod
{
    method_exchangeImplementations(class_getInstanceMethod(aClass, origMethod),
                                   class_getInstanceMethod(aClass, altMethod));
}

+ (instancetype)sharedPlugin
{
    return sharedPlugin;
}

- (id)initWithBundle:(NSBundle *)plugin
{
    self = [super init];
    if (self) {
        self.bundle = plugin;
        NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"Debug"];
        if (menuItem) {
            NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"Jump to selected line" action:@selector(jumpToSelectedLine) keyEquivalent:@"j"];
            [actionMenuItem setTarget:self];
            [actionMenuItem setKeyEquivalentModifierMask:NSControlKeyMask];
            NSInteger index = [menuItem.submenu indexOfItemWithTitle:@""];
            if (index > 0) {
                [[menuItem submenu] insertItem:actionMenuItem atIndex:index];
            }
        }
    }
    return self;
}

- (void)jumpToSelectedLine
{
    DVTSourceTextView *sourceTextView = [DTXcodeUtils currentSourceTextView];
    NSRange selectedTextRange = [sourceTextView selectedRange];
    NSRect rectForSelectedRange = [self rectForSelectedRange:selectedTextRange andSourceTextView:sourceTextView];
    NSUInteger line = [rulerView lineNumberForRect:rectForSelectedRange];
    [self jumpToLine:line];
}

- (NSRect)rectForSelectedRange:(NSRange)aRange andSourceTextView:(DVTSourceTextView *)sourceTextView
{
    NSRange selection = [sourceTextView selectedRange];
    NSLayoutManager *layoutManager = [sourceTextView layoutManager];
    NSTextContainer *textContainer = [sourceTextView textContainer];
    NSRange glyphRange = [sourceTextView.layoutManager glyphRangeForCharacterRange:selection actualCharacterRange:nil];
    NSRect boundingRect = [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:textContainer];
    return boundingRect;
}

- (void)jumpToLine:(NSUInteger)lineNumber
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSView *consoleView = [[[NSApp mainWindow] contentView] findSubView:NSClassFromString(@"IDEConsoleTextView")];
        NSString *consoleString = ((id(*)(id, SEL))objc_msgSend)(consoleView, @selector(string));
        
        if ([consoleString rangeOfString:@"(lldb)" options:NSBackwardsSearch].location != NSNotFound) {
            NSString *jumpCommand = [NSString stringWithFormat:@"jump %@", @(lineNumber -1)];
            NSString *nextCommand = @"next";
            
            ((void(*)(id, SEL, id))objc_msgSend)(consoleView, @selector(insertText:), jumpCommand);
            ((void(*)(id, SEL, id))objc_msgSend)(consoleView, @selector(insertNewline:), nil);
            
            ((void(*)(id, SEL, id))objc_msgSend)(consoleView, @selector(insertText:), nextCommand);
            ((void(*)(id, SEL, id))objc_msgSend)(consoleView, @selector(insertNewline:), nil);
            
        } else {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"Oops, seems like there isn't (lldb) running!"];
            [alert runModal];
        }
    });
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
