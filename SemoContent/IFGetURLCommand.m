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

- (QPromise *)executeWithArgs:(NSArray *)args {
    _promise = [[QPromise alloc] init];
    _url = [args objectAtIndex:0];
    _filename = [args objectAtIndex:1];
    NSString *retry = [args objectAtIndex:2];
    _remainingRetries = _maxRetries - [retry integerValue];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:_filename]) {
        [fileManager removeItemAtPath:_filename error:nil];
    }
    [fileManager createFileAtPath:_filename contents:nil attributes:nil];
    _fileHandle = [NSFileHandle fileHandleForWritingAtPath:_filename];
    
    NSURL *url = [NSURL URLWithString:_url];
    // See note here about NSURLConnection cacheing: http://blackpixel.com/blog/2012/05/caching-and-nsurlconnection.html
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:url
                                                       cachePolicy:NSURLRequestReloadIgnoringLocalCacheData // TODO
                                                   timeoutInterval:60];
    [req setHTTPMethod:@"GET"];
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    [connection start];

    return _promise;
}

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
            // Command name will be provided by the scheduler.
            @"args": args
        };
        [_promise resolve:@[ retryCommand ]];
    }
    else {
        [_promise reject:@"All retries used"];
    }
}

@end
