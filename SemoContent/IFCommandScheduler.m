//
//  IFCommandScheduler.m
//  SemoContent
//
//  Created by Julian Goacher on 07/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFCommandScheduler.h"
#import "IFCommand.h"
#import "IFSemoContent.h"
#import "NSString+IF.h"
#import "NSArray+IF.h"

static IFLogger *Logger;

@implementation IFCommandScheduler

+ (void)initialize {
    Logger = [[IFLogger alloc] initWithTag:@"IFCommandScheduler"];
}

- (id)init {
    self = [super init];
    if (self) {
        _db = [[IFDB alloc] init];
        _db.name = @"semo-command-scheduler";
        _db.version = @0;
        _db.tables = @{
            @"queue": @{
                @"columns": @{
                    @"id":      @{ @"type": @"INTEGER PRIMARY KEY" },
                    @"batch":   @{ @"type": @"INTEGER" },
                    @"command": @{ @"type": @"TEXT" },
                    @"args":    @{ @"type": @"TEXT" }
                }
            }
        };
        _currentBatch = 0;
    }
    return self;
}

- (void)setCommands:(NSDictionary *)commands {
    _commands = commands;
    // Connect the commands to the scheduler; this allows commands to append new
    // commands to the queue.
    for (NSString *name in [commands allKeys]) {
        id<IFCommand> command = [commands objectForKey:name];
        command.scheduler = self;
    }
}

- (void)executeQueue {
    if ([_execQueue count] > 0) {
        // Commands currently being executed from queue, leave these to be completed.
        return;
    }
    while (YES) {
        _execQueue = [_db performQuery:@"SELECT * FROM queue ORDER BY batch, id ASC" withParams:@[]];
        if ([_execQueue count] == 0) {
            // Exit if no command left to execute.
            break;
        }
        for (NSDictionary *command in _execQueue) {
            // Read command fields from record.
            NSString *rowid = [command valueForKey:@"id"];
            NSString *name = [command valueForKey:@"command"];
            NSArray *args = [[command valueForKey:@"args"] split:@" "];
            _currentBatch = [(NSNumber *)[command valueForKey:@"batch"] integerValue];
            // Find and execute the command.
            [Logger debug:@"Executing %@ %@", name, args];
            id<IFCommand> command = [_commands objectForKey:name];
            if (!command) {
                [Logger error:@"Command not found: %@", name];
                // TODO: Purge queue?
                continue;
            }
            NSArray *newCommands = [command executeWithArgs:args];
            // Queue any new commands, delete current command from db.
            [_db beginTransaction];
            for (NSDictionary *newCommand in newCommands) {
                NSString *name = [newCommand valueForKey:@"name"];
                // Check for system commands.
                if ([@"control.purge-queue" isEqualToString:name]) {
                    [self purgeQueue];
                    continue;
                }
                if ([@"control.purge-current-batch" isEqualToString:name]) {
                    [self purgeCurrentBatch];
                    continue;
                }
                NSInteger batch = _currentBatch;
                NSNumber *priority = [newCommand valueForKey:@"priority"];
                if (priority) {
                    batch += [priority integerValue];
                    // Negative priorities can place new commands at the head of the queue; reset the exec queue
                    // to force a db read, so that these commands are read into the head of the exec queue.
                    if (batch < _currentBatch) {
                        _execQueue = @[];
                    }
                }
                NSString *args = [(NSArray *)[newCommand valueForKey:@"args"] joinWithSeparator:@" "];
                [Logger debug:@"Appending %@ %@", name, args];
                NSDictionary *values = @{
                    @"batch":  [NSNumber numberWithInteger:batch],
                    @"name":   name,
                    @"args":   args
                };
                [_db insertValues:values intoTable:@"queue"];
            }
            [_db deleteIDs:@[ rowid ] fromTable:@"queue"];
            [_db commitTransaction];
        }
        // Loop around and query for any additional command added to the queue by commands exec'd in last loop.
    }
}

- (void)appendCommand:(NSString *)name withArgs:(NSArray *)args {
    [Logger debug:@"Appending %@ %@", name, args];
    NSNumber *batch = [NSNumber numberWithInteger:_currentBatch];
    NSDictionary *values = @{
        @"batch":   batch,
        @"name":    name,
        @"args":    [args joinWithSeparator:@" "]
    };
    [_db insertValues:values intoTable:@"queue"];
}

- (void)purgeQueue {
    // Replace the execution queue with an empty list, delete all queued commands.
    _execQueue = @[];
    _currentBatch = 0;
    [_db deleteFromTable:@"queue" where:@"1 = 1"];
}

- (void)purgeCurrentBatch {
    _execQueue = @[];
    [_db deleteFromTable:@"queue" where:[NSString stringWithFormat:@"batch=%ld", _currentBatch]];
}

#pragma mark - IFService

- (void)startService {
    [_db startService];
    // Execute any command remaining on the queue.
    [self executeQueue];
}

@end
