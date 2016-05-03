//
//  IFCommandScheduler.m
//  SemoContent
//
//  Created by Julian Goacher on 07/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFCommandScheduler.h"
#import "IFCommand.h"
#import "IFCommandProtocol.h"
#import "IFSemoContent.h"
#import "IFRmFileCommand.h"
#import "IFMvFileCommand.h"
#import "IFUnzipCommand.h"
#import "NSDictionary+IF.h"
#import "NSString+IF.h"

static IFLogger *Logger;
static dispatch_queue_t execQueue;

@interface NSArray (JSON)

- (NSString *)toJSON;

@end

@implementation NSArray (JSON)

- (NSString *)toJSON {
    NSData *data = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:nil];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end

@interface IFCommandItem : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSArray *args;
@property (nonatomic, strong) NSNumber *priority;

@end

@implementation IFCommandItem

@end

@interface IFCommandScheduler ()

/** Execute the next command on the exec queue. */
- (void)executeNextCommand;
/** Continue queue processing after execution a command. */
- (void)continueQueueProcessingAfterCommand:(NSString *)rowID;
/**
 * Parse a command item into a command descriptor.
 * The command item can be either:
 * 1. A dictionary instance with 'name' and 'args' entries;
 * 2. Or a command line string, which is parsed into 'name' and 'args' items.
 */
- (IFCommandItem *)parseCommandItem:(id)item;

@end

// Macro to test whether a method is called on the scheduler's execution queue.
#define RunningOnExecQueue  (dispatch_get_specific(execQueueKey) != NULL)

@implementation IFCommandScheduler

static void *execQueueKey = "IFCommandScheduler.execQueue";

