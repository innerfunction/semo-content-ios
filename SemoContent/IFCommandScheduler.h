//
//  IFCommandScheduler.h
//  SemoContent
//
//  Created by Julian Goacher on 07/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFDB.h"
#import "IFService.h"

@interface IFCommandScheduler : NSObject <IFService> {
    // The queue database.
    IFDB *_db;
    // A list of commands currently being executed.
    NSArray *_execQueue;
    // Pointer into the exec queue to the command currently being executed.
    NSInteger _execIdx;
    // Current batch number.
    NSInteger _currentBatch;
}

/** A map of command instances, keyed by name. */
@property (nonatomic, strong) NSDictionary *commands;
/**
 * A map of command protocol instances, keyed by command prefix.
 * Each protocol provides a list of one or more supported commands. These commands are entered
 * into the command map with the protocol name as its prefix, so e.g. protocol.command.
 */
@property (nonatomic, strong) NSDictionary *protocols;

/** Execute all commands currently on the queue. */
- (void)executeQueue;
/** Append a new command to the queue. */
- (void)appendCommand:(NSString *)name withArgs:(NSArray *)args;
/** Purge the current execution queue. */
- (void)purgeQueue;
/** Purge the current command batch. */
- (void)purgeCurrentBatch;

@end
