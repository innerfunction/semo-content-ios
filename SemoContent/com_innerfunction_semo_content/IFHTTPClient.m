//
//  IFHTTPClient.m
//  SemoContent
//
//  Created by Julian Goacher on 24/02/2016.
//  Copyright © 2016 InnerFunction. All rights reserved.
//

#import "IFHTTPClient.h"
#import "SSKeychain.h"

typedef QPromise *(^IFHTTPClientAction)();

@interface IFHTTPClient()

- (BOOL)isAuthenticationErrorResponse:(IFHTTPClientResponse *)response;
- (QPromise *)reauthenticate;
- (QPromise *)submitAction:(IFHTTPClientAction)action;

@end

@implementation IFHTTPClientResponse

- (id)initWithHTTPResponse:(NSURLResponse *)response data:(NSData *)data {
    self = [super init];
    if (self) {
        self.httpResponse = (NSHTTPURLResponse *)response;
        self.data = data;
    }
    return self;
}

- (id)initWithHTTPResponse:(NSURLResponse *)response downloadLocation:(NSURL *)location {
    self = [super init];
    if (self) {
        self.httpResponse = (NSHTTPURLResponse *)response;
        self.downloadLocation = location;
    }
    return self;
}

- (id)parseData {
    id data = nil;
    NSString *contentType = _httpResponse.MIMEType;
    if ([@"application/json" isEqualToString:contentType]) {
        data = [NSJSONSerialization JSONObjectWithData:_data
                                               options:0
                                                 error:nil];
        // TODO: Parse error handling.
    }
    else if ([@"application/x-www-form-urlencoded" isEqualToString:contentType]) {
        // Adapted from http://stackoverflow.com/questions/8756683/best-way-to-parse-url-string-to-get-values-for-keys
        NSMutableDictionary *mdata = [[NSMutableDictionary alloc] init];
        // TODO: Proper handling of response text encoding.
        NSString *paramString = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
        NSArray *params = [paramString componentsSeparatedByString:@"&"];
        for (NSString *param in params) {
            NSArray *pair = [param componentsSeparatedByString:@"="];
            NSString *name = [(NSString *)[pair objectAtIndex:0] stringByRemovingPercentEncoding];
            NSString *value = [(NSString *)[pair objectAtIndex:1] stringByRemovingPercentEncoding];
            [mdata setObject:value forKey:name];
        }
        data = mdata;
    }
    else if ([@"text/html" isEqualToString:contentType]) {
        data = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
    }
    return data;
}

@end

/*
@implementation IFHTTPClientAuthenticationHandler

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    // Taken from https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/URLLoadingSystem/Articles/AuthenticationChallenges.html#//apple_ref/doc/uid/TP40009507-SW1
    if (challenge.previousFailureCount == 0) {
        NSString *account = [[NSUserDefaults standardUserDefaults] stringForKey:@"semo/username"];
        NSString *password = [SSKeychain passwordForService:@"<service>" account:account];
        NSURLCredential *credential = [NSURLCredential credentialWithUser:account password:password persistence:NSURLCredentialPersistenceNone];
        [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
    }
    else {
        [challenge.sender cancelAuthenticationChallenge:challenge];
        // Redisplay login screen, show toast
    }
}

@end
*/

@implementation IFHTTPClient

- (QPromise *)get:(NSString *)url {
    return [self get:url data:nil];
}

- (QPromise *)get:(NSString *)url data:(NSDictionary *)data {
    return [self submitAction:^QPromise *{
        QPromise *promise = [QPromise new];
        // Build URL.
        NSURLComponents *urlParts = [NSURLComponents componentsWithString:url];
        if (data) {
            NSMutableArray *queryItems = [[NSMutableArray alloc] init];
            for (NSString *name in data) {
                NSURLQueryItem *queryItem = [NSURLQueryItem queryItemWithName:name value:[data objectForKey:name]];
                [queryItems addObject:queryItem];
            }
            urlParts.queryItems = queryItems;
        }
        // Send request.
        NSURLRequest *request = [NSURLRequest requestWithURL:urlParts.URL];
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request
            completionHandler:^(NSData * _Nullable responseData, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                if (error) {
                    [promise reject:error];
                }
                else {
                    [promise resolve:[[IFHTTPClientResponse alloc] initWithHTTPResponse:response data:responseData]];
                }
            }];
        [task resume];
        return promise;
    }];
}

