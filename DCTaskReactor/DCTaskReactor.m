//
//  DCConcurrency.m
//  DCOperation
//
//  Created by Paul on 5/24/15.
//  Copyright (c) 2015 DC. All rights reserved.
//

#import "DCTaskReactor.h"
#import "NSMutableArray+Extention.h"

@interface DCTaskReactor ()

@property (strong, nonatomic) NSMutableArray *mainQueueTasksPool;
@property (strong, nonatomic) NSMutableArray *backgroundSerialQueueTasksPool;
@property (strong, nonatomic) NSMutableArray *backgroundConcurrentQueueTasksPool;

@property (strong, nonatomic) NSOperationQueue *mainQueue;
@property (strong, nonatomic) NSOperationQueue *backgroundSerialQueue;
@property (strong, nonatomic) NSOperationQueue *backgroundConcurrentQueue;

@end

@implementation DCTaskReactor

static void *mainQueueContext = &mainQueueContext;
static void *backgroundSerialQueueContext = &backgroundSerialQueueContext;
static void *backgroundConcurrentQueueContext = &backgroundConcurrentQueueContext;

#pragma mark - Singleton Method

+ (instancetype)shareDCTaskReactor {
    
    static DCTaskReactor *dcTaskReactor = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        dcTaskReactor = [[self alloc]init];
        
    });
    
    return dcTaskReactor;
}

#pragma mark - Initializations

- (instancetype)init {
    
    if (self = [super init]) {

        // Initialization here
        //
        // The default queue rule is FIFO
        //
        _dcTaskQueueRule = kDCTaskQueueRuleFIFO;
        
        // Init a chaos queue for temporarility save the tasks
        //
        _mainQueueTasksPool = [[NSMutableArray alloc]init];
        _backgroundConcurrentQueueTasksPool = [[NSMutableArray alloc]init];
        _backgroundSerialQueueTasksPool = [[NSMutableArray alloc]init];
        
        // Just Fetch the main queue,we don't have to create a new one
        //
        _mainQueue = [NSOperationQueue mainQueue];
        [_mainQueue addObserver:self
                     forKeyPath:@"operationCount"
                        options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                        context:mainQueueContext];
        
        // Set the concurrentOperationCount to 1 to force a serial queue
        //
        _backgroundSerialQueue = [[NSOperationQueue alloc]init];
        _backgroundSerialQueue.maxConcurrentOperationCount = 1;
        [_backgroundSerialQueue addObserver:self
                                 forKeyPath:@"operationCount"
                                    options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                                    context:backgroundSerialQueueContext];
        
        // Init a normal concurrent queue
        //
        _backgroundConcurrentQueue = [[NSOperationQueue alloc]init];
        [_backgroundConcurrentQueue addObserver:self
                                     forKeyPath:@"operationCount"
                                        options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                                        context:backgroundConcurrentQueueContext];
        
        // Set the default task limit control by the system
        //
        _maxConcurrentTaskLimit = NSOperationQueueDefaultMaxConcurrentOperationCount;
        _backgroundConcurrentQueue.maxConcurrentOperationCount = self.maxConcurrentTaskLimit;
        
    }
    
    return self;
}

#pragma mark - Properties' Setter Method

- (void)setMaxConcurrentTaskLimit:(NSInteger)maxConcurrentTaskLimit {
    
    _backgroundConcurrentQueue.maxConcurrentOperationCount = maxConcurrentTaskLimit;
    
}

#pragma mark - Cancel Task Methods

- (void)cancelAllTask {
    
    [_backgroundConcurrentQueue cancelAllOperations];
    [_backgroundConcurrentQueueTasksPool removeAllObjects];
    
    [_backgroundSerialQueue cancelAllOperations];
    [_backgroundSerialQueueTasksPool removeAllObjects];
    
    [_mainQueue cancelAllOperations];
    
}

