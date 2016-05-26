//
//  IFDownloadZipCommand.m
//  SemoContent
//
//  Created by Julian Goacher on 24/05/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFDownloadZipCommand.h"
#import "IFFileIO.h"

@implementation IFDownloadZipCommand

- (id)initWithHTTPClient:(IFHTTPClient *)httpClient commandScheduler:(IFCommandScheduler *)commandScheduler {
    self = [super init];
    if (self) {
        _httpClient = httpClient;
        _commandScheduler = commandScheduler;
        _promises = [NSMutableSet new];
    }
    return self;
}

- (QPromise *)execute:(NSString *)name withArgs:(NSArray *)args {
    QPromise *promise = [[QPromise alloc] init];
    if ([args count] > 1) {
        // Add promise object to set of promises to ensure reference isn't loss after ARC tidyup.
        [_promises addObject:promise];
        // Read arguments.
        NSString *url = args[0];
        NSString *unzipPath = args[1];
        NSString *overwrite = @"no";
        if ([args count] > 2) {
            overwrite = args[2];
        }
        // Start the downloading
        [_httpClient getFile:url]
        .then((id)^(IFHTTPClientResponse *response) {
            // Schedule commands to unzip the downloaded file before removing it.
            NSString *downloadPath = [response.downloadLocation path];
            if ([IFFileIO unzipFileAtPath:downloadPath toPath:unzipPath overwrite:NO]) {
                [promise resolve:@[]];
            }
            else {
                [promise reject:@"Failed to unzip download"];
            }
            [_promises removeObject:promise];
            return nil;
        })
        .fail(^(id error) {
            NSString *msg = [NSString stringWithFormat:@"Download from %@ failed: %@", url, error];
            [promise reject:msg];
            [_promises removeObject:promise];
        });
    }
    else {
        [promise reject:@"Incorrect number of arguments"];
    }

    return promise;
}

@end