+ (void)initialize {
    Logger = [[IFLogger alloc] initWithTag:@"IFCommandScheduler"];
    execQueue = dispatch_queue_create("com.innerfunction.semo.commands.CommandScheduler", 0);
    dispatch_queue_set_specific(execQueue, execQueueKey, execQueueKey, NULL);
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
        if ([command isKindOfClass:[IFCommandProtocol class]]) {
            IFCommandProtocol *protocol = (IFCommandProtocol *)command;
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
    dispatch_async(execQueue, ^{
        _execQueue = [_db performQuery:@"SELECT * FROM queue WHERE status='P' ORDER BY batch, id ASC" withParams:@[]];
        _execIdx = 0;
        [self executeNextCommand];
    });
}

- (void)executeNextCommand {
    dispatch_async(execQueue, ^{
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
        NSString *rowid = commandItem[@"id"];
        NSString *name = commandItem[@"command"];
        NSString *argsJSON = commandItem[@"args"];
        NSArray *args = [argsJSON parseJSON:nil];
        _currentBatch = [(NSNumber *)commandItem [@"batch"] integerValue];
        // Find and execute the command.
        [Logger debug:@"Executing %@ %@", name, [args componentsJoinedByString:@" "]];
        id<IFCommand> command = _commands[name];
        if (!command) {
            [Logger error:@"Command not found: %@", name];
            [self purgeQueue];
            return;
        }
        [command execute:name withArgs:args]
        .then((id)^(NSArray *commands) {
            dispatch_async(execQueue, ^{
                // Queue any new commands, delete current command from db.
                [_db beginTransaction];
                for (id item in commands) {
                    IFCommandItem *command = [self parseCommandItem:item];
                    if (!command) {
                        // Indicates an unparseable command line string; just continue to the next command.
                        continue;
                    }
                    // Check for system commands.
                    if ([@"control.purge-queue" isEqualToString:command.name]) {
                        [self purgeQueue];
                        continue;
                    }
                    if ([@"control.purge-current-batch" isEqualToString:command.name]) {
                        [self purgeCurrentBatch];
                        continue;
                    }
                    NSInteger batch = _currentBatch;
                    if (command.priority) {
                        batch += [command.priority integerValue];
                        // Negative priorities can place new commands at the head of the queue; reset the exec queue
                        // to force a db read, so that these commands are read into the head of the exec queue.
                        if (batch < _currentBatch) {
                            _execQueue = @[];
                        }
                    }
                    [Logger debug:@"Appending %@ %@", command.name, command.args];
                    NSDictionary *values = @{
                        @"batch":   [NSNumber numberWithInteger:batch],
                        @"command": command.name,
                        @"args":    [command.args toJSON],
                        @"status":  @"P"
                    };
                    [_db insertValues:values intoTable:@"queue"];
                }
                [self continueQueueProcessingAfterCommand:rowid];
            });
            return nil;
        })
        .fail(^(id error) {
            [Logger error:@"Error executing command %@ %@: %@", name, args, error];
            // TODO: Review whether queue should be purged or not. Removed for now - commands
            // should detect errors caused by previous command failures and deal with accordingly.
            // [self purgeQueue];
            [self continueQueueProcessingAfterCommand:rowid];
        });
    });
}

- (void)continueQueueProcessingAfterCommand:(NSString *)rowID {
    // Delete the command record from the queue.
    if (_deleteExecutedQueueRecords) {
        [_db deleteIDs:@[ rowID ] fromTable:@"queue"];
    }
    else {
        NSDictionary *values = @{
            @"id":      rowID,
            @"status":  @"X"
        };
        [_db updateValues:values inTable:@"queue"];
    }
    [_db commitTransaction];
    // Continue to next queued command.
    [self executeNextCommand];
}

- (IFCommandItem *)parseCommandItem:(id)item {
    if ([item isKindOfClass:[NSDictionary class]]) {
        NSDictionary *itemDict = (NSDictionary *)item;
        NSString *name = itemDict[@"name"];
        id args = itemDict[@"args"];
        if (name) {
            if ([args isKindOfClass:[NSString class]]) {
                args = [(NSString *)args componentsSeparatedByString:@" "];
            }
            if ([args isKindOfClass:[NSArray class]]) {
                IFCommandItem *command = [IFCommandItem new];
                command.name = name;
                command.args = args;
                command.priority = itemDict[@"priority"];
                return command;
            }
        }
    }
    else if ([item isKindOfClass:[NSString class]]) {
        NSArray *parts = [(NSString *)item componentsSeparatedByString:@" "];
        if ([parts count] > 0) {
            IFCommandItem *command = [IFCommandItem new];
            command.name = parts[0];
            if ([parts count] > 1) {
                command.args = [parts subarrayWithRange:NSMakeRange(1, [parts count] - 1)];
            }
            else {
                command.args = @[];
            }
            return command;
        }
    }
    [Logger warn:@"Invalid command item: %@", item];
    return nil;
}

- (void)appendCommand:(NSString *)name withArgs:(NSArray *)args {
    [Logger debug:@"Appending %@ %@", name, args];
    NSNumber *batch = [NSNumber numberWithInteger:_currentBatch];
    NSString *argsJSON = [args toJSON];
    NSDictionary *values = @{
        @"batch":   batch,
        @"command": name,
        @"args":    argsJSON,
        @"status":  @"P"
    };
    dispatch_async(execQueue, ^{
        // Only one pending command with the same name and args should exist for the same batch
        // at any time, so only insert record if no matching record found.
        NSArray *params = @[ batch, name, argsJSON, @"P" ];
        NSInteger count = [_db countInTable:@"queue" where:@"batch=? AND command=? AND args=? AND status=?" withParams:params];
        if (count == 0) {
            [_db upsertValues:values intoTable:@"queue"];
        }
    });
}

- (void)appendCommand:(NSString *)command, ... {
    if (command) {
        // Construct the command line string from the arguments.
        va_list _args;
        va_start(_args, command);
        NSString *commandLine = [[NSString alloc] initWithFormat:command arguments:_args];
        va_end(_args);
        // Append the new command.
        IFCommandItem *commandItem = [self parseCommandItem:commandLine];
        if (commandItem) {
            [self appendCommand:commandItem.name withArgs:commandItem.args];
        }
    }
}

- (void)purgeQueue {
    // Replace the execution queue with an empty list, delete all queued commands.
    _execQueue = @[];
    _execIdx = 0;
    _currentBatch = 0;
    void (^purge)() = ^() {
        if (_deleteExecutedQueueRecords) {
            [_db deleteFromTable:@"queue" where:@"1 = 1"];
        }
        else {
            [_db performUpdate:@"UPDATE queue SET status='X' WHERE status='P'" withParams:@[]];
        }
    };
    // If already running on the exec queue the run the purge synchronously; else add to end of queue.
    if (RunningOnExecQueue) {
        purge();
    }
    else {
        dispatch_async(execQueue, purge);
    }
}

- (void)purgeCurrentBatch {
    _execQueue = @[];
    _execIdx = 0;
    void (^purge)() = ^() {
        if (_deleteExecutedQueueRecords) {
            [_db deleteFromTable:@"queue" where:[NSString stringWithFormat:@"batch=%ld", _currentBatch]];
        }
        else {
            NSNumber *batch = [NSNumber numberWithInteger:_currentBatch];
            [_db performUpdate:@"UPDATE queue SET status='X' WHERE status='P' AND batch=?" withParams:@[ batch ]];
        }
    };
    // If already running on the exec queue the run the purge synchronously; else add to end of queue.
    if (RunningOnExecQueue) {
        purge();
    }
    else {
        dispatch_async(execQueue, purge);
    }
}

#pragma mark - IFService

- (void)startService {
    [_db startService];
    // Execute any commands left on the queue from previous start.
    [self executeQueue];
}

@end
