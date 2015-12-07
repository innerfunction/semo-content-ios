//
//  IFCommandScheduler.h
//  SemoContent
//
//  Created by Julian Goacher on 07/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IFDB.h"
#import "IFService.h"

@interface IFCommandScheduler : NSObject <IFService> {
    IFDB *_db;
}

/** A map of command instances, keyed by name. */
@property (nonatomic, strong) NSDictionary *commands;

/** Execute all commands currently on the queue. */
- (void)executeQueue;
/** Execute a command. */
- (void)executeCommand:(NSString *)name withArgs:(NSString *)args;
/** Append a new command to the queue. */
- (void)appendCommand:(NSString *)name withArgs:(NSString *)args;

@end
