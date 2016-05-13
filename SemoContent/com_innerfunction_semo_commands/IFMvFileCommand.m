//
//  IFMvFileCommand.m
//  SemoContent
//
//  Created by Julian Goacher on 08/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFMvFileCommand.h"

@interface IFMvFileCommand()

- (NSError *)moveFileAtPath:(NSString *)fromPath toPath:(NSString *)toPath;

@end

@implementation IFMvFileCommand

- (id)init {
    self = [super init];
    if (self) {
        _fileManager = [NSFileManager defaultManager];
    }
    return self;
}

- (QPromise *)execute:(NSString *)name withArgs:(NSArray *)args {
    if ([args count] < 2) {
        return [Q reject:@"Wrong number of arguments"];
    }
    NSString *fromPath = [args objectAtIndex:0];
    NSString *toPath = [args objectAtIndex:1];
    BOOL fromIsDirectory;
    NSError *error = nil;
    // Check from location exists.
    if ([_fileManager fileExistsAtPath:fromPath isDirectory:&fromIsDirectory]) {
        if (fromIsDirectory) {
            // Check target location exists.
            if (![_fileManager fileExistsAtPath:toPath]) {
                [_fileManager createDirectoryAtPath:toPath withIntermediateDirectories:YES attributes:nil error:&error];
            }
            if (!error) {
                // List directory contents and move each one to the target location.
                NSArray *files = [_fileManager contentsOfDirectoryAtPath:fromPath error:&error];
                for (NSInteger idx = 0; idx < [files count] && !error; idx++) {
                    NSString *filename = files[idx];
                    NSString *fromFile = [fromPath stringByAppendingPathComponent:filename];
                    NSString *toFile = [toPath stringByAppendingPathComponent:filename];
                    error = [self moveFileAtPath:fromFile toPath:toFile];
                }
            }
        }
        else {
            error = [self moveFileAtPath:fromPath toPath:toPath];
        }
    }
    if (error) {
        [Q reject:error];
    }
    return [Q resolve:@[]];
}

#pragma mark - Private methods

- (NSError *)moveFileAtPath:(NSString *)fromPath toPath:(NSString *)toPath {
    NSError *error = nil;
    // If there is already a file at the target path then remove it first.
    if ([_fileManager fileExistsAtPath:toPath]) {
        [_fileManager removeItemAtPath:toPath error:&error];
    }
    if (!error) {
        [_fileManager moveItemAtPath:fromPath toPath:toPath error:&error];
    }
    return error;
}

@end
