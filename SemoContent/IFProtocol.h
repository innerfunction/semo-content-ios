//
//  IFProtocol.h
//  SemoContent
//
//  Created by Julian Goacher on 09/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * A command protocol.
 * A command implementation that supports multiple different named commands, useful for
 * defining protocols composed of a number of related commands.
 */
@protocol IFProtocol <IFCommand>

/** Return a list of command names supported by this protocol. */
- (NSArray *)supportedCommands;

@end
