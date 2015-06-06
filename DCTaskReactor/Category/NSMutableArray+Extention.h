//
//  NSMutableArray+Extention.h
//  DCOperation
//
//  Created by Paul on 6/6/15.
//  Copyright (c) 2015 DC. All rights reserved.
//

@import Foundation;

@interface NSMutableArray (Extention)

- (void)removeFirstObject;

- (void)moveObject:(NSObject *)object toIndex:(NSUInteger)index;

@end
