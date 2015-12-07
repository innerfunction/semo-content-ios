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
                    @"command": @{ @"type": @"TEXT" },
                    @"args":    @{ @"type": @"TEXT" }
                }
            }
        };
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
    while (YES) {
        NSArray *commands = [_db performQuery:@"SELECT * FROM queue ORDER BY id ASC" withParams:@[]];
        if ([commands count] == 0) {
            // Exit if no command left to execute.
            break;
        }
        for (NSDictionary *command in commands) {
            // Execute the command then delete the command from the db before looping around to the next command.
            NSString *rowid = [command valueForKey:@"id"];
            NSString *name = [command valueForKey:@"command"];
            NSString *args = [command valueForKey:@"args"];
            [self executeCommand:name withArgs:args];
            [_db deleteIDs:@[ rowid ] fromTable:@"queue"];
        }
        // Loop around and query for any additional command added to the queue by commands exec'd in last loop.
    }
}

- (void)executeCommand:(NSString *)name withArgs:(NSString *)args {
    [Logger debug:@"Executing %@ %@", name, args];
    id<IFCommand> command = [_commands objectForKey:name];
    if (!command) {
        [Logger error:@"Command not found: %@", name];
        return;
    }
    [command executeWithArgs:args];
}

- (void)appendCommand:(NSString *)name withArgs:(NSString *)args {
    [Logger debug:@"Appending %@ %@", name, args];
    NSDictionary *command = @{
        @"name":      name,
        @"args":      args
    };
    [_db insertValues:command intoTable:@"queue"];
}

#pragma mark - IFService

- (void)startService {
    [_db startService];
    // Execute any command remaining on the queue.
    [self executeQueue];
}

@end