- (QPromise *)getFile:(NSString *)url {
    return [self submitAction:^QPromise *{
        QPromise *promise = [QPromise new];
        NSURL *fileURL = [NSURL URLWithString:url];
        // See note here about NSURLConnection cacheing: http://blackpixel.com/blog/2012/05/caching-and-nsurlconnection.html
        NSURLRequest *request = [NSURLRequest requestWithURL:fileURL
                                                 cachePolicy:NSURLRequestReloadRevalidatingCacheData // NOTE
                                             timeoutInterval:60];
        NSURLSession *session = [NSURLSession sharedSession];
        NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request
                                                        completionHandler:
        ^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error) {
                [promise reject:error];
            }
            else {
                [promise resolve:[[IFHTTPClientResponse alloc] initWithHTTPResponse:response downloadLocation:location]];
            }
        }];
        [task resume];
        return promise;
    }];
}

- (QPromise *)post:(NSString *)url data:(NSDictionary *)data {
    return [self submitAction:^QPromise *{
        QPromise *promise = [QPromise new];
        // Build URL.
        NSURL *nsURL = [NSURL URLWithString:url];
        // Send request.
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:nsURL];
        request.HTTPMethod = @"POST";
        [request addValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        if (data) {
            NSMutableArray *queryItems = [[NSMutableArray alloc] init];
            for (NSString *name in data) {
                NSString *pname = [name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
                NSString *pvalue = [[[data objectForKey:name] description] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
                NSString *param = [NSString stringWithFormat:@"%@=%@", pname, pvalue];
                [queryItems addObject:param];
            }
            NSString *body = [queryItems componentsJoinedByString:@"&"];
            request.HTTPBody = [body dataUsingEncoding:NSUTF8StringEncoding];
        }
        NSURLSession *session = [NSURLSession sharedSession];
        /*
        IFHTTPClientAuthenticationHandler *authHandler = [[IFHTTPClientAuthenticationHandler alloc] init];
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration
                                                              delegate:authHandler
                                                         delegateQueue:nil];
        */
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request
            completionHandler:^(NSData * _Nullable responseData, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                if (error) {
                    [promise reject:error];
                }
                else {
                    [promise resolve:[[IFHTTPClientResponse alloc] initWithHTTPResponse:response data:responseData]];
                }
            }];
        [task resume];
        return promise;
    }];
}

- (QPromise *)submit:(NSString *)method url:(NSString *)url data:(NSDictionary *)data {
    if ([@"POST" isEqualToString:method]) {
        return [self post:url data:data];
    }
    return [self get:url data:data];
}

#pragma mark - Private methods

- (BOOL)isAuthenticationErrorResponse:(IFHTTPClientResponse *)response {
    if (_authenticationDelegate) {
        return [_authenticationDelegate httpClient:self isAuthenticationErrorResponse:response];
    }
    return NO;
}

- (QPromise *)reauthenticate {
    if (_authenticationDelegate) {
        return [_authenticationDelegate reauthenticateUsingHttpClient:self];
    }
    return [Q reject:nil];
}

- (QPromise *)submitAction:(IFHTTPClientAction)action {
    QPromise *promise = [QPromise new];
    action()
    .then((id)^(IFHTTPClientResponse *response) {
        if ([self isAuthenticationErrorResponse:response]) {
            [self reauthenticate]
            .then((id)^(id response) {
                [promise resolve:action()];
                return nil;
            })
            .fail(^(id error) {
                [promise reject:error];
            });
        }
        else {
            [promise resolve:response];
        }
        return nil;
    })
    .fail(^(id error) {
        [promise reject:error];
    });
    return promise;
}

@end
