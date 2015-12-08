//
//  IFUnzipCommand.m
//  SemoContent
//
//  Created by Julian Goacher on 08/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFUnzipCommand.h"
#import "IFFileIO.h"

@implementation IFUnzipCommand

- (QPromise *)executeWithArgs:(NSArray *)args {
    if ([args count] < 2) {
        return [Q reject:@"Wrong number of arguments"];
    }
    NSString *zipPath = [args objectAtIndex:0];
    NSString *toPath = [args objectAtIndex:1];
    if ([IFFileIO unzipFileAtPath:zipPath toPath:toPath]) {
        return [Q resolve:@[]];
    }
    return [Q reject:@"Failed to unzip file"];
}

@end
