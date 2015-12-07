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

- (void)executeWithArgs:(NSString *)args;

@end
