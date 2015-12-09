//
//  IFCommandScheduler.m
//  SemoContent
//
//  Created by Julian Goacher on 07/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFCommandScheduler.h"
#import "IFCommand.h"
#import "IFProtocol.h"
#import "IFSemoContent.h"
#import "NSString+IF.h"
#import "NSArray+IF.h"
#import "NSDictionary+IF.h"
#import "IFGetURLCommand.h"
#import "IFRmFileCommand.h"
#import "IFMvFileCommand.h"
#import "IFUnzipCommand.h"

static IFLogger *Logger;
static dispatch_queue_t execQueue;

@interface IFCommandScheduler ()

/** Merge a map of command names into the current map. */
- (void)mergeCommands:(NSDictionary *)commands;
/** Execute the next command on the exec queue. */
- (void)executeNextCommand;

@end

@implementation IFCommandScheduler

+ (void)initialize {
    Logger = [[IFLogger alloc] initWithTag:@"IFCommandScheduler"];
    execQueue = dispatch_queue_create("com.innerfunction.semo.content.CommandScheduler", 0);
}

- (id)init {
    self = [super init];
    if (self) {
        // Command database setup.
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
        // Standard built-in command mappings.
        self.commands = @{
            @"get":   [[IFGetURLCommand alloc] init],
            @"rm":    [[IFRmFileCommand alloc] init],
            @"mv":    [[IFMvFileCommand alloc] init],
            @"unzip": [[IFUnzipCommand alloc] init]
        };
    }
    return self;
}

- (void)setCommands:(NSDictionary *)commands {
    [self mergeCommands:commands];
}

- (void)setProtocols:(NSDictionary *)protocols {
    _protocols = protocols;
    // Extract map of protocol commands from list of protocols.
    NSMutableDictionary *protocolCommands = [[NSMutableDictionary alloc] init];
    for (NSString *protocolName in [protocols allKeys]) {
        id<IFProtocol> protocol = [protocols objectForKey:protocolName];
        for (NSString *commandName in [protocol supportedCommands]) {
            // Map the protocol instance to each command name it supports.
            NSString *qualifiedName = [NSString stringWithFormat:@"%@.%@", protocolName, commandName];
            [protocolCommands setObject:protocol forKey:qualifiedName];
        }
    }
    // Merge protocol commands into command map.
    [self mergeCommands:protocolCommands];
}

- (void)mergeCommands:(NSDictionary *)commands {
    if (_commands == nil) {
        _commands = commands;
    }
    else {
        _commands = [_commands extendWith:commands];
    }
}

- (void)executeQueue {
    if (_execIdx > 0) {
        // Commands currently being executed from queue, leave these to be completed.
        return;
    }
    _execQueue = [_db performQuery:@"SELECT * FROM queue ORDER BY batch, id ASC" withParams:@[]];
    _execIdx = 0;
    dispatch_async(execQueue, ^{
        [self executeNextCommand];
    });
}

- (void)executeNextCommand {
    if ([_execQueue count] == 0) {
        // Do nothing if nothing on the queue.
        return;
    }
    if (_execIdx > [_execQueue count]) {
        // If moved past the end of the queue then try reading a new list of commands from the db.
        [self executeQueue];
        return;
    }
    NSDictionary *commandItem = [_execQueue objectAtIndex:_execIdx];
    // Iterate command pointer.
    _execIdx++;
    // Read command fields from record.
    NSString *rowid = [commandItem valueForKey:@"id"];
    NSString *name = [commandItem valueForKey:@"command"];
    NSArray *args = [[commandItem valueForKey:@"args"] split:@" "];
    _currentBatch = [(NSNumber *)[commandItem valueForKey:@"batch"] integerValue];
    // Find and execute the command.
    [Logger debug:@"Executing %@ %@", name, args];
    id<IFCommand> command = [_commands objectForKey:name];
    if (!command) {
        [Logger error:@"Command not found: %@", name];
        [self purgeQueue];
        return;
    }
    [command execute:name withArgs:args]
    .then((id)^(NSArray *newCommands) {
        // Queue any new commands, delete current command from db.
        [_db beginTransaction];
        for (NSDictionary *newCommand in newCommands) {
            NSString *newName = [newCommand valueForKey:@"name"];
            // Check for system commands.
            if ([@"control.purge-queue" isEqualToString:newName]) {
                [self purgeQueue];
                continue;
            }
            if ([@"control.purge-current-batch" isEqualToString:newName]) {
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
            NSString *newArgs = [(NSArray *)[newCommand valueForKey:@"args"] joinWithSeparator:@" "];
            [Logger debug:@"Appending %@ %@", newName, newArgs];
            NSDictionary *values = @{
                @"batch":  [NSNumber numberWithInteger:batch],
                @"name":   newName,
                @"args":   newArgs
            };
            [_db insertValues:values intoTable:@"queue"];
        }
        [_db deleteIDs:@[ rowid ] fromTable:@"queue"];
        [_db commitTransaction];
        // Continue to next queued command.
        dispatch_async(execQueue, ^{
            [self executeNextCommand];
        });
    })
    .fail(^(id error) {
        [Logger error:@"Error executing command %@ %@: %@", name, args, error];
        [self purgeQueue];
    });
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
    _execIdx = 0;
    _currentBatch = 0;
    [_db deleteFromTable:@"queue" where:@"1 = 1"];
}

- (void)purgeCurrentBatch {
    _execQueue = @[];
    _execIdx = 0;
    [_db deleteFromTable:@"queue" where:[NSString stringWithFormat:@"batch=%ld", _currentBatch]];
}

#pragma mark - IFService

- (void)startService {
    [_db startService];
    // Execute any commands left on the queue from previous start.
    [self executeQueue];
}

@end
