//
//  DCTask.h
//  DCOperation
//
//  Created by Paul on 5/28/15.
//  Copyright (c) 2015 DC. All rights reserved.
//

@import Foundation;

typedef void(^executedBlock)(void);

@interface DCTask : NSBlockOperation

@property (assign, nonatomic) NSUInteger queueIdentifier;

- (instancetype)initTaskWithExecutionBlock:(void(^)(void))executionBlock;

- (instancetype)initTaskWithExecutionBlock:(void (^)(void))executionBlock
                                  finished:(executedBlock)finishBlock;

@end
