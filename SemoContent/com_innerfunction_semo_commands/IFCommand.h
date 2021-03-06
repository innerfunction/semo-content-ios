//
//  IFCommand.h
//  SemoContent
//
//  Created by Julian Goacher on 07/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Q.h"

@class IFCommandScheduler;

@protocol IFCommand <NSObject>

/**
 * Execute the command with the specified name and arguments.
 * Returns a deferred promise which may resolve to an array of new commands to
 * be queued for execution after the current, and any other commands, complete.
 */
- (QPromise *)execute:(NSString *)name withArgs:(NSArray *)args;

@end
