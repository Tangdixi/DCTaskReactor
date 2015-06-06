//
//  DCConcurrency.h
//  DCOperation
//
//  Created by Paul on 5/24/15.
//  Copyright (c) 2015 DC. All rights reserved.
//

#import "DCTask.h"

/**
 *  These constants let you choose which operation queue to add your task
 */
typedef NS_ENUM(NSUInteger, kDCTaskQueueIdentifier){
    /**
     *  The main thread
     */
    kDCTaskQueueIdentifierMain = 1,
    /**
     *  The Serial queue which means executing task one by one and don't
     */
    kDCTaskQueueIdentifierBackgroundSerial = 2,
    /**
     *  The Concurrent queue and it won't block the main thread
     */
    kDCTaskQueueIdentifierBackgroundConcurrency = 3
};

/**
 *  The executing order for the queue
 */
typedef NS_ENUM(NSInteger, kDCTaskQueueRule){
    /**
     *  FIFO, ake first in first out queue
     */
    kDCTaskQueueRuleFIFO = 1,
    /**
     *  LILO, aka last in first out queue
     */
    kDCTaskQueueRuleLIFO = 2
};

@import Foundation;

@protocol DCTaskReactorDelegate <NSObject>

@optional

/**
 *  @brief Ask the delegate for all the tasks finished
 */
- (void)dcTaskReactorAllTasksFinished;

/**
 *  @brief Ask the delegate for all the tasks in main queue finished
 */
- (void)dcTaskReactorAllTasksInMainQueueFinished;

/**
 *  @brief Ask the delegate for all the taks in background serial queue
 */
- (void)dcTaskReactorAllTasksInBackgroundSerialQueueFinished;

/**
 *  @brief Ask the delegate for all the tasks in background concurrent queue
 */
- (void)dcTaskReactorAllTasksInBackgroundConcurrentQueueFinished;

@end

@interface DCTaskReactor : NSObject

#define kDCTaskPriority BOOL
#define kDCTaskQueuePriorityHead YES
#define kDCTaskQueuePriorityTail NO

@property (weak, nonatomic) id<DCTaskReactorDelegate> delegate;

/**
 *  The limit for the concurrent count, it will control by the sustem in default
 */
@property (assign, nonatomic) NSInteger maxConcurrentTaskLimit;

/**
 *  The task queue rule
 */
@property (assign, nonatomic) kDCTaskQueueRule dcTaskQueueRule;

/**
 *  @brief Create a singeleton for DCTaskReactor
 *
 *  @discussion You can use **dcTaskReactorSingleton** instead
 *
 *  @return A singleton
 */
+ (instancetype)shareDCTaskReactor;

/**
 *  @brief Add a task into a pool, the task will add to the operation queue and executing immediately
 *
 *  @param task            An DCTask object, this parameter should never be nil
 *  @param queueIdentifier A constant for **kDCTaskQueueIdentifier**, this parameter shoule not be nil
 *
 *  @return An array which contain the fetched managed objects
 */
- (void)addTask:(DCTask *)task
        toQueue:(kDCTaskQueueIdentifier)queueIdentifier;

/**
 *  @brief Add few tasks into the operation queue, then it will execute accordding to **dcTaskQueueRule**
 *
 *  @param tasks           A DCTask object, this parameter shoule never be nil
 *  @param queueIdentifier A constant for **kDCTaskQueueIdentifier**, this parameter shoule not be nil
 */
- (void)addTasks:(NSArray *)tasks
         toQueue:(kDCTaskQueueIdentifier)queueIdentifier;

/**
 *  @brief Adjust the task's executing order
 *
 *  @param task         A DCTask object, this parameter shoule never be nil
 *  @param taskPriority A contant for **kDCTaskPriority**
 */
- (void)moveTask:(DCTask *)task
    withPriority:(kDCTaskPriority)taskPriority;

/**
 *  @brief Cancel all task in DCTaskReactor
 */
- (void)cancelAllTask;

/**
 *  @brief Cancel a task in DCTaskReactor
 *
 *  @discussion If the task has already add to the operation queue, then this method do nothing
 *
 *  @param task A DCTask object, this parameter shoule never be nil
 */
- (void)cancelTask:(DCTask *)task;

/**
 *  @brief Cancel all tasks in a task pool which you specify
 *
 *  @param queueIdentifier A constant for **kDCTaskQueueIdentifier**, this parameter shoule not be nil
 */
- (void)cancelAllTaskInQueue:(kDCTaskQueueIdentifier)queueIdentifier;

@end

#define dcTaskReactorSingleton [DCCoreData shareDCCoreData]
