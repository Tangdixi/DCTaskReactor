//
//  DCTask.m
//  DCOperation
//
//  Created by Paul on 5/28/15.
//  Copyright (c) 2015 DC. All rights reserved.
//

#import "DCTask.h"

@interface DCTask ()

@end

@implementation DCTask

- (instancetype)initTaskWithExecutionBlock:(void (^)(void))executionBlock {
    
    return [self initTaskWithExecutionBlock:executionBlock finished:nil];
}

- (instancetype)initTaskWithExecutionBlock:(void (^)(void))executionBlock
                                  finished:(executedBlock)finishBlock {
    
    if (self = [super init]) {
        
        [self addExecutionBlock:executionBlock];
        
        self.completionBlock = finishBlock;
        
    }
    
    return self;
    
}

@end
