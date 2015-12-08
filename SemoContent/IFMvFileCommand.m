//
//  IFMvFileCommand.m
//  SemoContent
//
//  Created by Julian Goacher on 08/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFMvFileCommand.h"

@implementation IFMvFileCommand

- (QPromise *)executeWithArgs:(NSArray *)args {
    if ([args count] < 2) {
        return [Q reject:@"Wrong number of arguments"];
    }
    NSString *fromPath = [args objectAtIndex:0];
    NSString *toPath = [args objectAtIndex:1];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager copyItemAtPath:fromPath toPath:toPath error:nil]) {
        [fileManager removeItemAtPath:fromPath error:nil];
    }
    return [Q resolve:@[]];
}

@end
