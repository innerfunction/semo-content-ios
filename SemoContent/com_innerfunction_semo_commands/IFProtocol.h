//
//  IFProtocol.h
//  SemoContent
//
//  Created by Julian Goacher on 09/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFCommand.h"

typedef QPromise *(^IFProtocolCommandBlock) (NSArray *args);

/**
 * A command protocol.
 * A command implementation that supports multiple different named commands, useful for
 * defining protocols composed of a number of related commands.
 */
@interface IFProtocol : NSObject <IFCommand> {
    NSDictionary *_commands;
    NSString *_commandPrefix;
}

/** Return a list of command names supported by this protocol. */
- (NSArray *)supportedCommands;
/** Register a protocol command. */
- (void)addCommand:(NSString *)name withBlock:(IFProtocolCommandBlock)block;
/** Qualify a protocol command name with the current command prefix. */
- (NSString *)qualifiedCommandName:(NSString *)name;
/**
 * Parse a command argument list.
 * Transforms a list of switch name/values (e.g. -name value) pairs into a dictionary
 * of { name: value } pairs. Name only switches are given the value @1. A dictionary
 * of default switch values can optionally be provided.
 */
- (NSDictionary *)parseArgArray:(NSArray *)args defaults:(NSDictionary *)defaults;

@end
