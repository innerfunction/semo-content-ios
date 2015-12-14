//
//  IFProtocol.m
//  SemoContent
//
//  Created by Julian Goacher on 09/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFProtocol.h"
#import "NSDictionary+IF.h"
#import "NSString+IF.h"

@implementation IFProtocol

- (id)init {
    self = [super init];
    if (self) {
        _commands = [NSDictionary dictionary];
    }
    return self;
}

- (NSArray *)supportedCommands {
    return [_commands allKeys];
}

- (void)addCommand:(NSString *)name withBlock:(IFProtocolCommandBlock)block {
    _commands = [_commands dictionaryWithAddedObject:block forKey:name];
}

- (NSString *)qualifiedCommandName:(NSString *)name {
    return [NSString stringWithFormat:@"%@.%@", _commandPrefix, name ];
}

#pragma mark - IFCommand protocol

- (QPromise *)execute:(NSString *)name withArgs:(NSArray *)args {
    // Split the protocol prefix from the name to get the actual command name.
    NSArray *nameParts = [name split:@"."];
    _commandPrefix = [nameParts objectAtIndex:0];
    NSString *commandName = [nameParts objectAtIndex:1];
    // Find a handler block for the named command.
    IFProtocolCommandBlock block = [_commands objectForKey:commandName];
    if (block) {
        return block( args );
    }
    // No handler found.
    return [Q reject:[NSString stringWithFormat:@"Unrecognized command name: %@", commandName]];
}

@end
