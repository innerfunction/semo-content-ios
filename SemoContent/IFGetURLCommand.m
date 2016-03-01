//
//  IFGetURLCommand.m
//  SemoContent
//
//  Created by Julian Goacher on 08/12/2015.
//  Copyright © 2015 InnerFunction. All rights reserved.
//

#import "IFGetURLCommand.h"

#define DefaultMaxRetries 3

@implementation IFGetURLCommand

- (id)init {
    self = [super init];
    if (self) {
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
        /*
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager fileExistsAtPath:_filename]) {
            [fileManager removeItemAtPath:_filename error:nil];
        }
        [fileManager createFileAtPath:_filename contents:nil attributes:nil];
        _fileHandle = [NSFileHandle fileHandleForWritingAtPath:_filename];
        */
        NSURL *url = [NSURL URLWithString:_url];
        // See note here about NSURLConnection cacheing: http://blackpixel.com/blog/2012/05/caching-and-nsurlconnection.html
        /*
        NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestReloadRevalidatingCacheData // NOTE
                                                       timeoutInterval:60];
        [req setHTTPMethod:@"GET"];
        
        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
        [connection start];
        */
        NSURLRequest *request = [NSURLRequest requestWithURL:url
                                                 cachePolicy:NSURLRequestReloadRevalidatingCacheData // NOTE
                                             timeoutInterval:60];
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request
                                                        completionHandler:
        ^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error) {
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
            }
            else {
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
                [fileManager moveItemAtURL:location toURL:fileURL error:nil];
                [_promise resolve:@[]];
            }
        }];
        // Start the request.
        [task resume];
    }
    else {
        [_promise reject:@"Incorrect number of arguments"];
    }
    return _promise;
}
/*
#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    if ([data length] > 0) {
        [_fileHandle seekToEndOfFile];
        [_fileHandle writeData:data];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [_promise resolve:@[]];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
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
}
*/
@end