- (void)cancelAllTaskInQueue:(kDCTaskQueueIdentifier)queueIdentifier {
    
    // Only the task is in the tasks' pool, or we can do nothing for the task
    //
    NSMutableArray *operationQueueTasksPool = [self fetchOperationTasksQueueWithIdentifier:queueIdentifier];
    [operationQueueTasksPool removeAllObjects];
    
}

- (void)cancelTask:(DCTask *)task {
    
    NSMutableArray *operationQueueTasksPool = [self fetchOperationTasksQueueWithIdentifier:task.queueIdentifier];
    
    [operationQueueTasksPool removeObject:task];
    
}

#pragma mark - Add Task Methods

- (void)addTask:(DCTask *)task
        toQueue:(kDCTaskQueueIdentifier)queueIdentifier {
    
    // 1. Fetch the tasks' pool, aka an array that save the tasks temporary
    //
    NSMutableArray *operationQueueTasksPool = [self fetchOperationTasksQueueWithIdentifier:queueIdentifier];
    
    // 2. Assign a queue identifier to the task, for priority handle
    //
    task.queueIdentifier = queueIdentifier;
    
    // 3. Add the task into the pool, accordding to the queue rule
    //
    [operationQueueTasksPool addObject:task];
    
    // 4. Fetch the queue with the identifier, the task will add into this queue
    //
    NSOperationQueue *operationQueue = [self fetchOperationQueueWithIdentifier:queueIdentifier];
    
    // 5 .Active array when the queue is empty or less than the max concurrent count
    //
    if (operationQueue.operationCount == 0 ||
        operationQueue.operationCount < operationQueue.maxConcurrentOperationCount) {
        
        // 6. Pop the last task is tasks' pool and add it into the queue
        //
        [self performHeadTaskInQueue:operationQueue
                        fromTaskPool:operationQueueTasksPool];
        
    }
    
}

- (void)addTasks:(NSArray *)tasks
         toQueue:(kDCTaskQueueIdentifier)queueIdentifier {
    
    if (self.dcTaskQueueRule == kDCTaskQueueRuleLIFO) {
        
        for (DCTask *task in [tasks reverseObjectEnumerator]) {
            
            [self addTask:task
                  toQueue:queueIdentifier];
            
        }
        
    }
    else {
        
        for (DCTask *task in tasks) {
            
            [self addTask:task
                  toQueue:queueIdentifier];
            
        }
        
    }
    
}

#pragma mark - Adjust Task Order Methods

- (void)moveTask:(DCTask *)task
    withPriority:(kDCTaskPriority)taskPriority {
    
    NSMutableArray *operationQueueTasksPool = [self fetchOperationTasksQueueWithIdentifier:task.queueIdentifier];
    
    @synchronized(self) {
        
        // Only the task is in the tasks' pool, or we can do nothing for the task
        //
        if (! task.isExecuting) {
            
            // Move it to the tasks' pool's head
            //
            if (taskPriority == kDCTaskQueuePriorityHead) {
                
                [operationQueueTasksPool moveObject:task toIndex:0];
                
            }
            
            // Move it to the tasks' pool's tail
            //
            else {
                
                [operationQueueTasksPool moveObject:task toIndex:operationQueueTasksPool.count - 1];
                
            }
            
        }
        
    }
    
}

#pragma mark - Private Perform Task Method

- (void)performHeadTaskInQueue:(NSOperationQueue *)operationQueue
                  fromTaskPool:(NSMutableArray *)operationQueueTasksPool {
    
    DCTask *task = operationQueueTasksPool.firstObject;
    
    // 1. Only if the task is exist
    //
    if (task) {
        
        // 2. Remove the first task in the pool.
        //
        [operationQueueTasksPool removeFirstObject];
        
        // 3. Add to the queue
        //
        [operationQueue addOperation:task];
        
    }
    
}

#pragma mark - Private Fetch Queue Methods

