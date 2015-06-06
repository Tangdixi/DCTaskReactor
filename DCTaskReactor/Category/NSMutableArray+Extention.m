//
//  NSMutableArray+Extention.m
//  DCOperation
//
//  Created by Paul on 6/6/15.
//  Copyright (c) 2015 DC. All rights reserved.
//

#import "NSMutableArray+Extention.h"

@implementation NSMutableArray (Extention)

- (void)removeFirstObject {
    
    [self removeObjectAtIndex:0];
    
}

- (void)moveObject:(NSObject *)object toIndex:(NSUInteger)index {
    
    BOOL hasObject = [self containsObject:object];
    
    if (! hasObject) {
        
        return ;
        
    }
    
    // Remove the object first
    //
    [self removeObjectAtIndex:[self indexOfObject:object]];
    
    [self insertObject:object atIndex:index];
    
}

@end
