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

/** Execute the next command on the exec queue. */
- (void)executeNextCommand;
/**
 * Parse a command item into a command descriptor.
 * The command item can be either:
 * 1. Already a descriptor, specified as an NSDictionary instance, in which case it is returned unchanged;
 * 2. Or a command line string, in which case it is parsed and a new descriptor is returned.
 */
- (NSDictionary *)parseCommandItem:(id)item;

@end

@implementation IFCommandScheduler

+ (void)initialize {
    Logger = [[IFLogger alloc] initWithTag:@"IFCommandScheduler"];
    execQueue = dispatch_queue_create("com.innerfunction.semo.commands.CommandScheduler", 0);
}

- (id)init {
    self = [super init];
    if (self) {
        // Command database setup.
        _db = [[IFDB alloc] init];
        _db.name = @"com.innerfunction.semo.command-scheduler";
        _db.version = @0;
        _db.tables = @{
            @"queue": @{
                @"columns": @{
                    @"id":      @{ @"type": @"INTEGER PRIMARY KEY", @"tag": @"id" },
                    @"batch":   @{ @"type": @"INTEGER" },
                    @"command": @{ @"type": @"TEXT" },
                    @"args":    @{ @"type": @"TEXT" },
                    @"status":  @{ @"type": @"TEXT" } // States: P - pending X - executed
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
        
        _deleteExecutedQueueRecords = YES;
    }
    return self;
}

- (NSString *)queueDBName {
    return _db.name;
}

- (void)setQueueDBName:(NSString *)queueDBName {
    _db.name = queueDBName;
}

- (void)setCommands:(NSDictionary *)commands {
    NSMutableDictionary *commandsToAdd = [[NSMutableDictionary alloc] init];
    // Iterate over the set of commands being added, to check for any command protocols.
    for (NSString *name in [commands allKeys]) {
        id<IFCommand> command = [commands objectForKey:name];
        if ([command isKindOfClass:[IFProtocol class]]) {
            IFProtocol *protocol = (IFProtocol *)command;
            // Iterate over the protocol's supported commands and add to the command
            // namespace under a fully qualified name.
            for (NSString *subname in [protocol supportedCommands]) {
                NSString *qualifiedName = [NSString stringWithFormat:@"%@.%@", name, subname];
                [commandsToAdd setObject:protocol forKey:qualifiedName];
            }
        }
        else {
            [commandsToAdd setObject:command forKey:name];
        }
    }
    // (Possibly) merge additional commands into the current set of commands.
    if (_commands == nil) {
        _commands = commandsToAdd;
    }
    else {
        _commands = [_commands extendWith:commandsToAdd];
    }
}

- (void)executeQueue {
    if (_execIdx > 0) {
        // Commands currently being executed from queue, leave these to be completed.
        return;
    }
    _execQueue = [_db performQuery:@"SELECT * FROM queue WHERE status='P' ORDER BY batch, id ASC" withParams:@[]];
    _execIdx = 0;
    dispatch_async(execQueue, ^{
        [self executeNextCommand];
    });
}

- (void)executeNextCommand {
    if ([_execQueue count] == 0) {
        // Do nothing if nothing on the queue.
        _execIdx = -1;
        return;
    }
    if (_execIdx > [_execQueue count] - 1) {
        // If moved past the end of the queue then try reading a new list of commands from the db.
        _execIdx = -1;
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
        for (id item in newCommands) {
            NSDictionary *newCommand = [self parseCommandItem:item];
            if (!newCommand) {
                // Indicates an unparseable command line string; just continue to the next command.
                continue;
            }
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
                @"batch":   [NSNumber numberWithInteger:batch],
                @"command": newName,
                @"args":    newArgs,
                @"status":  @"P"
            };
            [_db insertValues:values intoTable:@"queue"];
        }
        // Delete the command record from the queue.
        if (_deleteExecutedQueueRecords) {
            [_db deleteIDs:@[ rowid ] fromTable:@"queue"];
        }
        else {
            NSDictionary *values = @{
                @"id":      rowid,
                @"status":  @"X"
            };
            [_db updateValues:values inTable:@"queue"];
        }
        [_db commitTransaction];
        // Continue to next queued command.
        dispatch_async(execQueue, ^{
            [self executeNextCommand];
        });
        return nil;
    })
    .fail(^(id error) {
        [Logger error:@"Error executing command %@ %@: %@", name, args, error];
        [self purgeQueue];
    });
}

- (NSDictionary *)parseCommandItem:(id)item {
    if ([item isKindOfClass:[NSDictionary class]]) {
        return (NSDictionary *)item;
    }
    NSString *line = [item description];
    NSArray *parts = [line split:@" "];
    if ([parts count] > 0) {
        NSString *name = [parts objectAtIndex:0];
        NSArray *args = @[];
        if ([parts count] > 1) {
            args = [parts subarrayWithRange:NSMakeRange(1, [parts count] - 1)];
        }
        return @{ @"name": name, @"args": args };
    }
    [Logger warn:@"Invalid command line: %@", line];
    return nil;
}

- (void)appendCommand:(NSString *)name withArgs:(NSArray *)args {
    [Logger debug:@"Appending %@ %@", name, args];
    NSNumber *batch = [NSNumber numberWithInteger:_currentBatch];
    NSString *joinedArgs = [args joinWithSeparator:@" "];
    NSDictionary *values = @{
        @"batch":   batch,
        @"command": name,
        @"args":    joinedArgs,
        @"status":  @"P"
    };
    // Only one pending command with the same name and args should exist for the same batch
    // at any time, so only insert record if no matching record found.
    NSArray *params = @[ batch, name, joinedArgs, @"P" ];
    NSInteger count = [_db countInTable:@"queue" where:@"batch=? AND command=? AND args=? AND status=?" withParams:params];
    if (count == 0) {
        [_db upsertValues:values intoTable:@"queue"];
    }
}

- (void)appendCommand:(NSString *)command, ... {
    if (command) {
        // Construct the command line string from the arguments.
        va_list _args;
        va_start(_args, command);
        NSString *commandline = [[NSString alloc] initWithFormat:command arguments:_args];
        va_end(_args);
        // Append the new command.
        NSDictionary *commandDesc = [self parseCommandItem:commandline];
        if (commandDesc) {
            NSString *name = [commandDesc valueForKey:@"name"];
            NSArray *args = [commandDesc valueForKey:@"args"];
            [self appendCommand:name withArgs:args];
        }
    }
}

- (void)purgeQueue {
    // Replace the execution queue with an empty list, delete all queued commands.
    _execQueue = @[];
    _execIdx = 0;
    _currentBatch = 0;
    if (_deleteExecutedQueueRecords) {
        [_db deleteFromTable:@"queue" where:@"1 = 1"];
    }
    else {
        [_db performUpdate:@"UPDATE queue SET status='X' WHERE status='P'" withParams:@[]];
    }
}

- (void)purgeCurrentBatch {
    _execQueue = @[];
    _execIdx = 0;
    if (_deleteExecutedQueueRecords) {
        [_db deleteFromTable:@"queue" where:[NSString stringWithFormat:@"batch=%ld", _currentBatch]];
    }
    else {
        NSNumber *batch = [NSNumber numberWithInteger:_currentBatch];
        [_db performUpdate:@"UPDATE queue SET status='X' WHERE status='P' AND batch=?" withParams:@[ batch ]];
    }
}

#pragma mark - IFService

- (void)startService {
    [_db startService];
    // Execute any commands left on the queue from previous start.
    [self executeQueue];
}

@end
