//
//  IFCommand.h
//  SemoContent
//
//  Created by Julian Goacher on 07/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IFCommandScheduler;

@protocol IFCommand <NSObject>

@property (nonatomic, weak) IFCommandScheduler *scheduler;

/**
 * Execute the command with the specified arguments.
 * May return an array of new commands to be queued for execution.
 */
- (NSArray *)executeWithArgs:(NSArray *)args;

@end