- (NSOperationQueue *)fetchOperationQueueWithIdentifier:(kDCTaskQueueIdentifier)queueIdentifier {
    
    switch (queueIdentifier) {
            
        case kDCTaskQueueIdentifierMain:
            return self.mainQueue;
            
        case kDCTaskQueueIdentifierBackgroundSerial:
            return self.backgroundSerialQueue;
            
        case kDCTaskQueueIdentifierBackgroundConcurrency:
            return self.backgroundConcurrentQueue;
            
        default:
            
            NSAssert(queueIdentifier, @"Unknown Queue");
            
            return nil;
            
    }
    
}

- (NSMutableArray *)fetchOperationTasksQueueWithIdentifier:(kDCTaskQueueIdentifier)queueIdentifier {
    
    switch (queueIdentifier) {
            
        case kDCTaskQueueIdentifierMain:
            return self.mainQueueTasksPool;
            
        case kDCTaskQueueIdentifierBackgroundSerial:
            return self.backgroundSerialQueueTasksPool;
            
        case kDCTaskQueueIdentifierBackgroundConcurrency:
            return self.backgroundConcurrentQueueTasksPool;
            
        default:
            
            NSAssert(queueIdentifier, @"Unknown Queue");
            
            return nil;
            
    }
    
}

- (NSOperationQueue *)fetchOperationQueueWithContext:(void *)context {
    
    if (context == mainQueueContext) {
        return self.mainQueue;
    }
    else if (context == backgroundConcurrentQueueContext) {
        return self.backgroundConcurrentQueue;
    }
    else {
        return self.backgroundSerialQueue;
    }
    
}

- (NSMutableArray *)fetchOperationTasksQueueWithContext:(void *)context {
    
    if (context == mainQueueContext) {
        return self.mainQueueTasksPool;
    }
    else if (context == backgroundConcurrentQueueContext) {
        return self.backgroundConcurrentQueueTasksPool;
    }
    else {
        return self.backgroundSerialQueueTasksPool;
    }
    
}

#pragma mark - KVO Methods

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    @synchronized(self) {
        
        if ([keyPath isEqualToString:@"operationCount"]) {
            
            // Process the task dispatch stuff
            //
            NSUInteger currentOperationCount = ((NSNumber *)change[@"new"]).unsignedIntegerValue;
            
            NSOperationQueue *operationQueue = [self fetchOperationQueueWithContext:context];
            NSMutableArray *operationQueueTasksPool = [self fetchOperationTasksQueueWithContext:context];
            
            
            if (currentOperationCount < operationQueue.maxConcurrentOperationCount) {
                
                [self performHeadTaskInQueue:operationQueue
                                fromTaskPool:operationQueueTasksPool];
                
            }
            
            // Configure the DCTaskReactor Delegate
            //
            if (currentOperationCount == 0) {
                
                if ([_delegate respondsToSelector:@selector(dcTaskReactorAllTasksFinished)]) {
                    
                    [_delegate dcTaskReactorAllTasksFinished];
                    
                }
                
                if ([_delegate respondsToSelector:@selector(dcTaskReactorAllTasksInMainQueueFinished)] &&
                    context == mainQueueContext) {
                    
                    [_delegate dcTaskReactorAllTasksInMainQueueFinished];
                    
                }
                
                if ([_delegate respondsToSelector:@selector(dcTaskReactorAllTasksInBackgroundSerialQueueFinished)] &&
                    context == backgroundSerialQueueContext) {
                    
                    [_delegate dcTaskReactorAllTasksInBackgroundSerialQueueFinished];
                    
                }
                
                if ([_delegate respondsToSelector:@selector(dcTaskReactorAllTasksInBackgroundConcurrentQueueFinished)] &&
                    context == backgroundConcurrentQueueContext) {
                    
                    [_delegate dcTaskReactorAllTasksInBackgroundConcurrentQueueFinished];
                    
                }
            }
            
        }
        
    }
    
}

@end
