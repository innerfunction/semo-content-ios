//
//  IFRmFileCommand.m
//  SemoContent
//
//  Created by Julian Goacher on 08/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFRmFileCommand.h"

@implementation IFRmFileCommand

- (QPromise *)executeWithArgs:(NSArray *)args {
    if ([args count] < 1) {
        return [Q reject:@"Missing <filename> argument"];
    }
    NSString *filename = [args objectAtIndex:0];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // NOTE this should remove directories as well as individual files.
    [fileManager removeItemAtPath:filename error:nil];
    return [Q resolve:@[]];
}

@end
