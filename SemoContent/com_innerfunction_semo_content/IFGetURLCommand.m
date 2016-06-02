//
//  IFGetURLCommand.m
//  SemoContent
//
//  Created by Julian Goacher on 08/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFGetURLCommand.h"
#import "IFCommandScheduler.h"

#define DefaultMaxRetries   (3)
#define RequestWindowSize   (5)

@implementation IFGetURLCommand

- (id)initWithHTTPClient:(IFHTTPClient *)httpClient {
    self = [super init];
    if (self) {
        _httpClient = httpClient;
        _maxRetries = DefaultMaxRetries;
        _requestWindow = [NSMutableArray new];
    }
    return self;
}

- (QPromise *)execute:(NSString *)name withArgs:(NSArray *)args {
    _commandName = name;
    _promise = [[QPromise alloc] init];
    
    if ([args count] > 1) {
        
        _url = args[0];
        _filename = args[1];
        
        NSInteger previousAttempts = 0;
        if ([args count] > 2) {
            previousAttempts = [(NSString *)args[2] integerValue];
        }
        
        dispatch_block_t request = ^() {

            if ([_requestWindow count] > RequestWindowSize) {
                [_requestWindow removeObjectAtIndex:0];
            }
            [_requestWindow addObject:[NSDate new]];

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
                return nil;
            })
            .fail(^(id error) {
                // Check for retries.
                NSInteger attempts = previousAttempts + 1;
                if (attempts < _maxRetries) {
                    NSString *args = [NSString stringWithFormat:@"%@ %ld", _url, (long)attempts ];
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
        };
        
        // Request throttling - ensure number of requests per minute doesn't exceed some defined maximum.
        // TODO: Consider supporing per-domain (or even per-URL?) request limits. Also, perhaps allow
        // request limit to be set per-command? This would allow easy setup of different channels for
        // different usages.
        float timeToNextRequest = -1;
        if (_maxRequestsPerMinute > 0  && [_requestWindow count] > 0) {
            // The following code uses a request window containing n previous requests. The code calculates
            // the ideal number of seconds per request (i.e. to hit the maximum requests per minute). The
            // ideal time of the next request is then calculated by multiplying the seconds-per-request by
            // the size of the request window, and adding this to the time of the first request in the window.
            // The result may be positive (indicating a future time); or negative (indicating a past time).
            NSDate *windowStart = (NSDate *)_requestWindow[0];
            float secsPerRequest = (1.0f / _maxRequestsPerMinute) * 60.0f;
            NSDate *nextRequestTime = [windowStart dateByAddingTimeInterval:(secsPerRequest * ([_requestWindow count] + 1))];
            timeToNextRequest = [nextRequestTime timeIntervalSinceNow];
        }
        // If the ideal next request time is in the past then immediately execute the request.
        if (timeToNextRequest < 0) {
            request();
        }
        else {
            //NSLog(@"Delaying HTTP request by %f secs", timeToNextRequest);
            // Ideal next request time is in the future, so schedule the request to execute on the queue
            // after a suitable delay.
            int64_t tdelta = (int64_t)timeToNextRequest * NSEC_PER_SEC;
            dispatch_queue_t queue = [IFCommandScheduler getCommandExecutionQueue];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, tdelta), queue, request);
        }
    }
    else {
        [_promise reject:@"Incorrect number of arguments"];
    }
    return _promise;
}

@end
