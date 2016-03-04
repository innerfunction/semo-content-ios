//
//  IFGetURLCommand.m
//  SemoContent
//
//  Created by Julian Goacher on 08/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFGetURLCommand.h"

#define DefaultMaxRetries (3)

@implementation IFGetURLCommand

- (id)initWithHTTPClient:(IFHTTPClient *)httpClient {
    self = [super init];
    if (self) {
        _httpClient = httpClient;
        _maxRetries = DefaultMaxRetries;
    }
    return self;
}

- (QPromise *)execute:(NSString *)name withArgs:(NSArray *)args {
    _commandName = name;
    _promise = [[QPromise alloc] init];
    if ([args count] > 1) {
        _url = [args objectAtIndex:0];
        _filename = [args objectAtIndex:1];
        
        NSInteger retry = 0;
        if ([args count] > 2) {
            retry = [(NSString *)[args objectAtIndex:2] integerValue];
        }
        _remainingRetries = _maxRetries - retry;
        
        [_httpClient getFile:_url]
        .then((id)^(IFHTTPClientResponse *response) {
            // Copy downloaded file to target location.
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSURL *fileURL = [NSURL fileURLWithPath:_filename];
            
            // Check whether the target location exists, delete any file already at the target location.
            NSString *dirPath = [fileURL.path stringByDeletingLastPathComponent];
            if (![fileManager fileExistsAtPath:dirPath]) {
                [fileManager createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
            else if ([fileManager fileExistsAtPath:fileURL.path]) {
                [fileManager removeItemAtURL:fileURL error:nil];
            }
            
            // Copy downloaded file to target location.
            [fileManager moveItemAtURL:response.downloadLocation toURL:fileURL error:nil];
            [_promise resolve:@[]];
        })
        .fail(^(id error) {
            // Check for retries.
            if (_remainingRetries > 0) {
                NSString *args = [NSString stringWithFormat:@"%@ %ld", _url, _remainingRetries - 1 ];
                NSDictionary *retryCommand = @{
                    @"name": _commandName,
                    @"args": args
                };
                [_promise resolve:@[ retryCommand ]];
            }
            else {
                [_promise reject:@"All retries used"];
            }
        });
    }
    else {
        [_promise reject:@"Incorrect number of arguments"];
    }
    return _promise;
}

@end
