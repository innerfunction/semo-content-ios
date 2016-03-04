//
//  IFRmFileCommand.m
//  SemoContent
//
//  Created by Julian Goacher on 08/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFRmFileCommand.h"

@implementation IFRmFileCommand

- (QPromise *)execute:(NSString *)name withArgs:(NSArray *)args {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for (NSString *filename in args) {
        // NOTE this should remove directories as well as individual files.
        [fileManager removeItemAtPath:filename error:nil];
    }
    return [Q resolve:@[]];
}

@end
