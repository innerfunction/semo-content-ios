//
//  IFProtocol.h
//  SemoContent
//
//  Created by Julian Goacher on 09/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFCommand.h"

typedef QPromise *(^IFCommandProtocolBlock) (NSArray *args);

/**
 * A command protocol.
 * A command implementation that supports multiple different named commands, useful for
 * defining protocols composed of a number of related commands.
 */
@interface IFCommandProtocol : NSObject <IFCommand> {
    NSDictionary *_commands;
    NSString *_commandPrefix;
}

/** Return a list of command names supported by this protocol. */
- (NSArray *)supportedCommands;
/** Register a protocol command. */
- (void)addCommand:(NSString *)name withBlock:(IFCommandProtocolBlock)block;
/** Qualify a protocol command name with the current command prefix. */
- (NSString *)qualifiedCommandName:(NSString *)name;
/**
 * Parse a command argument list.
 * Transforms an array of command arguments into a dictionary of name/value pairs.
 * Arguments can be defined by position, or by using named switches (e.g. -name value).
 * The names of positional arguments are specified using the argOrder list.
 */
- (NSDictionary *)parseArgArray:(NSArray *)args argOrder:(NSArray *)argOrder defaults:(NSDictionary *)defaults;

@end
